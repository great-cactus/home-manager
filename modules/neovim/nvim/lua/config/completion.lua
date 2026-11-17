-- Insert, cmdline and terminal completion with blink.cmp.
--
-- The items of every source are ranked together by one fuzzy score (Rust
-- matcher, with frecency and proximity bonuses), so the best match comes
-- first whatever its source:
--   lsp       language servers (skkelua's own client is left to SKK mode)
--   path      file names; while it has items the buffer words are left out
--   snippets  LuaSnip triggers
--   buffer    words of the listed buffers
--   dict      English word list (config/completion_dict.lua)
--   rg        words of the project (config/completion_rg.lua)
local M = {}

-- Off in special buffers (prompts, pickers) and while SKK is on; the
-- cmdline and terminals keep it.
function M.enabled()
  if vim.b.completion_disabled then
    return false
  end
  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
  return mode == 'c' or mode == 't' or vim.bo.buftype == ''
end

-- Directory of relative paths: the buffer's, or the shell's in a terminal.
function M.cwd(ctx)
  local bo = vim.bo[ctx.bufnr]
  if bo.buftype == 'terminal' then
    local pid = vim.b[ctx.bufnr].terminal_job_pid
    return pid and vim.uv.fs_readlink('/proc/' .. pid .. '/cwd') or vim.fn.getcwd()
  end
  return vim.fn.expand(('#%d:p:h'):format(ctx.bufnr))
end

-- The listed file buffers, and the current one (a terminal's own output).
local function listed_buffers()
  local current = vim.api.nvim_get_current_buf()
  return vim.tbl_filter(function(buf)
    if buf == current then
      return true
    end
    return vim.bo[buf].buflisted and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == ''
  end, vim.api.nvim_list_bufs())
end

local function after_indent()
  local before = vim.api.nvim_get_current_line():sub(1, vim.fn.col('.') - 1)
  return before == '' or before:match('%s$') ~= nil
end

-- <Tab> with no menu and no snippet: indent at line start/after a space,
-- otherwise open the menu.
local function show_unless_indent(cmp)
  if vim.fn.mode() == 'i' and not after_indent() then
    return cmp.show()
  end
end

local function change_choice()
  local ls = package.loaded.luasnip
  if ls and ls.choice_active() then
    ls.change_choice(1)
    return true
  end
end

M.keymap = {
  preset = 'none',
  ['<Tab>'] = { 'select_next', 'snippet_forward', show_unless_indent, 'fallback' },
  ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
  ['<C-n>'] = { 'select_next', 'show' },
  ['<C-p>'] = { 'select_prev', 'show' },
  ['<C-y>'] = { 'accept', 'hide', 'fallback' },
  ['<C-e>'] = { 'cancel', change_choice, 'fallback' },
}

-- Keys act on the menu only while it is shown; otherwise the shell gets them.
M.term_keymap = {
  preset = 'none',
  ['<Tab>'] = { 'select_next', 'fallback' },
  ['<S-Tab>'] = { 'select_prev', 'fallback' },
  ['<C-n>'] = { 'select_next', 'fallback' },
  ['<C-p>'] = { 'select_prev', 'fallback' },
  ['<C-y>'] = { 'accept', 'fallback' },
  ['<C-e>'] = { 'cancel', 'fallback' },
}

M.opts = {
  enabled = M.enabled,
  keymap = M.keymap,
  completion = {
    list = { selection = { preselect = false, auto_insert = true } },
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
  },
  snippets = { preset = 'luasnip' },
  fuzzy = {
    implementation = 'prefer_rust_with_warning',
    -- Nix ships the built library
    prebuilt_binaries = { download = false },
  },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer', 'dict', 'rg' },
    providers = {
      lsp = {
        -- buffer words are wanted next to LSP items too
        fallbacks = {},
        transform_items = function(_, items)
          return vim.tbl_filter(function(item)
            return item.client_name ~= 'skkelua'
          end, items)
        end,
      },
      path = { opts = { get_cwd = M.cwd } },
      buffer = { opts = { get_bufnrs = listed_buffers } },
      dict = {
        name = 'Dict',
        module = 'config.completion_dict',
        min_keyword_length = 3,
        max_items = 5,
        score_offset = -5,
      },
      rg = {
        name = 'rg',
        module = 'config.completion_rg',
        min_keyword_length = 3,
        max_items = 10,
        score_offset = -3,
        async = true,
        timeout_ms = 500,
      },
    },
  },
  cmdline = { enabled = true },
  term = {
    enabled = true,
    keymap = M.term_keymap,
    sources = { 'path', 'buffer' },
    completion = { menu = { auto_show = true } },
  },
}

function M.setup()
  -- skkelua's conversion candidates still use the builtin popup
  vim.o.completeopt = 'menuone,noselect,fuzzy,popup'
  vim.o.pumheight = 10
  vim.o.pummaxwidth = 50
  vim.o.dictionary = vim.o.dictionary ~= '' and vim.o.dictionary or vim.fn.stdpath('config') .. '/dict/words.txt'
  vim.opt.shortmess:append('c')
  require('blink.cmp').setup(M.opts)
end

return M

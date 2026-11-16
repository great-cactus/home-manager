-- Native insert-mode completion (replaces ddc.vim).
--
-- 'autocomplete' collects every source listed in 'complete' into one popup:
--   luasnip  snippet triggers (expanded on <C-y> by CompleteDone below)
--   lsp      vim.lsp.omnifunc; async, its items are appended when they arrive
--   . w b    words of the current buffer, windows and listed buffers
--   path     file names (also after a non-keyword such as '/')
--   k        English word list (Nix links it to dict/words.txt)
--   rg       words of the project, searched with ripgrep under a deadline
-- Vim keeps the first item of identical words, so luasnip comes first: a
-- trigger that rg also finds stays expandable.
local M = {}

M.rg_timeout_ms = 150
M.rg_min_length = 3
M.rg_max_items = 10
M.path_max_items = 200

-- Plain functions so 'complete' can reference them as v:lua.NativeCmp.*
_G.NativeCmp = M

local function line_to_cursor()
  return vim.api.nvim_get_current_line():sub(1, vim.fn.col('.') - 1)
end

local function keyword_start()
  return vim.fn.match(line_to_cursor(), [[\k*$]])
end

local function has_fuzzy()
  return vim.tbl_contains(vim.opt.completeopt:get(), 'fuzzy')
end

-- Keep items whose word matches base: fuzzy when 'completeopt' has it,
-- otherwise by case-insensitive prefix.
local function filter(items, base)
  if base == '' then
    return items
  end
  if has_fuzzy() then
    return vim.fn.matchfuzzy(items, base, { key = 'word' })
  end
  local lower = base:lower()
  return vim.tbl_filter(function(item)
    return vim.startswith(item.word:lower(), lower)
  end, items)
end

-- >>> luasnip
function M.luasnip(findstart, base)
  if findstart == 1 then
    return package.loaded.luasnip and keyword_start() or -2
  end
  local ls = package.loaded.luasnip
  if not ls then
    return {}
  end
  -- The completed word starts at the keyword; a trigger with a leading
  -- non-keyword part ("#include") is offered only when that part is already
  -- typed, and only its keyword part is inserted (else "##include").
  local before = line_to_cursor()
  before = before:sub(1, #before - #base)
  local items = {}
  for _, ft in ipairs(require('luasnip.util.util').get_snippet_filetypes()) do
    for _, snip in ipairs(ls.get_snippets(ft)) do
      local trig = snip.trigger
      if not snip.hidden and not snip.regTrig and trig ~= '' then
        local lead = vim.fn.matchstr(trig, [[^\%(\k\@!.\)*]])
        if lead == '' or (lead ~= trig and vim.endswith(before, lead)) then
          local desc = snip.description
          items[#items + 1] = {
            word = trig:sub(#lead + 1),
            abbr = trig,
            menu = '[LS]',
            kind = 'Snippet',
            info = type(desc) == 'table' and table.concat(desc, '\n') or desc or '',
            user_data = { luasnip = snip.id, trigger = trig },
          }
        end
      end
    end
  end
  return filter(items, base)
end

-- Replace the accepted trigger with the expanded snippet.
local function expand_luasnip()
  local item = vim.v.completed_item
  local id = type(item.user_data) == 'table' and item.user_data.luasnip
  if not id or vim.v.event.reason ~= 'accept' then
    return
  end
  local ls = package.loaded.luasnip
  local snip = ls and ls.get_id_snippet(id)
  if not snip then
    return
  end
  -- the whole trigger, including a leading part typed before the word
  local trigger = item.user_data.trigger or item.word
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  ls.snip_expand(snip, {
    clear_region = { from = { row - 1, col - #trigger }, to = { row - 1, col } },
  })
end
-- <<< luasnip

-- >>> path
-- Start of a path-like token before the cursor; it must contain a '/'.
local function path_start()
  local before = line_to_cursor()
  local start = vim.fn.match(before, [[\f*$]])
  if start < 0 or not before:sub(start + 1):find('/', 1, true) then
    return -2
  end
  return start
end

local function is_absolute(path)
  return path:match('^[/~]') ~= nil
end

function M.path(findstart, base)
  if findstart == 1 then
    return path_start()
  end
  local seen, items = {}, {}
  local function add(word)
    if not seen[word] and #items < M.path_max_items then
      seen[word] = true
      items[#items + 1] = { word = word, menu = '[File]' }
    end
  end
  for _, word in ipairs(vim.fn.getcompletion(base, 'file')) do
    add(word)
  end
  -- Relative paths are tried from the buffer's directory too.
  local bufdir = vim.fn.expand('%:p:h')
  if not is_absolute(base) and bufdir ~= '' and bufdir ~= vim.fn.getcwd() then
    local prefix = bufdir .. '/'
    for _, full in ipairs(vim.fn.getcompletion(prefix .. base, 'file')) do
      if vim.startswith(full, prefix) then
        add(full:sub(#prefix + 1))
      end
    end
  end
  return items
end
-- <<< path

-- >>> rg
-- rg over a DrvFs mount (/mnt/c on WSL) is too slow for completion.
local function rg_root()
  local root = vim.fs.root(0, '.git') or vim.fn.getcwd()
  if root:match('^/mnt/%a/') or root == vim.env.HOME or root == '/' then
    return nil
  end
  return root
end

local function rg_pattern(base)
  return [[\b]] .. base:gsub('[%^%$%.%*%+%?%(%)%[%]{}|\\]', '\\%0') .. [[\w+]]
end

local has_rg -- cached: executable() walks PATH on every call
function M.rg(findstart, base)
  if findstart == 1 then
    if has_rg == nil then
      has_rg = vim.fn.executable('rg') == 1
    end
    local start = keyword_start()
    local typed = line_to_cursor():sub(start + 1)
    if not has_rg or vim.fn.strchars(typed) < M.rg_min_length then
      return -2
    end
    return start
  end
  local root = rg_root()
  if not root then
    return {}
  end
  local done, stdout = false, ''
  local ok, proc = pcall(vim.system, {
    'rg', '--no-config', '--only-matching', '--no-filename', '--no-line-number',
    '--smart-case', '--max-count', '20', '--max-columns', '300',
    '-e', rg_pattern(base), '.',
  }, { cwd = root, text = true }, function(res)
    stdout = res.stdout or ''
    done = true
  end)
  if not ok then
    return {}
  end
  -- fast_only: completion runs under textlock; scheduled callbacks of other
  -- plugins must not run inside it
  vim.wait(M.rg_timeout_ms, function()
    return done or vim.fn.complete_check() == 1
  end, 5, true)
  if not done then
    pcall(proc.kill, proc, 'sigterm')
    return {}
  end
  local seen, items = {}, {}
  for word in stdout:gmatch('[^\n]+') do
    if word ~= base and not seen[word] then
      seen[word] = true
      items[#items + 1] = { word = word, menu = '[rg]' }
      if #items >= M.rg_max_items then
        break
      end
    end
  end
  return items
end
-- <<< rg

-- >>> lsp
-- The builtin client inserts textEdit.newText as the word but ignores the
-- part of the edit range after the cursor, so an item that also replaces
-- auto-paired text (obsidian "[[Note]]" over "]]") doubled it. Drop the
-- suffix of newText that is already in the buffer after the cursor.
--
-- vim.lsp.completion keeps the convert of the first client enabled in a
-- buffer for all clients, so this one also does skkelua's (its items carry
-- the display text in data.display).
function M.lsp_convert(item)
  local display = vim.tbl_get(item, 'data', 'display')
  if display then
    return { info = '', abbr = display }
  end
  local edit = item.textEdit
  if not (edit and edit.newText and edit.range) or item.insertTextFormat == 2 then
    return {}
  end
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  if edit.range['end'].line ~= row - 1 then
    return {}
  end
  local line = vim.api.nvim_get_current_line()
  local text = edit.newText:match('[^\n]*')
  -- convert gets no client, so try the encodings of the attached ones
  -- (obsidian-ls counts UTF-8 bytes, most servers UTF-16 units)
  local encodings = vim.tbl_map(function(client)
    return client.offset_encoding or 'utf-16'
  end, vim.lsp.get_clients({ bufnr = 0 }))
  if #encodings == 0 then
    encodings = { 'utf-16' }
  end
  local tried = {}
  for _, enc in ipairs(encodings) do
    if not tried[enc] then
      tried[enc] = true
      local ok, end_byte = pcall(vim.str_byteindex, line, enc, edit.range['end'].character, false)
      if ok and end_byte > col then
        local covered = line:sub(col + 1, end_byte)
        if #text > #covered and text:sub(-#covered) == covered then
          return { word = text:sub(1, -#covered - 1) }
        end
      end
    end
  end
  return {}
end
-- <<< lsp

local function feed(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function luasnip_jumpable(dir)
  local ls = package.loaded.luasnip
  return ls ~= nil and ls.locally_jumpable(dir)
end

-- <Tab>: next item > snippet jump (vim.snippet for LSP, LuaSnip for
-- [LS]) > indent at line start/after a space > start completion manually.
function M.tab()
  if vim.fn.pumvisible() == 1 then
    return feed('<C-n>')
  end
  if vim.snippet.active({ direction = 1 }) then
    return feed('<Cmd>lua vim.snippet.jump(1)<CR>')
  end
  if luasnip_jumpable(1) then
    return feed('<Cmd>lua require("luasnip").jump(1)<CR>')
  end
  local before = line_to_cursor()
  if before == '' or before:match('%s$') then
    return feed('<Tab>')
  end
  return feed('<C-n>')
end

function M.s_tab()
  if vim.fn.pumvisible() == 1 then
    return feed('<C-p>')
  end
  if vim.snippet.active({ direction = -1 }) then
    return feed('<Cmd>lua vim.snippet.jump(-1)<CR>')
  end
  if luasnip_jumpable(-1) then
    return feed('<Cmd>lua require("luasnip").jump(-1)<CR>')
  end
  return feed('<S-Tab>')
end

-- <C-e>: close the popup, otherwise cycle a LuaSnip choice node.
function M.c_e()
  if vim.fn.pumvisible() == 1 then
    return feed('<C-e>')
  end
  local ls = package.loaded.luasnip
  if ls and ls.choice_active() then
    return feed('<Cmd>lua require("luasnip").change_choice(1)<CR>')
  end
  return feed('<C-e>')
end

M.sources = table.concat({
  'Fv:lua.NativeCmp.luasnip',
  'Fv:lua.vim.lsp.omnifunc',
  '.',
  'w',
  'b',
  'Fv:lua.NativeCmp.path',
  'k^5',
  'Fv:lua.NativeCmp.rg^' .. M.rg_max_items,
}, ',')

-- Popups in special buffers (prompts, pickers, terminals) are noise.
local function update_buffer_autocomplete()
  vim.bo.autocomplete = vim.bo.buftype == '' and not vim.b.completion_disabled
end

function M.setup()
  vim.o.complete = M.sources
  vim.o.completeopt = 'menuone,noselect,fuzzy,popup'
  vim.o.autocomplete = true
  vim.o.pumheight = 10
  vim.o.pummaxwidth = 50
  vim.o.dictionary = vim.fn.stdpath('config') .. '/dict/words.txt'
  vim.opt.shortmess:append('c')

  local group = vim.api.nvim_create_augroup('NativeCompletion', { clear = true })
  vim.api.nvim_create_autocmd('InsertEnter', { group = group, callback = update_buffer_autocomplete })
  vim.api.nvim_create_autocmd('CompleteDone', { group = group, callback = expand_luasnip })
  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      -- skkelua enables its own client on skkelua-enable
      if client and client.name ~= 'skkelua' and client:supports_method('textDocument/completion') then
        -- autotrigger covers trigger characters ('.', '[', '#', ...), which
        -- 'autocomplete' ignores because they are not keyword characters.
        vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true, convert = M.lsp_convert })
      end
    end,
  })

  local expr = { expr = true, replace_keycodes = false }
  vim.keymap.set('i', '<Tab>', M.tab, expr)
  vim.keymap.set('i', '<S-Tab>', M.s_tab, expr)
  -- a snippet jump leaves a placeholder selected (Select mode)
  for dir, key in pairs({ [1] = '<Tab>', [-1] = '<S-Tab>' }) do
    vim.keymap.set('s', key, function()
      if vim.snippet.active({ direction = dir }) then
        return feed(('<Cmd>lua vim.snippet.jump(%d)<CR>'):format(dir))
      end
      if luasnip_jumpable(dir) then
        return feed(('<Cmd>lua require("luasnip").jump(%d)<CR>'):format(dir))
      end
      return feed(key)
    end, expr)
  end
  vim.keymap.set('i', '<C-e>', M.c_e, expr)
end

return M

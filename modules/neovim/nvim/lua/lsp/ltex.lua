-- ltex-ls configuration with integrated dictionary management
-- Spell checking via LSP diagnostics (underlines) + dictionary persistence
-- Code actions: addToDictionary, disableRules, hideFalsePositives
-- Keymaps: zg (global), zG (local), zug/zuG (remove)

local global_dir = vim.fn.expand('~/.local/share/ltex')
local local_dir = '.ltex'

---------------------------------------------------------------------------
-- File I/O
---------------------------------------------------------------------------
local function read_lines(path)
  local lines = {}
  local f = io.open(path, 'r')
  if f then
    for line in f:lines() do
      if line ~= '' then lines[#lines + 1] = line end
    end
    f:close()
  end
  return lines
end

local function write_lines(path, lines)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local f = io.open(path, 'w')
  if f then
    for _, l in ipairs(lines) do f:write(l .. '\n') end
    f:close()
  end
end

local function append_unique(path, value)
  local lines = read_lines(path)
  for _, l in ipairs(lines) do
    if l == value then return end
  end
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  local f = io.open(path, 'a')
  if f then
    f:write(value .. '\n')
    f:close()
  end
end

local function remove_entry(path, target)
  local lines = read_lines(path)
  local new = {}
  for _, l in ipairs(lines) do
    if l ~= target then new[#new + 1] = l end
  end
  write_lines(path, new)
end

---------------------------------------------------------------------------
-- Path builder: base_dir/kind/lang.txt
---------------------------------------------------------------------------
local function fpath(base, kind, lang)
  return base .. '/' .. kind .. '/' .. lang .. '.txt'
end

---------------------------------------------------------------------------
-- Merge global + project-local entries for a given kind and language
---------------------------------------------------------------------------
local function merged(kind, lang)
  local entries = read_lines(fpath(global_dir, kind, lang))
  for _, e in ipairs(read_lines(fpath(local_dir, kind, lang))) do
    entries[#entries + 1] = e
  end
  return entries
end

---------------------------------------------------------------------------
-- Build ltex settings from current dictionary files
---------------------------------------------------------------------------
local function build_settings(lang)
  return {
    ltex = {
      language = lang,
      dictionary = { [lang] = merged('dictionaries', lang) },
      disabledRules = { [lang] = merged('disabledRules', lang) },
      hiddenFalsePositives = { [lang] = merged('hiddenFalsePositives', lang) },
    },
  }
end

---------------------------------------------------------------------------
-- Notify all ltex clients of updated settings
---------------------------------------------------------------------------
local function refresh()
  for _, client in ipairs(vim.lsp.get_clients({ name = 'ltex' })) do
    local lang = client.config.settings.ltex.language or 'en-US'
    client.config.settings = build_settings(lang)
    client:notify('workspace/didChangeConfiguration', {
      settings = client.config.settings,
    })
    -- Force re-diagnosis on all attached buffers to clear stale diagnostics
    for _, bufnr in ipairs(vim.lsp.get_buffers_by_client_id(client.id)) do
      local uri = vim.uri_from_bufnr(bufnr)
      local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
      client:notify('textDocument/didChange', {
        textDocument = { uri = uri, version = vim.lsp.util.buf_versions[bufnr] or 0 },
        contentChanges = { { text = text } },
      })
    end
  end
end

---------------------------------------------------------------------------
-- Code action handlers (ltex-ls custom commands)
---------------------------------------------------------------------------
vim.lsp.commands['_ltex.addToDictionary'] = function(command)
  for lang, words in pairs(command.arguments[1].words) do
    for _, w in ipairs(words) do
      append_unique(fpath(global_dir, 'dictionaries', lang), w)
    end
  end
  refresh()
end

vim.lsp.commands['_ltex.disableRules'] = function(command)
  for lang, rules in pairs(command.arguments[1].ruleIds) do
    for _, r in ipairs(rules) do
      append_unique(fpath(global_dir, 'disabledRules', lang), r)
    end
  end
  refresh()
end

vim.lsp.commands['_ltex.hideFalsePositives'] = function(command)
  for lang, fps in pairs(command.arguments[1].falsePositives) do
    for _, fp in ipairs(fps) do
      append_unique(fpath(global_dir, 'hiddenFalsePositives', lang), fp)
    end
  end
  refresh()
end

---------------------------------------------------------------------------
-- Buffer-local keymaps (set on LspAttach)
---------------------------------------------------------------------------
local function setup_keymaps(client, bufnr)
  local lang = client.config.settings.ltex.language or 'en-US'
  local opts = { buffer = bufnr, silent = true }

  vim.keymap.set('n', 'zg', function()
    local word = vim.fn.expand('<cword>')
    append_unique(fpath(global_dir, 'dictionaries', lang), word)
    refresh()
    vim.notify('"' .. word .. '" → global dictionary', vim.log.levels.INFO)
  end, opts)

  vim.keymap.set('n', 'zG', function()
    local word = vim.fn.expand('<cword>')
    append_unique(fpath(local_dir, 'dictionaries', lang), word)
    refresh()
    vim.notify('"' .. word .. '" → local dictionary', vim.log.levels.INFO)
  end, opts)

  vim.keymap.set('n', 'zug', function()
    local word = vim.fn.expand('<cword>')
    remove_entry(fpath(global_dir, 'dictionaries', lang), word)
    refresh()
    vim.notify('"' .. word .. '" ← global dictionary', vim.log.levels.INFO)
  end, opts)

  vim.keymap.set('n', 'zuG', function()
    local word = vim.fn.expand('<cword>')
    remove_entry(fpath(local_dir, 'dictionaries', lang), word)
    refresh()
    vim.notify('"' .. word .. '" ← local dictionary', vim.log.levels.INFO)
  end, opts)
end

---------------------------------------------------------------------------
-- Server configuration
---------------------------------------------------------------------------
return {
  cmd = { 'ltex-ls' },
  filetypes = { 'tex', 'latex', 'plaintex', 'markdown' },
  settings = build_settings('en-US'),
  on_attach = function(client, bufnr)
    -- Reload settings on attach to pick up project-local dictionaries
    local lang = client.config.settings.ltex.language or 'en-US'
    client.config.settings = build_settings(lang)
    client:notify('workspace/didChangeConfiguration', {
      settings = client.config.settings,
    })
    setup_keymaps(client, bufnr)
  end,
}

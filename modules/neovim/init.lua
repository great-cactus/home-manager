-- Leader / global vars
vim.g.mapleader        = ' '
vim.g.tex_flavor       = 'latex'
vim.g.fortran_free_source = 0

-- MyAutoCmd: referenced by some plugin ftplugin scripts (e.g. markdown.vim)
vim.api.nvim_create_augroup('MyAutoCmd', { clear = true })

-- Plugin manager (dein)
-- インストーラ (dein-installer.vim) の構造に従う:
--   dein.vim は ~/.cache/dein/repos/github.com/Shougo/dein.vim に配置
--   TOML は ~/.config/nvim/dein/ で管理（Nix が ~/.cache/dein/ に干渉しないよう分離）
local dein_base     = vim.fn.expand('~/.cache/dein')
local dein_src      = dein_base .. '/repos/github.com/Shougo/dein.vim'
local dein_toml_dir = vim.fn.stdpath('config') .. '/dein'

vim.opt.runtimepath:prepend(dein_src)

if vim.fn['dein#load_state'](dein_base) == 1 then
  vim.fn['dein#begin'](dein_base)

  vim.fn['dein#load_toml'](dein_toml_dir .. '/dein.toml',      { lazy = false })
  vim.fn['dein#load_toml'](dein_toml_dir .. '/dein_lazy.toml', { lazy = true  })
  vim.fn['dein#add'](dein_src)
  vim.fn['dein#end']()
  vim.fn['dein#save_state']()
end

if vim.fn['dein#check_install']() ~= 0 then
  vim.fn['dein#install']()
end

vim.cmd('filetype indent plugin on')
vim.cmd('syntax enable')

-- Disable unused built-in plugins
vim.g.did_install_default_menus = 1
vim.g.did_install_syntax_menu   = 1
vim.g.did_indent_on             = 1
vim.g.did_load_filetypes        = 1
vim.g.did_load_ftplugin         = 1
vim.g.loaded_2html_plugin       = 1
vim.g.loaded_gzip               = 1
vim.g.loaded_man                = 1
vim.g.loaded_matchit            = 1
vim.g.loaded_matchparen         = 1
vim.g.loaded_netrwPlugin        = 1
vim.g.loaded_remote_plugins     = 1
vim.g.loaded_shada_plugin       = 1
vim.g.loaded_spellfile_plugin   = 1
vim.g.loaded_tarPlugin          = 1
vim.g.loaded_tutor_mode_plugin  = 1
vim.g.loaded_zipPlugin          = 1
vim.g.skip_loading_mswin        = 1

-- General
vim.opt.foldlevel      = 99
vim.opt.foldlevelstart = 99
vim.opt.belloff        = 'all'
vim.opt.backspace      = 'indent,eol,start'
vim.opt.swapfile       = false

-- Tab / indent
vim.g.markdown_recommended_style = 0  -- keep global shiftwidth=2 for markdown
vim.opt.tabstop     = 2
vim.opt.shiftwidth  = 2
vim.opt.expandtab   = true
vim.opt.autoindent  = true
vim.opt.smartindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.wrapscan   = true
vim.opt.showmatch  = true
vim.opt.hlsearch   = true
vim.opt.smartcase  = true

-- Display
vim.opt.termguicolors = true
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.display        = 'lastline'
vim.opt.virtualedit    = 'onemore'
vim.opt.wildmode       = 'list:longest'
vim.opt.list           = true
vim.opt.listchars      = { tab = '^ ', trail = '~' }
vim.opt.cmdheight      = 0
vim.opt.conceallevel   = 2
vim.opt.completeopt    = 'menuone'
vim.opt.autochdir      = true
vim.opt.laststatus     = 0
vim.opt.statusline     = "%{repeat('─',winwidth('.'))}"

-- Clipboard
vim.opt.clipboard = 'unnamedplus'

-- Persistent undo
if vim.fn.has('persistent_undo') == 1 then
  vim.opt.undodir = { './.vimundo', vim.fn.expand('~/.vimundo') }
  vim.api.nvim_create_autocmd('BufReadPre', {
    pattern  = vim.fn.expand('~') .. '/*',
    callback = function() vim.opt_local.undofile = true end,
    group    = vim.api.nvim_create_augroup('SaveUndoFile', { clear = true }),
  })
end

-- Keymaps: motion
vim.keymap.set('n', '<Esc>', '<Cmd>nohlsearch<CR><Esc>', { silent = true })
vim.keymap.set({ 'n', 'v' }, 'L', '$')
vim.keymap.set({ 'n', 'v' }, 'H', '^')
vim.keymap.set({ 'n', 'v' }, '$', '<Nop>')
vim.keymap.set({ 'n', 'v' }, '^', '<Nop>')
vim.keymap.set('n', 'gj', 'gj', { noremap = true })
vim.keymap.set('n', 'gk', 'gk', { noremap = true })
vim.keymap.set('n', 'n', 'mNn')

-- Keymaps: US keyboard
vim.keymap.set({ 'n', 'v' }, ';', ':')
vim.keymap.set({ 'n', 'v' }, ':', ';')

-- Keymaps: insert mode
vim.keymap.set('i', '<C-l>', '<Right>', { silent = true })
vim.keymap.set('i', '<C-h>', '<Left>',  { silent = true })
vim.keymap.set('i', 'jj',   '<Esc>',   { silent = true })

-- Keymaps: yank / delete
vim.keymap.set({ 'n', 'v' }, 'x', '"_x')
vim.keymap.set('v', 'p', '"_dP')

-- Keymaps: leader
vim.keymap.set('n', '<Leader>t', ':tabe<Space>', { silent = false })
vim.keymap.set('n', '<leader>s', 'mS:%s/',       { desc = 'Search with mark' })
vim.keymap.set('v', '<leader>s', "mS:'<,'>s/",   { desc = 'Search with mark (visual)' })

-- H command: open help fullscreen
vim.api.nvim_create_user_command('H', function(opts)
  vim.cmd('help ' .. opts.args .. ' | only')
end, { nargs = '*', complete = 'help' })

-- Exact match replace
local function exact_match_replace()
  local search = vim.fn.input('Search for: ')
  if search == '' then return end
  local replace = vim.fn.input('Replace with: ')
  if replace == '' then return end
  vim.cmd('%s/\\<' .. search .. '\\>/' .. replace .. '/gc')
end
vim.keymap.set('n', '<Leader>S', exact_match_replace)

-- Toggle quickfix
local function toggle_quickfix()
  local nr = vim.fn.winnr('$')
  vim.cmd('cwindow')
  if vim.fn.winnr('$') == nr then
    vim.cmd('cclose')
  end
end
vim.keymap.set('n', '<leader>q', toggle_quickfix, { silent = true })

-- Expand / compact function params
local function expand_function_params()
  local cursor = vim.fn.getpos('.')
  vim.cmd('normal! [(')
  local s = vim.fn.line('.')
  vim.cmd('normal! %')
  local e = vim.fn.line('.')
  vim.cmd('silent! ' .. s .. ',' .. e .. [[s/\(\w\+\.\w\+\)(\([^)]*\))/\1(\r    \2\r)/g]])
  vim.cmd('silent! ' .. s .. ',' .. e .. [[s/,\s*/,\r    /g]])
  vim.fn.setpos('.', cursor)
end

local function compact_function_params()
  local cursor = vim.fn.getpos('.')
  vim.cmd('normal! [(')
  local s = vim.fn.line('.')
  vim.cmd('normal! %')
  local e = vim.fn.line('.')
  vim.cmd('silent! ' .. s .. ',' .. e .. [[s/\(\w\+\.\w\+\)(\_s*\([^)]*\)\_s*)/\1(\2)/g]])
  vim.cmd('silent! ' .. s .. ',' .. e .. [[s/,\_s*/,/g]])
  vim.cmd('silent! ' .. s .. ',' .. e .. [[s/,/, /g]])
  vim.cmd('silent! ' .. s .. ',' .. e .. [[s/=\s*/=/g]])
  vim.cmd('silent! ' .. s .. ',' .. e .. [[s/\s*=/=/g]])
  vim.fn.setpos('.', cursor)
end

local function toggle_function_format()
  local line = vim.fn.getline('.')
  if line:match('%w+%.%w+%(') and not line:match(',\n') then
    expand_function_params()
  else
    compact_function_params()
  end
end
vim.keymap.set('n', '<leader>ef', toggle_function_format)

-- Autocommands
local ag = vim.api.nvim_create_augroup

-- Restore cursor position on open
vim.api.nvim_create_autocmd('BufReadPost', {
  group   = ag('KeepLastPosition', { clear = true }),
  pattern = '*',
  callback = function()
    local line = vim.fn.line("'\"")
    if line > 0 and line <= vim.fn.line('$') then
      vim.cmd("normal! g'\"")
    end
  end,
})

-- Checktime on focus
vim.api.nvim_create_autocmd({ 'InsertEnter', 'WinEnter' }, {
  group   = ag('VimCheckTime', { clear = true }),
  pattern = '*',
  command = 'checktime',
})

-- Strip trailing whitespace on save (preserving cursor)
local function fix_trailing_whitespace()
  local pos         = vim.fn.getpos('.')
  local was_modified = vim.bo.modified
  vim.cmd([[silent! %s/\\\@<!\s\+$//]])
  if not was_modified then
    vim.bo.modified = false
  end
  vim.fn.setpos('.', pos)
end
vim.api.nvim_create_autocmd('BufWritePre', {
  group    = ag('FixPunctuationGroup', { clear = true }),
  pattern  = '*',
  callback = fix_trailing_whitespace,
})

-- View save / restore
vim.opt.viewoptions:remove('options')
vim.opt.viewoptions:remove('folds')

local view_group = ag('AutoView', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
  group   = view_group,
  pattern = '*',
  callback = function()
    if vim.fn.expand('%') ~= '' and vim.bo.buftype ~= 'nofile' then
      vim.cmd('mkview')
    end
  end,
})
vim.api.nvim_create_autocmd('BufRead', {
  group   = view_group,
  pattern = '*',
  callback = function()
    if vim.fn.expand('%') ~= '' and vim.bo.buftype ~= 'nofile' then
      vim.cmd('silent! loadview')
    end
  end,
})

-- StatusLine: blend with Normal background
local function setup_statusline_hl()
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })
  local bg = normal.bg
  if bg then
    vim.api.nvim_set_hl(0, 'StatusLine',   { bg = bg })
    vim.api.nvim_set_hl(0, 'StatusLineNC', { bg = bg })
  else
    vim.api.nvim_set_hl(0, 'StatusLine',   { link = 'Normal' })
    vim.api.nvim_set_hl(0, 'StatusLineNC', { link = 'Normal' })
  end
end
vim.api.nvim_create_autocmd({ 'VimEnter', 'ColorScheme' }, {
  callback = setup_statusline_hl,
})

-- Tree-sitter: native highlight and fold (nvim 0.12 built-in)
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldenable = false

-- Colorscheme (standalone, no plugin dependency)
vim.opt.background = 'light'
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function() vim.cmd.colorscheme 'Yokan' end,
})

-- Modules
require('config.terminal')
require('config.claude')
require('config.substitute_nohl')
require('config.lsp_treesitter_toggle').setup({ command = 'toggle' })
require('config.tabline_toggle').setup()
require('config.smart_scroll').setup()
require('config.thino').setup()
require('config.one_sentence_per_line').setup()

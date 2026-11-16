-- Leader / global vars
vim.g.mapleader        = ' '
vim.g.tex_flavor       = 'latex'
vim.g.fortran_free_source = 0

-- MyAutoCmd: referenced by some plugin ftplugin scripts (e.g. markdown.vim)
vim.api.nvim_create_augroup('MyAutoCmd', { clear = true })

-- PATH: drop Windows directories appended by WSL interop (/mnt/c/...).
-- A missed executable()/exepath() lookup walks the whole PATH, and each stat
-- on a DrvFs mount costs 1-10 ms, so plugin probes for optional tools (there
-- are dozens at startup) made opening a file take seconds. Child terminals
-- get the full PATH back (see config/terminal.lua).
vim.g.host_path = vim.env.PATH
if vim.fn.has('wsl') == 1 then
  local dirs = vim.split(vim.env.PATH or '', ':', { plain = true })
  vim.env.PATH = table.concat(vim.tbl_filter(function(dir)
    return not dir:match('^/mnt/%a/')
  end, dirs), ':')
end

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

-- Deferred plugins: entries marked `very_lazy = 1` in dein_lazy.toml (UI
-- decorations) are sourced one event-loop tick after VimEnter, i.e. after
-- the first redraw, so they never delay showing the first file.
-- Each of them attaches to the already-open buffers on setup, so FileType is
-- ignored while sourcing: dein otherwise re-fires FileType for the current
-- buffer whenever a sourced plugin added FileType autocmds, which re-ran
-- every ftplugin/LSP/obsidian handler.
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.schedule(function()
      local names = {}
      for name, plugin in pairs(vim.fn['dein#get']()) do
        if plugin.very_lazy == 1 and plugin.sourced == 0 then
          names[#names + 1] = name
        end
      end
      table.sort(names)
      -- One plugin per tick so pending input is handled in between
      local function source_next(i)
        local name = names[i]
        if not name then
          return
        end
        local saved = vim.o.eventignore
        vim.opt.eventignore:append('FileType')
        local ok, err = pcall(vim.fn['dein#source'], { name })
        vim.o.eventignore = saved
        if not ok then
          vim.notify('very_lazy: ' .. name .. ': ' .. tostring(err), vim.log.levels.ERROR)
        end
        vim.schedule(function() source_next(i + 1) end)
      end
      source_next(1)
    end)
  end,
})

vim.cmd('filetype indent plugin on')
-- `syntax enable` is issued after the tree-sitter FileType autocmd below.

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
vim.opt.timeoutlen     = 500

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
-- 'conceallevel' starts at 0 and becomes 2 right after the first redraw:
-- with conceal on, the tree-sitter highlighter parses markdown once per
-- screen line to find concealed lines (conceal_lines), which made opening a
-- note about 2x slower. Only windows still at the startup value change.
vim.opt.conceallevel   = 0
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.schedule(function()
      vim.go.conceallevel = 2
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.wo[win].conceallevel == 0 then
          vim.wo[win].conceallevel = 2
        end
      end
    end)
  end,
})
vim.opt.autochdir      = true
vim.opt.laststatus     = 0
vim.opt.statusline     = "%{repeat('─',winwidth('.'))}"

-- Clipboard
vim.opt.clipboard = 'unnamedplus'

if vim.fn.has('wsl') == 1 and vim.fn.executable('wl-paste') == 1 then
  -- WSLg: wl-copy/wl-paste (Wayland clipboard, UTF-8 native)
  vim.g.clipboard = {
    name = 'WSLg Clipboard',
    copy = {
      ['+'] = { 'wl-copy' },
      ['*'] = { 'wl-copy', '--primary' },
    },
    paste = {
      ['+'] = { 'wl-paste', '--no-newline' },
      ['*'] = { 'wl-paste', '--primary', '--no-newline' },
    },
    cache_enabled = true,
  }
elseif vim.fn.has('wsl') == 1 then
  -- WSL2 fallback: clip.exe (copy) + powershell.exe (paste)
  vim.g.clipboard = {
    name = 'WSL Clipboard',
    copy = {
      ['+'] = function(lines) vim.fn.system('clip.exe', table.concat(lines, '\n')) end,
      ['*'] = function(lines) vim.fn.system('clip.exe', table.concat(lines, '\n')) end,
    },
    paste = {
      ['+'] = function()
        return vim.fn.systemlist('powershell.exe -NoProfile -Command Get-Clipboard')
      end,
      ['*'] = function()
        return vim.fn.systemlist('powershell.exe -NoProfile -Command Get-Clipboard')
      end,
    },
    cache_enabled = true,
  }
elseif os.getenv('SSH_CONNECTION') then
  -- SSH: OSC 52
  local osc52 = require('vim.ui.clipboard.osc52')
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = osc52.copy('+'),
      ['*'] = osc52.copy('*'),
    },
    paste = {
      ['+'] = osc52.paste('+'),
      ['*'] = osc52.paste('*'),
    },
  }
end

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
vim.keymap.set('n', '<Esc><Esc>', '<Cmd>nohlsearch<CR>', { silent = true })
vim.keymap.set({ 'n', 'v' }, 'L', '$')
vim.keymap.set({ 'n', 'v' }, 'H', '^')
vim.keymap.set({ 'n', 'v' }, '$', '<Nop>')
vim.keymap.set({ 'n', 'v' }, '^', '<Nop>')
-- Visual line submode: gj/gk後、timeoutlen以内のj/kはgj/gkとして動作
-- ref: https://zenn.dev/mattn/articles/83c2d4c7645faa
vim.keymap.set('n', 'gj', '<Cmd>normal! gj<CR><Plug>(vline)', { remap = true })
vim.keymap.set('n', 'gk', '<Cmd>normal! gk<CR><Plug>(vline)', { remap = true })
vim.keymap.set('n', '<Plug>(vline)j', '<Cmd>normal! gj<CR><Plug>(vline)', { remap = true })
vim.keymap.set('n', '<Plug>(vline)k', '<Cmd>normal! gk<CR><Plug>(vline)', { remap = true })
vim.keymap.set('n', '<Plug>(vline)', '<Nop>')
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
  local pos          = vim.fn.getpos('.')
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

-- Big file detection (must run before FileType-based treesitter/fold setup)
require('config.bigfile').setup()

-- Tree-sitter: native highlight and fold (nvim 0.12 built-in)
-- Registered before `syntax enable` so it runs ahead of the `syntaxset`
-- FileType autocmd: a buffer marked as tree-sitter highlighted makes
-- $VIMRUNTIME/syntax/syntax.vim skip the regex syntax load, which is slow
-- (syntax/tex.vim ~90 ms) and redundant.
-- The start itself is deferred past the first redraw: compiling a highlights
-- query takes up to ~300 ms (LaTeX) and would otherwise delay showing the file.
local function ts_lang_for(buf, ft)
  local lang = vim.treesitter.language.get_lang(ft)
  if vim.b[buf].large_file or not lang then
    return nil
  end
  -- language.add() returns nil (no error) when no parser is on the runtimepath
  if not vim.treesitter.language.add(lang) then
    return nil
  end
  return lang
end

local function ts_start_deferred(buf, ft, lang)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= ft then
    return
  end
  -- ftplugin/markdown.lua already started it; restarting would reload syntax
  if not vim.treesitter.highlighter.active[buf] and not pcall(vim.treesitter.start, buf, lang) then
    vim.b[buf].ts_highlight = nil
    vim.bo[buf].syntax = ft  -- fall back to regex syntax
    return
  end
  -- Set treesitter foldexpr per window (not globally, to avoid cost on
  -- terminal/bigfile/no-parser buffers)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.wo[win][0].foldmethod = 'expr'
    vim.wo[win][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  end
end

vim.api.nvim_create_autocmd('FileType', {
  group = ag('TreesitterStart', { clear = true }),
  callback = function(args)
    local buf, ft = args.buf, args.match
    local lang = ts_lang_for(buf, ft)
    if not lang then
      if not vim.treesitter.highlighter.active[buf] then
        vim.b[buf].ts_highlight = nil
      end
      return
    end
    vim.b[buf].ts_highlight = true
    vim.schedule(function() ts_start_deferred(buf, ft, lang) end)
  end,
})
vim.opt.foldenable = false
vim.cmd('syntax enable')

-- Colorscheme (standalone, no plugin dependency)
vim.opt.background = 'light'
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function() vim.cmd.colorscheme 'Yokan' end,
})

-- Modules
require('config.terminal')
require('config.substitute_nohl')
require('config.lsp_treesitter_toggle').setup({ command = 'toggle' })
require('config.tabline_toggle').setup()
require('config.smart_scroll').setup({
  time_scale = 2.0,
  key_repeat  = 0.05,
  cursor_pos  = 0.25,
})
require('config.dict').setup()
require('config.completion').setup()

-- Read aloud (plugins/read_text, Lua port of read-text.vim)
require('plugins.read_text').setup({
  tts_provider = 'kokoro',
  audio_command = 'mpv',
  audio_args = { '--no-video', '--audio-samplerate=48000', '--ao=pulse', '--pulse-buffer=2000', '--pulse-latency-hacks=yes', '--quiet' },
  split_threshold = 20,
  speed = 1.0,
  voicevox_url = 'https://hideously-cheerful-swift.ngrok-free.app',
  espeak_voice = 'en',
  espeak_variant = 'f2',
  espeak_command = 'espeak-ng',
  melo_language = 'EN',
  melo_speaker = 'EN-BR',
  kokoro_lang = 'en-gb',
  kokoro_voice = 'bf_isabella',
  kokoro_model_path = '~/.local/share/kokoro-tts/kokoro-v1.0.onnx',
  kokoro_voices_path = '~/.local/share/kokoro-tts/voices-v1.0.bin',
})
vim.keymap.set('n', '<leader>rt', '<Plug>(read-text-from-cursor-async)')
vim.keymap.set('x', '<leader>rt', '<Plug>(read-text-selection-async)')
vim.keymap.set('n', '<leader>al', '<Plug>(read-text-line-async)')
vim.keymap.set('n', '<leader>rp', '<Plug>(read-text-toggle-pause)')
vim.keymap.set('n', '<leader>rs', '<Plug>(read-text-stop)')
require('config.one_sentence_per_line').setup()
require('config.comma_period').setup()
require('config.runner').setup({
  run_key = '<F5>',
  output_key = '<leader>ro',
  stop_key = '<Esc>',
  filetype = {
    python = "cd $dir && uv run $fileName",
    tex    = "cd $dir && latexmk $fileName",
  }
})

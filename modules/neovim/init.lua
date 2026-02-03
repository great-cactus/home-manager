-- Leader key
vim.g.mapleader = " "
vim.g.tex_flavor = "latex"

-- dein.vim
vim.opt.compatible = false
local dein_base = vim.fn.expand("~/.cache/dein")
local dein_src = dein_base .. "/repos/github.com/Shougo/dein.vim"
vim.opt.runtimepath:prepend(dein_src)

if vim.fn["dein#load_state"](dein_base) == 1 then
  vim.fn["dein#begin"](dein_base)
  vim.g["dein#auto_recache"] = 1

  local toml = dein_base .. "/dein.toml"
  local lazy_toml = dein_base .. "/dein_lazy.toml"

  vim.fn["dein#load_toml"](toml, { lazy = 0 })
  vim.fn["dein#load_toml"](lazy_toml, { lazy = 1 })

  vim.fn["dein#add"](dein_src)

  vim.fn["dein#end"]()
  vim.fn["dein#save_state"]()
end

if vim.fn["dein#check_install"]() == 1 then
  vim.fn["dein#install"]()
end

-- Filetype and syntax
vim.cmd("filetype indent plugin on")
vim.cmd("syntax enable")

-- Basic settings
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.belloff = "all"
vim.opt.backspace = "indent,eol,start"
vim.opt.swapfile = false

-- Tab settings
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Indent settings
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Search settings
vim.opt.ignorecase = true
vim.opt.wrapscan = true
vim.opt.showmatch = true
vim.opt.hlsearch = true
vim.opt.smartcase = true

-- Display settings
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.display = "lastline"
vim.opt.virtualedit = "onemore"
vim.opt.wildmode = "list:longest"

-- Highlight tab, trail
vim.opt.list = true
vim.opt.listchars = { tab = "^ ", trail = "~" }

vim.opt.cmdheight = 0
vim.opt.conceallevel = 2

-- Disable standard plugins
vim.g.did_install_default_menus = 1
vim.g.did_install_syntax_menu = 1
vim.g.did_indent_on = 1
vim.g.did_load_filetypes = 1
vim.g.did_load_ftplugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_gzip = 1
vim.g.loaded_man = 1
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_remote_plugins = 1
vim.g.loaded_shada_plugin = 1
vim.g.loaded_spellfile_plugin = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.skip_loading_mswin = 1

-- Clear highlight
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>", { silent = true })

-- Exact match replace
vim.keymap.set("n", "<leader>S", function()
  local search_term = vim.fn.input("Search for: ")
  if search_term == "" then return end
  local replace_term = vim.fn.input("Replace with: ")
  if replace_term == "" then return end
  vim.cmd("%s/\\<" .. search_term .. "\\>/" .. replace_term .. "/gc")
end)

-- Tab
vim.keymap.set("n", "<Leader>t", ":tabe ")

-- H/L for line start/end
vim.keymap.set("n", "L", "$")
vim.keymap.set("n", "H", "^")
vim.keymap.set("v", "L", "$")
vim.keymap.set("v", "H", "^")
vim.keymap.set({ "n", "v" }, "$", "<nop>")
vim.keymap.set({ "n", "v" }, "^", "<nop>")

-- Full screen help
vim.api.nvim_create_user_command("H", function(opts)
  vim.cmd("help " .. opts.args)
  vim.cmd("only")
end, { nargs = "*", complete = "help" })

-- Completion
vim.opt.completeopt = "menuone"

-- Restore cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- US keyboard swap ; and :
vim.keymap.set("n", ";", ":")
vim.keymap.set("n", ":", ";")
vim.keymap.set("v", ";", ":")
vim.keymap.set("v", ":", ";")

-- Insert mode cursor movement
vim.keymap.set("i", "<C-l>", "<Right>", { silent = true })
vim.keymap.set("i", "<C-h>", "<Left>", { silent = true })
vim.keymap.set("i", "<C-j>", "<Down>", { silent = true })
vim.keymap.set("i", "<C-k>", "<Up>", { silent = true })
vim.keymap.set("i", "jj", "<Esc>", { silent = true })

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Yank registers (don't overwrite register on x and p)
vim.keymap.set("n", "x", '"_x')
vim.keymap.set("v", "x", '"_x')
vim.keymap.set("v", "p", '"_dP')

-- Persistent undo
vim.opt.undodir = { "./.vimundo", vim.fn.expand("~/.vimundo") }
vim.api.nvim_create_autocmd("BufReadPre", {
  pattern = vim.fn.expand("~") .. "/*",
  callback = function()
    vim.opt_local.undofile = true
  end,
})

-- Check time on focus
vim.api.nvim_create_autocmd({ "InsertEnter", "WinEnter" }, {
  callback = function()
    vim.cmd("checktime")
  end,
})

-- Toggle quickfix
vim.keymap.set("n", "<leader>q", function()
  local nr = vim.fn.winnr("$")
  vim.cmd("cwindow")
  if vim.fn.winnr("$") == nr then
    vim.cmd("cclose")
  end
end, { silent = true })

-- Function expand/compact
local function expand_function_params()
  local save_cursor = vim.fn.getpos(".")
  vim.cmd("normal! [(")
  local start_line = vim.fn.line(".")
  vim.cmd("normal! %")
  local end_line = vim.fn.line(".")
  pcall(vim.cmd, start_line .. "," .. end_line .. [[s/\(\w\+\.\w\+\)(\([^)]*\))/\1(\r    \2\r)/g]])
  pcall(vim.cmd, start_line .. "," .. end_line .. [[s/,\s*/,\r    /g]])
  vim.fn.setpos(".", save_cursor)
end

local function compact_function_params()
  local save_cursor = vim.fn.getpos(".")
  vim.cmd("normal! [(")
  local start_line = vim.fn.line(".")
  vim.cmd("normal! %")
  local end_line = vim.fn.line(".")
  pcall(vim.cmd, start_line .. "," .. end_line .. [[s/\(\w\+\.\w\+\)(\_s*\([^)]*\)\_s*)/\1(\2)/g]])
  pcall(vim.cmd, start_line .. "," .. end_line .. [[s/,\_s*/,/g]])
  pcall(vim.cmd, start_line .. "," .. end_line .. [[s/,/, /g]])
  pcall(vim.cmd, start_line .. "," .. end_line .. [[s/=\s*/=/g]])
  pcall(vim.cmd, start_line .. "," .. end_line .. [[s/\s*=/=/g]])
  vim.fn.setpos(".", save_cursor)
end

vim.keymap.set("n", "<leader>ef", function()
  local line = vim.fn.getline(".")
  if line:match("%w+%.%w+%(") and not line:match(",\n") then
    expand_function_params()
  else
    compact_function_params()
  end
end)

-- Fix trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    local pos = vim.fn.getpos(".")
    pcall(vim.cmd, [[%s/\\\@<!\s\+$//]])
    vim.fn.setpos(".", pos)
  end,
})

vim.g.fortran_free_source = 0
vim.opt.autochdir = true

-- StatusLine: hide statusline
vim.opt.laststatus = 0
vim.opt.statusline = "%{repeat('─',winwidth('.'))}"

-- Code block background highlight for markdown/typst
local code_block_ns = vim.api.nvim_create_namespace("code_block_bg")

local function setup_codeblock_hl()
  vim.api.nvim_set_hl(0, "CodeBlockBg", { bg = "#c7c7c7" })
end

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  callback = setup_codeblock_hl,
})
setup_codeblock_hl()

local function highlight_code_blocks()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  if ft ~= "markdown" and ft ~= "typst" then return end

  vim.api.nvim_buf_clear_namespace(bufnr, code_block_ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local in_block = false

  for i, line in ipairs(lines) do
    if line:match("^```") then
      in_block = not in_block
      vim.api.nvim_buf_set_extmark(bufnr, code_block_ns, i - 1, 0, {
        end_row = i - 1,
        end_col = #line,
        hl_group = "CodeBlockBg",
        hl_eol = true,
      })
    elseif in_block then
      vim.api.nvim_buf_set_extmark(bufnr, code_block_ns, i - 1, 0, {
        end_row = i - 1,
        end_col = #line,
        hl_group = "CodeBlockBg",
        hl_eol = true,
      })
    end
  end
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "TextChangedI" }, {
  pattern = { "*.md", "*.typ" },
  callback = highlight_code_blocks,
})

-- StatusLine: sync background with Normal to hide statusline
local function setup_statusline_hl()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  local bg = normal.bg
  if bg then
    vim.api.nvim_set_hl(0, "StatusLine", { bg = bg })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = bg })
  else
    vim.api.nvim_set_hl(0, "StatusLine", { link = "Normal" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { link = "Normal" })
  end
end

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
  callback = setup_statusline_hl,
})

-- Put a mark before search
vim.keymap.set("n", "<leader>s", "mS:%s/", { desc = "Put a mark before search" })
vim.keymap.set("v", "<leader>s", "mS:'<,'>s/", { desc = "Put a mark before search" })
vim.keymap.set("n", "n", "mNn")

-- View options (don't save options and folds)
vim.opt.viewoptions:remove("options")
vim.opt.viewoptions:remove("folds")

-- Auto save/load view
local view_group = vim.api.nvim_create_augroup("AutoView", { clear = true })

vim.api.nvim_create_autocmd("BufWritePost", {
  group = view_group,
  pattern = "*",
  callback = function()
    if vim.fn.expand("%") ~= "" and vim.bo.buftype ~= "nofile" then
      vim.cmd("mkview")
    end
  end,
})

vim.api.nvim_create_autocmd("BufRead", {
  group = view_group,
  pattern = "*",
  callback = function()
    if vim.fn.expand("%") ~= "" and vim.bo.buftype ~= "nofile" then
      vim.cmd("silent! loadview")
    end
  end,
})

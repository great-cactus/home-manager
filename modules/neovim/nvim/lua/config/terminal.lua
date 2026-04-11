local M = {}

local terminal_buf = nil
local terminal_win = nil
local terminal_job = nil

function M.get_terminal_state()
  if not terminal_win or not vim.api.nvim_win_is_valid(terminal_win) then
    return 'closed'
  end

  local config = vim.api.nvim_win_get_config(terminal_win)
  local height = vim.o.lines
  local split_height = math.floor(height / 4)

  if config.relative == '' and config.height <= split_height then
    return 'split'
  else
    return 'popup'
  end
end

function M.toggle_terminal()
  local state = M.get_terminal_state()

  if state == 'split' then
    vim.api.nvim_win_hide(terminal_win)
    terminal_win = nil
  elseif state == 'popup' then
    vim.api.nvim_win_hide(terminal_win)
    terminal_win = nil
    M.open_terminal_split()
  else
    M.open_terminal_split()
  end
end

function M.toggle_terminal_popup()
  local state = M.get_terminal_state()

  if state == 'popup' then
    vim.api.nvim_win_hide(terminal_win)
    terminal_win = nil
  elseif state == 'split' then
    vim.api.nvim_win_hide(terminal_win)
    terminal_win = nil
    M.open_terminal_popup()
  else
    if not terminal_buf or not vim.api.nvim_buf_is_valid(terminal_buf) then
      M.create_terminal_buffer()
    end
    M.open_terminal_popup()
  end
end

function M.create_terminal_buffer()
  terminal_buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = terminal_buf })
  vim.api.nvim_set_option_value('filetype', 'terminal', { buf = terminal_buf })
end

function M.start_terminal()
  terminal_job = vim.fn.termopen(vim.o.shell, {
    on_exit = function()
      terminal_job = nil
    end
  })
end

function M.open_terminal_split()
  local height = vim.o.lines
  local split_height = math.floor(height / 4)

  if not terminal_buf or not vim.api.nvim_buf_is_valid(terminal_buf) then
    M.create_terminal_buffer()
  end

  vim.cmd('belowright ' .. split_height .. 'split')
  terminal_win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_buf(terminal_buf)

  if not terminal_job then
    M.start_terminal()
  end

  vim.cmd('startinsert')
end

function M.open_terminal_popup()
  local width = vim.o.columns
  local height = vim.o.lines
  local popup_width = math.floor(width * 0.75)
  local popup_height = math.floor(height * 0.75)
  local col = math.floor((width - popup_width) / 2)
  local row = math.floor((height - popup_height) / 2)

  terminal_win = vim.api.nvim_open_win(terminal_buf, true, {
    relative = 'editor',
    width = popup_width,
    height = popup_height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'single'
  })

  if not terminal_job then
    M.start_terminal()
  end

  vim.cmd('startinsert')
end

function M.open_terminal_tab()
  if not terminal_buf or not vim.api.nvim_buf_is_valid(terminal_buf) then
    M.create_terminal_buffer()
  end

  vim.cmd('tabnew')
  vim.api.nvim_set_current_buf(terminal_buf)

  if not terminal_job then
    M.start_terminal()
  end

  vim.cmd('startinsert')
end

vim.api.nvim_set_keymap('n', 'tt', '<cmd>lua require("config.terminal").open_terminal_tab()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'tx', '<cmd>lua require("config.terminal").toggle_terminal()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'tp', '<cmd>lua require("config.terminal").toggle_terminal_popup()<CR>', { noremap = true, silent = true })

-- ターミナル設定
vim.api.nvim_create_autocmd('TermOpen', {
  pattern = '*',
  callback = function()
    vim.cmd('startinsert')
    vim.opt_local.relativenumber = false
    vim.opt_local.number = false

    -- ターミナルバッファ専用のキーマップ（normal modeでqを押すと閉じる）
    vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':q<CR>', { noremap = true, silent = true })
  end
})

-- ターミナルウィンドウのstatusline制御
vim.api.nvim_create_autocmd({'WinEnter', 'BufWinEnter'}, {
  pattern = '*',
  callback = function()
    if vim.bo.buftype == 'terminal' then
      vim.opt.laststatus = 0
    end
  end
})

vim.api.nvim_create_autocmd({'WinLeave', 'BufWinLeave'}, {
  pattern = '*',
  callback = function()
    if vim.bo.buftype == 'terminal' then
      -- TODO: init.vimのlaststatusを引き継ぐようにする
      vim.opt.laststatus = 0
    end
  end
})

vim.api.nvim_set_keymap('t', '<Esc>', '<C-\\><C-n>', { noremap = true, silent = true })

return M

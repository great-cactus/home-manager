local M = {}

local claude_buf = nil
local claude_win = nil
local claude_job = nil
local input_buf = nil
local input_win = nil

function M.get_claude_state()
  if not claude_win or not vim.api.nvim_win_is_valid(claude_win) then
    return 'closed'
  end

  local config = vim.api.nvim_win_get_config(claude_win)
  local width = vim.o.columns
  local term_width = math.floor(width / 4)

  if config.width == term_width and config.col == width - term_width then
    return 'terminal'
  else
    return 'popup'
  end
end

function M.toggle_claude()
  local state = M.get_claude_state()

  if state == 'terminal' then
    vim.api.nvim_win_hide(claude_win)
    claude_win = nil
  elseif state == 'popup' then
    vim.api.nvim_win_hide(claude_win)
    claude_win = nil
    M.open_claude_terminal()
  else
    M.open_claude_terminal()
  end
end

function M.create_claude_buffer()
  claude_buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = claude_buf })
  vim.api.nvim_set_option_value('filetype', 'claude', { buf = claude_buf })
end

function M.start_claude_terminal()
  -- Start Claude Code terminal in the current buffer
  claude_job = vim.fn.termopen('claude', {
    on_exit = function()
      claude_job = nil
    end
  })
end

function M.open_claude_terminal()
  local width = vim.o.columns
  local height = vim.o.lines
  local term_width = math.floor(width / 4)

  if not claude_buf or not vim.api.nvim_buf_is_valid(claude_buf) then
    M.create_claude_buffer()
  end

  claude_win = vim.api.nvim_open_win(claude_buf, true, {
    relative = 'editor',
    width = term_width,
    height = height - 2,
    col = width - term_width,
    row = 0,
    style = 'minimal',
    border = 'single'
  })

  -- Start Claude Code terminal after opening the window
  if not claude_job then
    M.start_claude_terminal()
  end

  -- Start in insert mode for terminal interaction
  vim.cmd('startinsert')

  -- Auto-open input window after a brief delay
  vim.defer_fn(function()
    M.open_input_window()
  end, 100)
end

function M.toggle_claude_popup()
  local state = M.get_claude_state()

  if state == 'popup' then
    vim.api.nvim_win_hide(claude_win)
    claude_win = nil
  elseif state == 'terminal' then
    vim.api.nvim_win_hide(claude_win)
    claude_win = nil
    M.open_claude_popup()
  else
    if not claude_buf or not vim.api.nvim_buf_is_valid(claude_buf) then
      M.create_claude_buffer()
    end
    M.open_claude_popup()
  end
end

function M.open_claude_popup()
  local width = vim.o.columns
  local height = vim.o.lines
  local popup_width = math.floor(width * 0.75)
  local popup_height = math.floor(height * 0.75)
  local col = math.floor((width - popup_width) / 2)
  local row = math.floor((height - popup_height) / 2)

  claude_win = vim.api.nvim_open_win(claude_buf, true, {
    relative = 'editor',
    width = popup_width,
    height = popup_height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'single'
  })

  -- Start Claude Code terminal after opening the window
  if not claude_job then
    M.start_claude_terminal()
  end

  -- Start in insert mode for terminal interaction
  vim.cmd('startinsert')

  -- Auto-open input window after a brief delay
  vim.defer_fn(function()
    M.open_input_window()
  end, 100)
end

function M.create_input_buffer()
  input_buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = input_buf })
  vim.api.nvim_set_option_value('filetype', 'text', { buf = input_buf })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = input_buf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = input_buf })
end

function M.open_input_window()
  -- Only show input window if Claude terminal is open
  if not claude_win or not vim.api.nvim_win_is_valid(claude_win) then
    return
  end

  -- Don't open if already open
  if input_win and vim.api.nvim_win_is_valid(input_win) then
    return
  end

  local width = vim.o.columns
  local height = vim.o.lines
  local input_width = math.floor(width * 0.6)
  local input_height = 3
  local col = math.floor((width - input_width) / 2)
  local row = math.floor((height - input_height) / 2)

  if not input_buf or not vim.api.nvim_buf_is_valid(input_buf) then
    M.create_input_buffer()
  end

  input_win = vim.api.nvim_open_win(input_buf, true, {
    relative = 'editor',
    width = input_width,
    height = input_height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'single',
    title = ' Claude Input ',
    title_pos = 'center'
  })

  -- Set up buffer for input
  vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, {})

  -- Key mappings for input window (buffer-local)
  local opts = { noremap = true, silent = true, buffer = input_buf }
  vim.keymap.set('n', '<Esc>', function() M.close_input_window() end, opts)
  vim.keymap.set('i', '<C-c>', function() M.close_input_window() end, opts)
  vim.keymap.set('n', '<CR>', function() M.send_input() end, opts)
  vim.keymap.set('i', '<C-l>', function() M.send_input() end, opts)

  -- Make window more stable against external events
  vim.api.nvim_set_option_value('modified', false, { buf = input_buf })
  vim.api.nvim_set_option_value('modifiable', true, { buf = input_buf })

  -- Start in insert mode
  vim.cmd('startinsert')
end

function M.close_input_window()
  if input_win and vim.api.nvim_win_is_valid(input_win) then
    vim.api.nvim_win_close(input_win, true)
    input_win = nil
  end
end

function M.send_input()
  if not input_buf or not vim.api.nvim_buf_is_valid(input_buf) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
  local text = table.concat(lines, '\n')

  if text ~= '' then
    -- Send text to Claude terminal without newline
    if claude_job then
      vim.fn.chansend(claude_job, text)
    end
  end

  -- Close input window
  M.close_input_window()

  -- Focus back to Claude terminal and simulate Enter key press
  if claude_win and vim.api.nvim_win_is_valid(claude_win) then
    vim.api.nvim_set_current_win(claude_win)
    vim.cmd('startinsert')
    -- Simulate Enter key press in terminal
    vim.defer_fn(function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'n', false)
    end, 50)
  end
end

function M.send_escape_to_claude()
  if claude_job then
    vim.fn.chansend(claude_job, '\x1b')
  end
end

vim.api.nvim_set_keymap('n', '<Leader>cl', '<cmd>lua require("config.claude").toggle_claude()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>clp', '<cmd>lua require("config.claude").toggle_claude_popup()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>cli', '<cmd>lua require("config.claude").open_input_window()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>cls', '<cmd>lua require("config.claude").send_escape_to_claude()<CR>', { noremap = true, silent = true })

-- Terminal mode escape key mapping (consistent with init.vim)
vim.api.nvim_set_keymap('t', '<Esc>', '<C-\\><C-n>', { noremap = true, silent = true })

-- Auto-configure Claude terminal buffers (clean implementation)
vim.api.nvim_create_autocmd('TermOpen', {
  pattern = '*',
  callback = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    if buf_name:match('claude') then
      vim.cmd('setlocal norelativenumber')
      vim.cmd('setlocal nonumber')
      vim.cmd('startinsert')
    end
  end
})


return M

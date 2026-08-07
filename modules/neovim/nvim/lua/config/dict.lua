-- dict.lua: English dictionary lookup using WordNet (wn command)
-- Commands: :DictFloat, :DictHoriz, :DictVert

local M = {}

local function get_cword()
  local word = vim.fn.expand('<cword>')
  if word == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return nil
  end
  return word
end

local function lookup(word, callback)
  local wn = vim.fn.exepath('wn')
  if wn == '' then
    vim.notify('wn command not found', vim.log.levels.ERROR)
    return
  end
  vim.system({ wn, word, '-over' }, { text = true }, function(obj)
    vim.schedule(function()
      if obj.stdout == '' then
        vim.notify('No definition found for: ' .. word, vim.log.levels.WARN)
        return
      end
      local lines = vim.split(obj.stdout, '\n', { trimempty = true })
      callback(lines, word)
    end)
  end)
end

local function set_buf_options(buf, word)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'dict'
  vim.api.nvim_buf_set_name(buf, 'dict://' .. word)
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<Cmd>close<CR>', { nowait = true })
end

local function open_float(lines, word)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  set_buf_options(buf, word)
  vim.bo[buf].modifiable = false

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.api.nvim_strwidth(line))
  end

  local max_width = math.floor(vim.o.columns * 0.8)
  local max_height = math.floor(vim.o.lines * 0.8)
  width = math.min(width + 2, max_width)
  local height = math.min(#lines, max_height)

  vim.api.nvim_open_win(buf, true, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. word .. ' ',
    title_pos = 'center',
  })
end

local function open_split(cmd, lines, word)
  vim.cmd(cmd)
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  set_buf_options(buf, word)
  vim.bo[buf].modifiable = false

  local max = math.min(#lines, math.floor(vim.o.lines * 0.4))
  if cmd:match('^new') or cmd:match('^split') then
    vim.api.nvim_win_set_height(0, max)
  end
end

function M.setup()
  vim.api.nvim_create_user_command('DictFloat', function()
    local word = get_cword()
    if word then lookup(word, open_float) end
  end, {})

  vim.api.nvim_create_user_command('DictHoriz', function()
    local word = get_cword()
    if word then lookup(word, function(lines, w) open_split('new', lines, w) end) end
  end, {})

  vim.api.nvim_create_user_command('DictVert', function()
    local word = get_cword()
    if word then lookup(word, function(lines, w) open_split('vnew', lines, w) end) end
  end, {})
end

return M

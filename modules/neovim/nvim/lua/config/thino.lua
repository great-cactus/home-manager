local M = {}

M.config = {
  keymap = '<Leader>ot',
}

local function get_paths()
  local obsidian = vim.fn.expand("$OBSIDIAN_PATH")
  local today = os.date("%Y-%m-%d")
  return {
    daily = obsidian .. "/Output/DailyNotes/" .. today .. ".md",
    template = obsidian .. "/Templates/DailyNotes.md",
  }
end

local function read_file(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*a")
  file:close()
  return content
end

local function write_file(path, content)
  local file = io.open(path, "w")
  if not file then return false end
  file:write(content)
  file:close()
  return true
end

local function create_daily_note()
  local paths = get_paths()
  local template = read_file(paths.template)
  if not template then
    vim.notify("Failed to read template", vim.log.levels.ERROR)
    return false
  end

  local content = template
    :gsub("{{date:YYYYMMDDHHmm}}", os.date("%Y%m%d%H%M"))
    :gsub("{{date:YYYY/MM/DDH}}", os.date("%Y/%m/%d"))

  if not write_file(paths.daily, content) then
    vim.notify("Failed to create daily note", vim.log.levels.ERROR)
    return false
  end

  vim.notify("Daily note created", vim.log.levels.INFO)
  return true
end

local function append_to_daily_note(input)
  local paths = get_paths()

  if vim.fn.filereadable(paths.daily) == 0 then
    if not create_daily_note() then return end
  end

  local content = read_file(paths.daily) or ""
  local trimmed = content:gsub("%s+$", "")
  local entry = string.format("- %s %s", os.date("%H:%M:%S"), input)
  local new_content = trimmed .. "\n" .. entry .. "\n"

  if write_file(paths.daily, new_content) then
    vim.notify("Thino: " .. input, vim.log.levels.INFO)
  else
    vim.notify("Failed to write to daily note", vim.log.levels.ERROR)
  end
end

local function create_thino_entry()
  local width, height = 60, 1
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = 'minimal',
    border = 'rounded',
    title = ' Thino ',
    title_pos = 'center',
  })

  vim.cmd('startinsert')

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.cmd('stopinsert')
  end

  vim.keymap.set('i', '<CR>', function()
    local input = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    close()
    if input and input ~= "" then
      append_to_daily_note(input)
    end
  end, { buffer = buf })

  vim.keymap.set({ 'i', 'n' }, '<Esc>', close, { buffer = buf })
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  vim.keymap.set('n', M.config.keymap, create_thino_entry, {
    desc = 'Create Thino entry',
  })
end

return M

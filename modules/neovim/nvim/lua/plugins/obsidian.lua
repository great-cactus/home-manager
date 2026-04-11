vim.opt_local.conceallevel = 2
require("obsidian").setup{
  notes_subdir = "Output",
  log_level = vim.log.levels.INFO,
  frontmatter = { enabled = false },
  legacy_commands = false,

  workspaces = {
    {
      name = "Obsidian_Vault",
      path = vim.fn.expand("$OBSIDIAN_PATH")
    },
  },
  daily_notes = {
    folder      = "Output/DailyNotes",
    date_format = "%Y-%m-%d",
    template    = "DailyNote.md",
  },
  templates = {
    folder = "Templates",
    substitutions = {
      yesterday = function()
        return os.date("%Y-%m-%d", os.time() - 86400)
      end,
      tomorrow = function()
        return os.date("%Y-%m-%d", os.time() + 86400)
      end,
    },
  },
  attachments = {
    folder = './Attachments',
  },
  picker = {
    name = 'fzf-lua',
    new = "<C-x>",
    insert_link = "<C-l>",
  },
  completion = {
    nvim_cmp = false,
    min_chars = 2,
  },
  footer = {
    enabled = false, -- turn it off
    separator = false, -- turn it off
    -- separator = "", -- insert a blank line
    format = "{{backlinks}} backlinks  {{properties}} properties  {{words}} words  {{chars}} chars", -- works like the template system
    hl_group = "@property", -- Use another hl group
  }
}

-- Create permanent note function
local function create_permanent_note()
  local title = vim.fn.input("Enter title of Permanent note: ")
  if title == "" then
    return
  end

  local obsidian_path = vim.fn.expand("$OBSIDIAN_PATH")
  local file_path = obsidian_path .. "/Output/" .. title .. ".md"

  -- Check if file already exists
  if vim.fn.filereadable(file_path) == 1 then
    vim.notify("⚠️Error: Output/" .. title .. ".md already exists.", vim.log.levels.WARN)
    return
  end

  -- Generate metadata
  local today_id = os.date("%Y%m%d%H%M")
  local today_created = os.date("%Y-%m-%d %H:%M")
  local today_tag = os.date("%Y/%m/%d")

  local content = string.format([[---
ID: %s
created: %s
title: %s
aliases: []
tags: [ %s, PERMANENT ]
---
]], today_id, today_created, title, today_tag
  )

    -- Create file
  local file = io.open(file_path, "w")
  if file then
    file:write(content)
    file:close()

    -- Open the created file
    vim.cmd("edit " .. file_path)
    vim.notify("Created permanent note: " .. title, vim.log.levels.INFO)
  else
    vim.notify("Failed to create file: " .. file_path, vim.log.levels.ERROR)
  end
end

-- Create literature note function
local function create_literature_note()
  local current_buf = vim.api.nvim_get_current_buf()
  local current_file_path = vim.api.nvim_buf_get_name(current_buf)

  -- Check if there's an active file
  if current_file_path == "" then
    vim.notify("No active file found.", vim.log.levels.ERROR)
    return
  end

  -- Get the basename of the current file (without extension)
  local file_title = vim.fn.fnamemodify(current_file_path, ":t:r")

  local title = vim.fn.input("Enter title of Literature note: ")
  if title == "" then
    vim.notify("⚠️Error: No title is available.", vim.log.levels.WARN)
    return
  end

  local obsidian_path = vim.fn.expand("$OBSIDIAN_PATH")
  local file_path = obsidian_path .. "/Output/" .. file_title .. "-" .. title .. ".md"

  -- Check if file already exists
  if vim.fn.filereadable(file_path) == 1 then
    vim.notify("⚠️Error: Output/" .. file_title .. "-" .. title .. ".md already exists.", vim.log.levels.WARN)
    return
  end

  -- Generate metadata
  local today_id = os.date("%Y%m%d%H%M")
  local today_created = os.date("%Y-%m-%d %H:%M")
  local today_tag = os.date("%Y/%m/%d")

  -- Get relative path for the link
  local relative_path = vim.fn.fnamemodify(current_file_path, ":~:.")
  if vim.startswith(relative_path, obsidian_path) then
    relative_path = string.sub(relative_path, string.len(obsidian_path) + 2) -- Remove obsidian_path + "/"
  end
  local active_file_link = "[[" .. relative_path .. "]]"

  local content = string.format([[---
ID: %s
created: %s
title: %s
aliases: []
tags: [ %s, LITERATURE ]
---
%s

]], today_id, today_created, title, today_tag, active_file_link)

  -- Create file
  local file = io.open(file_path, "w")
  if file then
    file:write(content)
    file:close()

    -- Open the created file
    vim.cmd("edit " .. file_path)
    vim.notify("Created literature note: " .. file_title .. "-" .. title, vim.log.levels.INFO)
  else
    vim.notify("Failed to create file: " .. file_path, vim.log.levels.ERROR)
  end
end

-- Set keymap for <leader>op
vim.keymap.set('n', '<leader>op', create_permanent_note, { desc = 'Create Obsidian Permanent Note' })
-- Set keymap for <leader>ol
vim.keymap.set('n', '<leader>ol', create_literature_note, { desc = 'Create Obsidian Literature Note' })

-- Append entry to daily note
local function append_to_daily_note(input)
  local obsidian_path = vim.fn.expand("$OBSIDIAN_PATH")
  local today = os.date("%Y-%m-%d")
  local time = os.date("%H:%M:%S")
  local daily_note_path = obsidian_path .. "/Output/DailyNotes/" .. today .. ".md"

  -- Create daily note if it doesn't exist
  if vim.fn.filereadable(daily_note_path) == 0 then
    vim.cmd("ObsidianToday")
    vim.cmd("write")
    vim.cmd("bdelete")
  end

  -- Read existing content
  local entry = "- " .. time .. " " .. input
  local lines = {}
  local file = io.open(daily_note_path, "r")
  if file then
    for line in file:lines() do
      lines[#lines + 1] = line
    end
    file:close()
  end

  -- Remove trailing empty lines
  while #lines > 0 and lines[#lines]:match("^%s*$") do
    table.remove(lines)
  end

  lines[#lines + 1] = entry

  -- Write back
  file = io.open(daily_note_path, "w")
  if file then
    file:write(table.concat(lines, "\n") .. "\n")
    file:close()
    vim.notify("Thino: " .. input, vim.log.levels.INFO)
  else
    vim.notify("Failed to write to daily note", vim.log.levels.ERROR)
  end
end

-- Create Thino entry with floating window
local function create_thino_entry()
  local width = 60
  local height = 1
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

  vim.keymap.set('i', '<CR>', function()
    local input = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    vim.api.nvim_win_close(win, true)
    vim.cmd('stopinsert')
    if input and input ~= "" then
      append_to_daily_note(input)
    end
  end, { buffer = buf })

  vim.keymap.set('i', '<Esc>', function()
    vim.api.nvim_win_close(win, true)
    vim.cmd('stopinsert')
  end, { buffer = buf })
end

-- Open today's daily note in a new tab
local function open_daily_note()
  local obsidian_path = vim.fn.expand("$OBSIDIAN_PATH")
  local today = os.date("%Y-%m-%d")
  local daily_note_path = obsidian_path .. "/Output/DailyNotes/" .. today .. ".md"

  if vim.fn.filereadable(daily_note_path) == 0 then
    vim.cmd("ObsidianToday")
    vim.cmd("write")
    vim.cmd("bdelete")
  end

  vim.cmd("tabedit " .. vim.fn.fnameescape(daily_note_path))
end

vim.keymap.set('n', '<leader>od', open_daily_note, { desc = 'Open Obsidian Daily Note in new tab' })

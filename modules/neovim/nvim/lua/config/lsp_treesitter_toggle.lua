-- LSP and Tree-sitter Toggle Plugin
local M = {}

-- State management
local state = {
  popup_buf = nil,
  popup_win = nil,
  items = {},
  current_line = 1,
}

-- Get list of LSP clients attached to current buffer
local function get_lsp_clients()
  local clients = {}
  local buf_clients = vim.lsp.get_active_clients({ bufnr = 0 })

  for _, client in ipairs(buf_clients) do
    table.insert(clients, {
      type = "lsp",
      name = client.name,
      id = client.id,
    })
  end

  return clients
end

-- Get list of installed Tree-sitter parsers
local function get_treesitter_parsers()
  local parsers = {}
  local ok, ts_parsers = pcall(require, "nvim-treesitter.parsers")

  if not ok then
    return parsers
  end

  local installed = ts_parsers.get_parser_configs()

  for parser_name, _ in pairs(installed) do
    if ts_parsers.has_parser(parser_name) then
      table.insert(parsers, {
        type = "treesitter",
        name = parser_name,
      })
    end
  end

  table.sort(parsers, function(a, b)
    return a.name < b.name
  end)

  return parsers
end

-- Get status of LSP or Tree-sitter item
local function get_status(item)
  if item.type == "lsp" then
    local clients = vim.lsp.get_active_clients({ bufnr = 0 })
    for _, client in ipairs(clients) do
      if client.id == item.id then
        return true
      end
    end
    return false
  elseif item.type == "treesitter" then
    -- Check if highlighting is enabled for current buffer
    local ok_hl, ts_highlight = pcall(require, "vim.treesitter.highlighter")
    if ok_hl and ts_highlight.active then
      return ts_highlight.active[vim.api.nvim_get_current_buf()] ~= nil
    end

    return false
  end

  return false
end

-- Toggle LSP client
local function toggle_lsp(item)
  if get_status(item) then
    -- Stop LSP client
    vim.lsp.stop_client(item.id)
    vim.notify("Stopped LSP: " .. item.name, vim.log.levels.INFO)
  else
    -- Restart LSP client
    vim.cmd("LspStart " .. item.name)
    vim.notify("Started LSP: " .. item.name, vim.log.levels.INFO)
  end
end

-- Toggle Tree-sitter parser
local function toggle_treesitter(item)
  local ok, ts_config = pcall(require, "nvim-treesitter.configs")
  if not ok then
    vim.notify("Tree-sitter not available", vim.log.levels.ERROR)
    return
  end

  if get_status(item) then
    -- Disable Tree-sitter highlighting
    vim.cmd("TSBufDisable highlight")
    vim.notify("Disabled Tree-sitter: " .. item.name, vim.log.levels.INFO)
  else
    -- Enable Tree-sitter highlighting
    vim.cmd("TSBufEnable highlight")
    vim.notify("Enabled Tree-sitter: " .. item.name, vim.log.levels.INFO)
  end
end

-- Create popup content
local function create_popup_content()
  state.items = {}
  local lines = {}

  -- Add LSP section
  table.insert(lines, "=== LSP Servers ===")
  table.insert(state.items, { type = "header" })

  local lsp_clients = get_lsp_clients()
  if #lsp_clients == 0 then
    table.insert(lines, "  (no LSP clients attached)")
    table.insert(state.items, { type = "empty" })
  else
    for _, client in ipairs(lsp_clients) do
      local status = get_status(client)
      local checkbox = status and "[x]" or "[ ]"
      table.insert(lines, "  " .. checkbox .. " " .. client.name)
      table.insert(state.items, client)
    end
  end

  -- Add empty line
  table.insert(lines, "")
  table.insert(state.items, { type = "separator" })

  -- Add Tree-sitter section
  table.insert(lines, "=== Tree-sitter Parsers ===")
  table.insert(state.items, { type = "header" })

  local ts_parsers = get_treesitter_parsers()
  if #ts_parsers == 0 then
    table.insert(lines, "  (no parsers installed)")
    table.insert(state.items, { type = "empty" })
  else
    for _, parser in ipairs(ts_parsers) do
      local status = get_status(parser)
      local checkbox = status and "[x]" or "[ ]"
      table.insert(lines, "  " .. checkbox .. " " .. parser.name)
      table.insert(state.items, parser)
    end
  end

  return lines
end

-- Update popup content
local function update_popup()
  if not state.popup_buf or not vim.api.nvim_buf_is_valid(state.popup_buf) then
    return
  end

  local lines = create_popup_content()
  vim.api.nvim_buf_set_option(state.popup_buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(state.popup_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.popup_buf, "modifiable", false)
end

-- Handle toggle action
local function handle_toggle()
  local line = vim.api.nvim_win_get_cursor(state.popup_win)[1]
  local item = state.items[line]

  if not item or item.type == "header" or item.type == "separator" or item.type == "empty" then
    return
  end

  if item.type == "lsp" then
    toggle_lsp(item)
  elseif item.type == "treesitter" then
    toggle_treesitter(item)
  end

  -- Update popup content
  vim.defer_fn(function()
    update_popup()
  end, 100)
end

-- Close popup
local function close_popup()
  if state.popup_win and vim.api.nvim_win_is_valid(state.popup_win) then
    vim.api.nvim_win_close(state.popup_win, true)
  end

  state.popup_buf = nil
  state.popup_win = nil
  state.items = {}
  state.current_line = 1
end

-- Open toggle popup
local function open_toggle_popup()
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  state.popup_buf = buf

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "lsp-treesitter-toggle")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Get popup dimensions
  local lines = create_popup_content()
  local width = 50
  local height = #lines

  -- Calculate popup position (center of screen)
  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height
  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " LSP & Tree-sitter Toggle ",
    title_pos = "center",
  })
  state.popup_win = win

  -- Set window options
  vim.api.nvim_win_set_option(win, "cursorline", true)

  -- Set buffer content
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Set cursor to first toggleable item
  for i, item in ipairs(state.items) do
    if item.type == "lsp" or item.type == "treesitter" then
      vim.api.nvim_win_set_cursor(win, { i, 0 })
      break
    end
  end

  -- Set keymaps
  local opts = { noremap = true, silent = true, buffer = buf }

  -- Navigation
  vim.keymap.set("n", "j", function()
    local current = vim.api.nvim_win_get_cursor(state.popup_win)[1]
    local next = current + 1
    while next <= #state.items do
      local item = state.items[next]
      if item.type == "lsp" or item.type == "treesitter" then
        vim.api.nvim_win_set_cursor(state.popup_win, { next, 0 })
        break
      end
      next = next + 1
    end
  end, opts)

  vim.keymap.set("n", "k", function()
    local current = vim.api.nvim_win_get_cursor(state.popup_win)[1]
    local prev = current - 1
    while prev >= 1 do
      local item = state.items[prev]
      if item.type == "lsp" or item.type == "treesitter" then
        vim.api.nvim_win_set_cursor(state.popup_win, { prev, 0 })
        break
      end
      prev = prev - 1
    end
  end, opts)

  vim.keymap.set("n", "<Down>", function()
    local current = vim.api.nvim_win_get_cursor(state.popup_win)[1]
    local next = current + 1
    while next <= #state.items do
      local item = state.items[next]
      if item.type == "lsp" or item.type == "treesitter" then
        vim.api.nvim_win_set_cursor(state.popup_win, { next, 0 })
        break
      end
      next = next + 1
    end
  end, opts)

  vim.keymap.set("n", "<Up>", function()
    local current = vim.api.nvim_win_get_cursor(state.popup_win)[1]
    local prev = current - 1
    while prev >= 1 do
      local item = state.items[prev]
      if item.type == "lsp" or item.type == "treesitter" then
        vim.api.nvim_win_set_cursor(state.popup_win, { prev, 0 })
        break
      end
      prev = prev - 1
    end
  end, opts)

  -- Toggle action
  vim.keymap.set("n", "<CR>", handle_toggle, opts)

  -- Close popup
  vim.keymap.set("n", "q", close_popup, opts)
  vim.keymap.set("n", "<Esc>", close_popup, opts)
end

-- Setup function
function M.setup(opts)
  opts = opts or {}
  local command_name = opts.command or "toggle"

  -- Register command
  vim.api.nvim_create_user_command(
    command_name:gsub("^%l", string.upper),
    open_toggle_popup,
    { desc = "Toggle LSP and Tree-sitter features" }
  )
end

-- Export main function
M.open = open_toggle_popup

return M

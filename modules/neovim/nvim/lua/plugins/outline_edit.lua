local submode = require('submode')

-- State ---------------------------------------------------------------

local ns = vim.api.nvim_create_namespace('outline_edit')
local hl_ns = vim.api.nvim_create_namespace('outline_edit_highlight')

local state = {
  mode = "unselected",
  selected_block = nil,
  target_position = nil,
  indent_delta = 0,
}

-- Utilities ------------------------------------------------------------

local function is_list_item(line)
  return line:match("^%s*[-*]%s") or line:match("^%s*%d+%.%s")
end

local function get_indent_level(line)
  return #(line:match("^%s*"))
end

local function apply_indent_to_line(line, delta)
  if delta > 0 then
    return string.rep(" ", delta) .. line
  elseif delta < 0 then
    local to_remove = math.min(-delta, get_indent_level(line))
    return line:sub(to_remove + 1)
  end
  return line
end

local function get_item_block_range(start_line)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  if not is_list_item(lines[start_line]) then return nil end

  local parent_indent = get_indent_level(lines[start_line])
  local end_line = start_line

  for i = start_line + 1, #lines do
    local line = lines[i]
    if not line:match("^%s*$") then
      if get_indent_level(line) <= parent_indent then break end
      end_line = i
    end
  end

  return {
    start_line = start_line,
    end_line = end_line,
    lines = vim.list_slice(lines, start_line, end_line),
  }
end

-- State management -----------------------------------------------------

local function reset_state()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  vim.api.nvim_buf_clear_namespace(bufnr, hl_ns, 0, -1)
  state.mode = "unselected"
  state.selected_block = nil
  state.target_position = nil
  state.indent_delta = 0
end

local function refresh_visuals()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  vim.api.nvim_buf_clear_namespace(bufnr, hl_ns, 0, -1)

  local block = state.selected_block
  if not block then return end

  for i = block.start_line, block.end_line do
    vim.api.nvim_buf_add_highlight(bufnr, hl_ns, 'Visual', i - 1, 0, -1)
  end

  if state.target_position then
    local adjusted = apply_indent_to_line(block.lines[1], state.indent_delta)
    vim.api.nvim_buf_set_extmark(bufnr, ns, state.target_position - 1, 0, {
      virt_lines = { { { adjusted, 'Comment' } } },
      virt_lines_above = false,
    })
  end
end

-- Operations -----------------------------------------------------------

local function select_current_item()
  local line_num = vim.fn.line(".")
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
  if not is_list_item(line) then
    vim.notify("Not a list item", vim.log.levels.WARN)
    return false
  end

  local block = get_item_block_range(line_num)
  if not block then return false end

  state.selected_block = block
  state.target_position = line_num
  state.indent_delta = 0
  refresh_visuals()
  return true
end

local function move_target(delta)
  if not state.selected_block then return end
  local new_pos = math.max(1, math.min(
    state.target_position + delta,
    vim.api.nvim_buf_line_count(0)
  ))
  state.target_position = new_pos
  refresh_visuals()
end

local function adjust_indent(delta)
  if not state.selected_block then return end
  state.indent_delta = state.indent_delta + delta
  refresh_visuals()
end

local function apply_move_and_exit()
  if not state.selected_block or not state.target_position then return end

  local bufnr = vim.api.nvim_get_current_buf()
  local block = state.selected_block

  local lines_to_move = vim.api.nvim_buf_get_lines(bufnr, block.start_line - 1, block.end_line, false)
  if state.indent_delta ~= 0 then
    for i, line in ipairs(lines_to_move) do
      lines_to_move[i] = apply_indent_to_line(line, state.indent_delta)
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, block.start_line - 1, block.end_line, false, {})

  local adjusted_target = state.target_position
  if state.target_position > block.start_line then
    adjusted_target = adjusted_target - (block.end_line - block.start_line + 1)
  end

  vim.api.nvim_buf_set_lines(bufnr, adjusted_target, adjusted_target, false, lines_to_move)
  vim.fn.cursor(adjusted_target + 1, 0)

  reset_state()
  submode.leave()
end

-- Submode definition ---------------------------------------------------

submode.create("OutlineEdit", {
  mode = "n",
  enter = "<Leader>o",
  leave = { "q" },
  default = function(register)
    register("j", function()
      if state.mode == "unselected" then vim.cmd("normal! j") else move_target(1) end
    end)
    register("k", function()
      if state.mode == "unselected" then vim.cmd("normal! k") else move_target(-1) end
    end)

    register("<CR>", function()
      if state.mode == "unselected" then
        if select_current_item() then state.mode = "selected" end
      else
        apply_move_and_exit()
      end
    end)

    register("h", function()
      if state.mode == "selected" then adjust_indent(-2) else vim.cmd("normal! h") end
    end)
    register("l", function()
      if state.mode == "selected" then adjust_indent(2) else vim.cmd("normal! l") end
    end)

    register("<Tab>", function()
      if state.mode == "selected" then
        adjust_indent(2)
      else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, false, true), 'n', false)
      end
    end)
    register("<S-Tab>", function()
      if state.mode == "selected" then adjust_indent(-2) end
    end)

    register("<ESC>", function()
      if state.mode == "selected" then
        reset_state()
      else
        submode.leave()
      end
    end)
  end,

  hook = {
    on_enter = function()
      reset_state()
      pcall(vim.keymap.del, 'n', '<CR>', { buffer = 0 })
      vim.notify("-- OUTLINE EDIT --", vim.log.levels.INFO)
    end,
    on_leave = function()
      reset_state()
    end,
  },
})

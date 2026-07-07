-- copilot.lua: inline completion (ghost text)
require('copilot').setup({
  suggestion = {
    enabled = true,
    auto_trigger = true,
    hide_during_completion = false,
    debounce = 75,
    keymap = {
      accept = '<C-g>',
      next = false,
      prev = false,
      dismiss = '<C-]>',
    },
  },
  panel = { enabled = false },
  filetypes = {
    gitcommit = true,
    markdown = true,
  },
})

-- Toggle commands
local inline_enabled = true
local nes_enabled = true

vim.api.nvim_create_user_command('CopilotInlineToggle', function()
  require('copilot.suggestion').toggle_auto_trigger()
  inline_enabled = not inline_enabled
  vim.notify('Copilot Inline: ' .. (inline_enabled and 'ON' or 'OFF'))
end, { desc = 'Toggle Copilot inline completion' })

vim.api.nvim_create_user_command('CopilotNESToggle', function()
  nes_enabled = not nes_enabled
  vim.notify('Copilot NES: ' .. (nes_enabled and 'ON' or 'OFF'))
end, { desc = 'Toggle Copilot NES' })

-- NES keymaps (normal mode)
vim.keymap.set('n', '<Tab>', function()
  if not nes_enabled then
    local key = vim.api.nvim_replace_termcodes('<C-i>', true, false, true)
    vim.api.nvim_feedkeys(key, 'n', false)
    return
  end
  local state = vim.b[vim.api.nvim_get_current_buf()].nes_state
  if state then
    local _ = require('copilot-lsp.nes').walk_cursor_start_edit()
      or (
        require('copilot-lsp.nes').apply_pending_nes()
        and require('copilot-lsp.nes').walk_cursor_end_edit()
      )
    return
  end
  local key = vim.api.nvim_replace_termcodes('<C-i>', true, false, true)
  vim.api.nvim_feedkeys(key, 'n', false)
end, { desc = 'Apply NES or fallback Tab' })

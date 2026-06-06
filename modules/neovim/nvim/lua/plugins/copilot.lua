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
  copilot_node_command = vim.fn.expand('~/.nodejs/bin/node'),
})

-- <leader>cp: toggle copilot inline completion
vim.keymap.set('n', '<leader>cp', function()
  require('copilot.suggestion').toggle_auto_trigger()
end, { desc = 'Toggle Copilot inline completion' })

-- NES keymaps (normal mode)
vim.keymap.set('n', '<Tab>', function()
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

vim.keymap.set('n', '<Esc>', function()
  if not require('copilot-lsp.nes').clear() then
    vim.cmd('nohlsearch')
  end
end, { desc = 'Clear NES or nohlsearch', silent = true })

-- Copilot: inline ghost text (copilot.lua) and NES next edit suggestion (copilot-lsp)
--   :ToggleCopilotInline  cursor-position ghost text
--   :ToggleCopilotNES     pink/yellow diff preview away from the cursor
local copilot_opts = {
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
}

-- Each feature runs only while both the user toggle and the network are up;
-- see plugins/copilot_online.lua for the network side.
local want = { inline = true, nes = true }
local online = false

-- NES draws its preview as extmarks; drop the leftovers when switching off
local function clear_nes_marks()
  local ns = vim.api.nvim_get_namespaces()['copilotlsp.nes']
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      if ns then
        pcall(vim.api.nvim_buf_clear_namespace, buf, ns, 0, -1)
      end
      vim.b[buf].nes_state = nil
      vim.b[buf].nes_jump = nil
    end
  end
end

local function apply_inline()
  local on = online and want.inline
  local copilot = require('copilot')
  if not copilot.setup_done then
    if on then
      copilot.setup(copilot_opts)
    end
    return
  end
  if on then
    require('copilot.command').enable()
  else
    require('copilot.command').disable()
  end
end

-- NES lives entirely in the copilot_ls client, so stopping it stops the requests too
local function apply_nes()
  local on = online and want.nes
  vim.lsp.enable('copilot_ls', on)
  if not on then
    clear_nes_marks()
  end
end

require('plugins.copilot_online').setup(function(is_online)
  online = is_online
  apply_inline()
  apply_nes()
end)

-- Toggle commands
local function toggle(key, label, apply)
  want[key] = not want[key]
  apply()
  local state = want[key] and (online and 'ON' or 'ON (offline, pending)') or 'OFF'
  vim.notify('Copilot ' .. label .. ': ' .. state)
end

vim.api.nvim_create_user_command('ToggleCopilotInline', function()
  toggle('inline', 'Inline', apply_inline)
end, { desc = 'Toggle Copilot inline completion (ghost text)' })

vim.api.nvim_create_user_command('ToggleCopilotNES', function()
  toggle('nes', 'NES', apply_nes)
end, { desc = 'Toggle Copilot next edit suggestion (pink/yellow preview)' })

-- NES keymaps (normal mode)
vim.keymap.set('n', '<Tab>', function()
  local state = want.nes and vim.b[vim.api.nvim_get_current_buf()].nes_state
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

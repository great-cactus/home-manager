-- Copilot: inline ghost text (copilot.lua) and NES next edit suggestion (copilot-lsp)
--   :ToggleCopilotInline  cursor-position ghost text
--   :ToggleCopilotNES     pink/yellow diff preview away from the cursor
-- In OFF_BY_DEFAULT filetypes both start off and the toggles act on the current buffer only.
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

local OFF_BY_DEFAULT = { markdown = true }

local function is_per_buf(buf)
  return OFF_BY_DEFAULT[vim.bo[buf].filetype] == true
end

local function buf_want(buf, key)
  local v = vim.b[buf]['copilot_want_' .. key]
  if v == nil then
    return not is_per_buf(buf)
  end
  return v
end

-- NES draws its preview as extmarks; drop the leftovers when switching off
local function clear_nes_marks(buf)
  local ns = vim.api.nvim_get_namespaces()['copilotlsp.nes']
  if vim.api.nvim_buf_is_valid(buf) then
    if ns then
      pcall(vim.api.nvim_buf_clear_namespace, buf, ns, 0, -1)
    end
    vim.b[buf].nes_state = nil
    vim.b[buf].nes_jump = nil
  end
end

-- Per-buffer gates: inline via copilot.lua's buffer auto_trigger,
-- NES by keeping copilot_ls detached from the buffer
local function sync_buf_inline(buf)
  if buf_want(buf, 'inline') then
    vim.b[buf].copilot_suggestion_auto_trigger = nil
  else
    vim.b[buf].copilot_suggestion_auto_trigger = false
  end
  if buf == vim.api.nvim_get_current_buf() and package.loaded['copilot.suggestion'] then
    require('copilot.suggestion').dismiss()
  end
end

local function sync_buf_nes(buf)
  local client = vim.lsp.get_clients({ name = 'copilot_ls' })[1]
  if not client then
    return
  end
  local attached = client.attached_buffers[buf]
  if buf_want(buf, 'nes') then
    if not attached then
      vim.lsp.buf_attach_client(buf, client.id)
    end
  elseif attached then
    vim.lsp.buf_detach_client(buf, client.id)
    clear_nes_marks(buf)
  end
end

local buf_sync = { inline = sync_buf_inline, nes = sync_buf_nes }

local group = vim.api.nvim_create_augroup('CopilotPerBuf', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  callback = function(args)
    sync_buf_inline(args.buf)
    sync_buf_nes(args.buf)
  end,
})
vim.api.nvim_create_autocmd('LspAttach', {
  group = group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == 'copilot_ls' and not buf_want(args.buf, 'nes') then
      vim.schedule(function()
        sync_buf_nes(args.buf)
      end)
    end
  end,
})
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(buf) then
    sync_buf_inline(buf)
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
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      clear_nes_marks(buf)
    end
  end
end

require('plugins.copilot_online').setup(function(is_online)
  online = is_online
  apply_inline()
  apply_nes()
end)

-- Toggle commands
local function toggle(key, label, apply)
  local buf = vim.api.nvim_get_current_buf()
  if is_per_buf(buf) then
    local on = not buf_want(buf, key)
    vim.b[buf]['copilot_want_' .. key] = on
    buf_sync[key](buf)
    vim.notify('Copilot ' .. label .. ' (this buffer): ' .. (on and 'ON' or 'OFF'))
    return
  end
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

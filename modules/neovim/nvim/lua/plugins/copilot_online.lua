-- Online gate for Copilot: keep copilot.lua / copilot_ls stopped while offline
-- and bring them back automatically once the network recovers.
local M = {}

local PROBE_CMD = { 'curl', '-sI', '-m', '3', '-o', '/dev/null', 'https://api.github.com' }
local RETRY_MS = 60000

local online = nil -- nil: unknown, true/false: last probe result
local probing = false
local timer = nil

local function stop_timer()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

local function start_timer()
  if timer then
    return
  end
  timer = vim.uv.new_timer()
  timer:start(RETRY_MS, RETRY_MS, vim.schedule_wrap(M.probe))
end

local function apply(is_online)
  if is_online == online then
    return
  end
  local first = online == nil
  online = is_online
  M.on_change(is_online)
  if is_online then
    stop_timer()
  else
    -- Poll only while offline; FocusGained covers the online -> offline case
    start_timer()
  end
  if not (first and is_online) then
    vim.notify('Copilot: ' .. (is_online and 'online, enabled' or 'offline, disabled'))
  end
end

function M.probe()
  if probing then
    return
  end
  probing = true
  local ok = pcall(vim.system, PROBE_CMD, {}, vim.schedule_wrap(function(result)
    probing = false
    apply(result.code == 0)
  end))
  if not ok then
    -- Probe command unavailable: fail open
    probing = false
    apply(true)
  end
end

--- @param on_change fun(is_online: boolean) called on every state transition
function M.setup(on_change)
  M.on_change = on_change
  vim.api.nvim_create_autocmd('FocusGained', {
    group = vim.api.nvim_create_augroup('CopilotOnline', { clear = true }),
    callback = M.probe,
  })
  M.probe()
end

return M

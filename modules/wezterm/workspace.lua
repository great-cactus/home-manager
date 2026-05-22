local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

-- Show workspace selector and switch to selected workspace
function M.selector(window, pane)
  local workspaces = wezterm.mux.get_workspace_names()
  local current = window:active_workspace()

  local choices = {}
  for _, name in ipairs(workspaces) do
    local label = name
    if name == current then
      label = name .. ' (current)'
    end
    table.insert(choices, { id = name, label = label })
  end

  window:perform_action(
    act.InputSelector {
      title = 'Select Workspace',
      choices = choices,
      fuzzy = true,
      action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
        if id then
          inner_window:perform_action(
            act.SwitchToWorkspace { name = id },
            inner_pane
          )
        end
      end),
    },
    pane
  )
end

-- Create new workspace with name input
function M.create(window, pane)
  window:perform_action(
    act.PromptInputLine {
      description = 'Enter name for new workspace',
      action = wezterm.action_callback(function(inner_window, inner_pane, line)
        if line and line ~= '' then
          inner_window:perform_action(
            act.SwitchToWorkspace { name = line },
            inner_pane
          )
        end
      end),
    },
    pane
  )
end

-- Rename current workspace
function M.rename(window, pane)
  local current = window:active_workspace()
  window:perform_action(
    act.PromptInputLine {
      description = 'Rename workspace "' .. current .. '" to:',
      action = wezterm.action_callback(function(inner_window, inner_pane, line)
        if line and line ~= '' then
          wezterm.mux.rename_workspace(current, line)
        end
      end),
    },
    pane
  )
end

return M

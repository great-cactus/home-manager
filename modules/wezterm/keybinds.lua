local wezterm = require 'wezterm'
local act = wezterm.action
local workspace = require 'workspace'

local M = {}

function M.apply(config)
  -------------------------------------------------
  -- Leader Key (Ctrl-q)
  -------------------------------------------------
  config.leader = { key = 'q', mods = 'CTRL', timeout_milliseconds = 1000 }

  -------------------------------------------------
  -- Key Bindings
  -------------------------------------------------
  config.disable_default_key_bindings = true
  config.keys = {
    -- Reload config
    { key = 'r', mods = 'CMD|SHIFT', action = act.ReloadConfiguration },

    -- Toggle title bar
    {
      key = 'Enter',
      mods = 'CTRL|ALT',
      action = wezterm.action_callback(function(window, pane)
        local overrides = window:get_config_overrides() or {}
        if overrides.window_decorations == 'RESIZE' then
          overrides.window_decorations = 'TITLE | RESIZE'
        else
          overrides.window_decorations = 'RESIZE'
        end
        window:set_config_overrides(overrides)
      end),
    },

    -- Pane navigation (Leader + h/j/k/l)
    { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
    { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
    { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
    { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

    -- Pane resize (Leader + H/J/K/L)
    { key = 'H', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Left', 10 } },
    { key = 'J', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Down', 10 } },
    { key = 'K', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Up', 10 } },
    { key = 'L', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize { 'Right', 10 } },

    -- Split panes
    { key = 'v', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 's', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

    -- Close pane
    { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },

    -- New tab
    { key = 'n', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },

    -- Tab navigation (Leader + 1-9)
    { key = '1', mods = 'LEADER', action = act.ActivateTab(0) },
    { key = '2', mods = 'LEADER', action = act.ActivateTab(1) },
    { key = '3', mods = 'LEADER', action = act.ActivateTab(2) },
    { key = '4', mods = 'LEADER', action = act.ActivateTab(3) },
    { key = '5', mods = 'LEADER', action = act.ActivateTab(4) },
    { key = '6', mods = 'LEADER', action = act.ActivateTab(5) },
    { key = '7', mods = 'LEADER', action = act.ActivateTab(6) },
    { key = '8', mods = 'LEADER', action = act.ActivateTab(7) },
    { key = '9', mods = 'LEADER', action = act.ActivateTab(8) },

    -- Copy mode
    { key = '[', mods = 'LEADER', action = act.ActivateCopyMode },

    -- Paste
    { key = 'p', mods = 'LEADER|CTRL', action = act.PasteFrom 'Clipboard' },

    -- Workspace management
    { key = 'w', mods = 'LEADER', action = wezterm.action_callback(workspace.selector) },
    { key = 'W', mods = 'LEADER|SHIFT', action = wezterm.action_callback(workspace.create) },
    { key = '$', mods = 'LEADER|SHIFT', action = wezterm.action_callback(workspace.rename) },

    -- Refresh terminal screen
    { key = 'Q', mods = 'LEADER|SHIFT', action = act.Multiple {
      act.ClearScrollback 'ScrollbackAndViewport',
      act.SendString '\x0c',
    } },

    -- Font size
    { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
    { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
    { key = '0', mods = 'CTRL', action = act.ResetFontSize },
  }

  -------------------------------------------------
  -- Mouse Bindings
  -------------------------------------------------
  config.mouse_bindings = {
    -- Right click to paste
    {
      event = { Down = { streak = 1, button = 'Right' } },
      mods = 'NONE',
      action = act.PasteFrom 'Clipboard',
    },
    -- Copy on select
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'NONE',
      action = act.CompleteSelection 'ClipboardAndPrimarySelection',
    },
  }

  -------------------------------------------------
  -- Copy Mode (vim-style)
  -------------------------------------------------
  config.key_tables = {
    copy_mode = {
      -- Navigation
      { key = 'h', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
      { key = 'j', mods = 'NONE', action = act.CopyMode 'MoveDown' },
      { key = 'k', mods = 'NONE', action = act.CopyMode 'MoveUp' },
      { key = 'l', mods = 'NONE', action = act.CopyMode 'MoveRight' },

      -- Word movement
      { key = 'w', mods = 'NONE', action = act.CopyMode 'MoveForwardWord' },
      { key = 'b', mods = 'NONE', action = act.CopyMode 'MoveBackwardWord' },

      -- Line movement
      { key = '0', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLine' },
      { key = '$', mods = 'SHIFT', action = act.CopyMode 'MoveToEndOfLineContent' },

      -- Page movement
      { key = 'u', mods = 'CTRL', action = act.CopyMode 'PageUp' },
      { key = 'd', mods = 'CTRL', action = act.CopyMode 'PageDown' },

      -- Selection
      { key = 'v', mods = 'NONE', action = act.CopyMode { SetSelectionMode = 'Cell' } },
      { key = 'V', mods = 'SHIFT', action = act.CopyMode { SetSelectionMode = 'Line' } },

      -- Copy and exit
      {
        key = 'y',
        mods = 'NONE',
        action = act.Multiple {
          act.CopyTo 'ClipboardAndPrimarySelection',
          act.CopyMode 'Close',
        },
      },
      {
        key = 'Enter',
        mods = 'NONE',
        action = act.Multiple {
          act.CopyTo 'ClipboardAndPrimarySelection',
          act.CopyMode 'Close',
        },
      },

      -- Exit
      { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },
      { key = 'q', mods = 'NONE', action = act.CopyMode 'Close' },
    },
  }
end

return M

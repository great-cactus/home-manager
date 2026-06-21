local wezterm = require 'wezterm'
local keybinds = require 'keybinds'
local config = wezterm.config_builder()

-------------------------------------------------
-- CGI Color Palette
-------------------------------------------------
local cgi = {
  bg = '#f3f3f3',
  fg = '#273f3d',
  rose = '#885782',
  leaf = '#7f7650',
  wood = '#523629',
  water = '#69a6a2',
  blossom = '#a5689c',
  sky = '#7ac2bd',
}

-------------------------------------------------
-- Basic Settings
-------------------------------------------------
config.font = wezterm.font('Bizin Gothic NF')
config.color_scheme = 'Papercolor Light (Gogh)'
config.term = 'wezterm'
config.enable_kitty_graphics = true
config.enable_csi_u_key_encoding = true
config.adjust_window_size_when_changing_font_size = false
config.default_domain = 'WSL:Ubuntu-22.04'
config.canonicalize_pasted_newlines = 'LineFeed'
config.selection_word_boundary = ' \t\n{}[]()"\'`'

-------------------------------------------------
-- Tab Bar Settings
-------------------------------------------------
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = false
config.show_tab_index_in_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

config.colors = {
  tab_bar = {
    background = cgi.bg,
    active_tab = {
      bg_color = cgi.water,
      fg_color = cgi.fg,
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = cgi.bg,
      fg_color = cgi.leaf,
    },
    inactive_tab_hover = {
      bg_color = cgi.sky,
      fg_color = cgi.fg,
    },
    new_tab = {
      bg_color = cgi.bg,
      fg_color = cgi.leaf,
    },
    new_tab_hover = {
      bg_color = cgi.water,
      fg_color = cgi.fg,
    },
  },
}

-------------------------------------------------
-- Key Bindings
-------------------------------------------------
keybinds.apply(config)

-------------------------------------------------
-- Tab Title (1-indexed)
-------------------------------------------------
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local index = tab.tab_index + 1

  if tab.is_active then
    return wezterm.format {
      { Foreground = { Color = '#000000' } },
      { Background = { Color = cgi.bg } },
      { Text = '│' },
      { Attribute = { Underline = 'Single' } },
      { Text = ' ' .. index .. ' ' },
      { Attribute = { Underline = 'None' } },
      { Text = '│' },
    }
  else
    return wezterm.format {
      { Background = { Color = '#808080' } },
      { Foreground = { Color = '#ffffff' } },
      { Text = ' ' .. index .. ' ' },
    }
  end
end)

return config

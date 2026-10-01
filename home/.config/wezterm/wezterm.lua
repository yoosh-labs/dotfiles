local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "rose-pine-moon"
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 15.0
config.window_background_opacity = 0.8
config.macos_window_background_blur = 50
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"

-- Dim unfocused windows so the focused one is obvious at a glance.
local UNFOCUSED_FOREGROUND_TEXT_HSB = { hue = 1.0, saturation = 0.25, brightness = 0.45 }
local UNFOCUSED_WINDOW_BACKGROUND_OPACITY = wezterm.target_triple:find("linux") and 0.70 or 0.62 -- linux-patch

-- get_config_overrides() hands back a copy, so the current value is never the
-- same table we last stored; compare the fields instead of the identity.
local function same_text_hsb(actual, expected)
	if actual == nil or expected == nil then
		return actual == expected
	end
	return actual.hue == expected.hue
		and actual.saturation == expected.saturation
		and actual.brightness == expected.brightness
end

wezterm.on("window-focus-changed", function(window)
	local overrides = window:get_config_overrides() or {}
	local text_hsb, opacity
	if not window:is_focused() then
		text_hsb = UNFOCUSED_FOREGROUND_TEXT_HSB
		opacity = UNFOCUSED_WINDOW_BACKGROUND_OPACITY
	end

	-- Only write when one of the two values we own actually changes; a redundant
	-- set_config_overrides() call would trigger another config reload.
	if same_text_hsb(overrides.foreground_text_hsb, text_hsb) and overrides.window_background_opacity == opacity then
		return
	end

	overrides.foreground_text_hsb = text_hsb
	overrides.window_background_opacity = opacity
	window:set_config_overrides(overrides)
end)

-- linux-patch: Ubuntu overrides (XPS 15 fractions). macOS behavior above is untouched.
if wezterm.target_triple:find("linux") then
  local WINDOW_WIDTH_FRACTION = 0.49   -- about half the screen width
  local WINDOW_HEIGHT_FRACTION = 0.92  -- leaves room for the title bar and edge gaps

  config.font_size = 12.0
  config.window_background_opacity = 0.85
  config.window_decorations = "TITLE | RESIZE"
  config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
  config.default_prog = { "/usr/bin/zsh" }
  -- Fallback size in cells, used if the startup handler below cannot read the screen
  config.initial_cols = 124
  config.initial_rows = 64

  wezterm.on("gui-startup", function(cmd)
    local _, _, window = wezterm.mux.spawn_window(cmd or {})
    local gui = window:gui_window()
    local ok, screens = pcall(function() return wezterm.gui.screens() end)
    if ok and screens and screens.active then
      gui:set_inner_size(
        math.floor(screens.active.width * WINDOW_WIDTH_FRACTION),
        math.floor(screens.active.height * WINDOW_HEIGHT_FRACTION)
      )
    end
  end)

  -- Ctrl+Alt+Shift+T toggles the title bar (default: shown)
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = "T",
    mods = "CTRL|ALT|SHIFT",
    action = wezterm.action_callback(function(window, _)
      local overrides = window:get_config_overrides() or {}
      if overrides.window_decorations == "RESIZE" then
        overrides.window_decorations = nil
      else
        overrides.window_decorations = "RESIZE"
      end
      window:set_config_overrides(overrides)
    end),
  })
end

return config

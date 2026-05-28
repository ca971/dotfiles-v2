--- @module "events.theme_switcher""
--- @description Custom event to cycle through available themes.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local LoggerModule = require("lib.logger")

local M = {}

--- @type table<number, string>
--- Theme cycle order.
local THEME_CYCLE = {
  "catppuccin_mocha",
  "catppuccin_macchiato",
  "tokyo_night",
  "tokyo_night_storm",
  "rose_pine",
  "rose_pine_moon",
  "kanagawa",
  "gruvbox_dark",
  "nord",
  "dracula",
}

--- @type number
local _current_index = 1

--- Register the cycle-theme custom event.
--- @param wezterm table The wezterm module
function M.register(wezterm)
  local log = LoggerModule.create("event.theme")

  wezterm.on("cycle-theme", function(window, pane)
    _current_index = (_current_index % #THEME_CYCLE) + 1
    local theme_name = THEME_CYCLE[_current_index]

    -- Try to load and apply the theme
    local ok, ThemeEngine = pcall(require, "themes")
    if ok and type(ThemeEngine) == "table" and ThemeEngine.apply then
      ThemeEngine.apply(theme_name)

      local Colors = require("core.colors")
      local overrides = window:get_config_overrides() or {}
      overrides.colors = Colors.to_wezterm_scheme()
      window:set_config_overrides(overrides)

      log:info("Theme switched", { theme = theme_name })

      window:toast_notification("WezTerm", "Theme: " .. theme_name, nil, 3000)
    else
      log:warn("Theme engine not available")
    end
  end)
end

return M

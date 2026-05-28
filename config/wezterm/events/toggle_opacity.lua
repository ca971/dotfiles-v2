--- @module "events.toggle_opacity""
--- @description Custom event to toggle window opacity.
--- Cycles between opaque and transparent states.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local LoggerModule = require("lib.logger")
local Settings = require("core.settings")

local M = {}

--- Register the toggle-opacity custom event.
--- @param wezterm table The wezterm module
function M.register(wezterm)
  local log = LoggerModule.create("event.opacity")

  wezterm.on("toggle-opacity", function(window, pane)
    local overrides = window:get_config_overrides() or {}

    local current = overrides.window_background_opacity or Settings.get("window.opacity", 0.95)

    if current < 1.0 then
      overrides.window_background_opacity = 1.0
      log:info("Opacity set to 1.0 (opaque)")
    else
      overrides.window_background_opacity = Settings.get("window.opacity", 0.95)
      log:info("Opacity restored", {
        value = tostring(Settings.get("window.opacity", 0.95)),
      })
    end

    window:set_config_overrides(overrides)
  end)
end

return M

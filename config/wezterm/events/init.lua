--- @module "events""
--- @description Event registration orchestrator.
--- Loads and registers all WezTerm event handlers in the correct order.
--- Handles both built-in events and custom events.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local LoggerModule = require("lib.logger")

--- @class Events
--- @field _VERSION string Module version
local Events = {
  _VERSION = "1.0.0",
}

--- @type table<number, string>
--- Event modules to load in registration order.
local EVENT_MODULES = {
  "events.startup",
  "events.tab_title",
  "events.window_title",
  "events.new_tab",
  "events.toggle_opacity",
  "events.theme_switcher",
  "events.cheat_sheet",
  "events.augment_command_palette",
  -- Note: update_status is handled by bar/init.lua
}

--- Register all event handlers.
--- @param wezterm table The wezterm module
--- @param platform_info table Platform detection info
function Events.register(wezterm, platform_info)
  local log = LoggerModule.create("events")

  -- Register bar events (handles update-status)
  local bar_ok, Bar = pcall(require, "bar")
  if bar_ok and type(Bar) == "table" and Bar.register then
    Bar.register(wezterm, platform_info)
    log:info("Bar events registered")
  else
    log:debug("Bar module not available")
  end

  -- Register all other events
  local registered = 0
  for _, module_path in ipairs(EVENT_MODULES) do
    local ok, mod = pcall(require, module_path)
    if ok and type(mod) == "table" and type(mod.register) == "function" then
      local reg_ok, reg_err = pcall(mod.register, wezterm, platform_info)
      if reg_ok then
        registered = registered + 1
      else
        log:warn("Event registration failed", {
          module = module_path,
          error = tostring(reg_err),
        })
      end
    else
      log:debug("Event module skipped", {
        module = module_path,
        reason = ok and "no register function" or tostring(mod),
      })
    end
  end

  log:info("Events registration complete", {
    registered = tostring(registered),
    total = tostring(#EVENT_MODULES),
  })
end

return Events

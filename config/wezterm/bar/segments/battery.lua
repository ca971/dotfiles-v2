--- @module "bar.segments.battery""
--- @description Battery status segment.
--- Shows battery percentage with adaptive icon and color.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local IconsModule = require("core.icons")
local Settings = require("core.settings")

local M = {}

--- Render the battery segment.
--- @param wezterm table The wezterm module
--- @param context table Render context
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  if not Settings.get("features.battery_indicator", true) then
    return nil
  end

  local battery_info = wezterm.battery_info()
  if not battery_info or #battery_info == 0 then
    return nil
  end

  local bat = battery_info[1]
  local level = math.floor((bat.state_of_charge or 0) * 100 + 0.5)
  local is_charging = bat.state == "Charging"

  -- Adaptive color based on level
  local bg
  if is_charging then
    bg = Colors.accent("green")
  elseif level >= 60 then
    bg = Colors.accent("green")
  elseif level >= 30 then
    bg = Colors.accent("yellow")
  elseif level >= 10 then
    bg = Colors.accent("peach")
  else
    bg = Colors.accent("red")
  end

  local icon = IconsModule.battery(level, is_charging)

  return {
    text = string.format("%d%%", level),
    fg = Colors.base("crust"),
    bg = bg,
    icon = icon,
    priority = 70,
  }
end

return M

--- @module "bar.segments.datetime""
--- @description Date and time segment.
--- Shows formatted date/time with configurable format.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")

local M = {}

--- Render the datetime segment.
--- @param wezterm table The wezterm module
--- @param context table Render context
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  local date_str = wezterm.strftime("%a %b %-d")
  local time_str = wezterm.strftime("%H:%M")

  return {
    text = date_str .. " " .. time_str,
    fg = Colors.base("crust"),
    bg = Colors.accent("blue"),
    icon = Icons.ui("calendar"),
    priority = 90,
  }
end

return M

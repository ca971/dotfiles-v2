--- @module "bar.segments.username""
--- @description Username segment for status bar.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")

local M = {}

--- Render the username segment.
--- @param wezterm table The wezterm module
--- @param context table Render context
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  local username = os.getenv("USER") or os.getenv("USERNAME") or "user"

  return {
    text = username,
    fg = Colors.base("text"),
    bg = Colors.base("surface0"),
    icon = Icons.ui("home"),
    priority = 35,
  }
end

return M

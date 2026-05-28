--- @module "bar.segments.hostname""
--- @description Hostname segment for status bar.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")

local M = {}

--- Render the hostname segment.
--- @param wezterm table The wezterm module
--- @param context table Render context
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  local hostname = context.platform_info and context.platform_info.hostname or "unknown"

  -- Shorten FQDN
  hostname = hostname:match("^([^%.]+)") or hostname

  return {
    text = hostname,
    fg = Colors.base("text"),
    bg = Colors.base("surface1"),
    icon = Icons.ui("gear"),
    priority = 30,
  }
end

return M

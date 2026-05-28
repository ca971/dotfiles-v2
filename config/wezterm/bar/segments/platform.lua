--- @module "bar.segments.platform""
--- @description OS/Platform indicator segment.
--- Shows the current operating system with appropriate icon.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")

local M = {}

--- Render the platform segment.
--- @param wezterm table The wezterm module
--- @param context table Render context
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  local info = context.platform_info
  if not info then
    return nil
  end

  local os_name = info.os or "unknown"
  local icon = Icons.os(os_name)

  local display = os_name
  if info.is_wsl then
    display = "WSL"
    icon = Icons.get("env", "wsl")
  end

  return {
    text = display,
    fg = Colors.base("text"),
    bg = Colors.base("surface1"),
    icon = icon,
    priority = 60,
  }
end

return M

--- @module "bar.segments.mode""
--- @description Current key table / mode indicator segment.
--- Shows NORMAL, COPY, SEARCH, or RESIZE mode with distinct colors.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")

local M = {}

--- @type table<string, table>
local MODE_CONFIG = {
  normal = { label = "NORMAL", bg = Colors.accent("blue"), icon = Icons.ui("rocket") },
  copy_mode = { label = "COPY", bg = Colors.accent("yellow"), icon = Icons.ui("check") },
  search_mode = { label = "SEARCH", bg = Colors.accent("green"), icon = Icons.ui("search") },
  resize_pane = { label = "RESIZE", bg = Colors.accent("mauve"), icon = Icons.ui("gear") },
}

--- Render the mode segment.
--- @param wezterm table The wezterm module
--- @param context table Render context with window, pane
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  local window = context.window
  if not window then
    return nil
  end

  local mode_name = "normal"
  local name = window:active_key_table()
  if name then
    mode_name = name
  end

  local cfg = MODE_CONFIG[mode_name] or MODE_CONFIG.normal

  return {
    text = cfg.label,
    fg = Colors.base("crust"),
    bg = cfg.bg,
    icon = cfg.icon,
    priority = 1,
  }
end

return M

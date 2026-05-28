--- @module "bar.segments.workspace""
--- @description Active workspace/session name segment.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")

local M = {}

--- Render the workspace segment.
--- @param wezterm table The wezterm module
--- @param context table Render context
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  local window = context.window
  if not window then
    return nil
  end

  local workspace = window:active_workspace()
  if not workspace or workspace == "default" then
    return nil
  end

  return {
    text = workspace,
    fg = Colors.base("text"),
    bg = Colors.accent("mauve"),
    icon = Icons.ui("folder"),
    priority = 10,
  }
end

return M

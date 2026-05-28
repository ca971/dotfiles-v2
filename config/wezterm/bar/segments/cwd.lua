--- @module "bar.segments.cwd""
--- @description Current working directory segment.
--- Shows shortened CWD with home directory substitution.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")
local PathUtils = require("lib.path")

local M = {}

--- Render the CWD segment.
--- @param wezterm table The wezterm module
--- @param context table Render context
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  local pane = context.pane
  if not pane then
    return nil
  end

  local cwd_uri = pane:get_current_working_dir()
  if not cwd_uri then
    return nil
  end

  local cwd = ""
  if type(cwd_uri) == "userdata" and cwd_uri.file_path then
    cwd = cwd_uri.file_path
  elseif type(cwd_uri) == "string" then
    cwd = cwd_uri:gsub("^file://[^/]*", "")
  else
    return nil
  end

  -- Shorten the path
  local shortened = PathUtils.shorten(cwd, 30)

  return {
    text = shortened,
    fg = Colors.base("text"),
    bg = Colors.base("surface0"),
    icon = Icons.ui("folder_open"),
    priority = 15,
  }
end

return M

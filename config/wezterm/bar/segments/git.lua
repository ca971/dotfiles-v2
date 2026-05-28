--- @module "bar.segments.git""
--- @description Git branch and status segment.
--- Shows current branch name and dirty/clean status indicator.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")
local Settings = require("core.settings")

local M = {}

--- Render the git segment.
--- @param wezterm table The wezterm module
--- @param context table Render context
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  if not Settings.get("features.git_status", true) then
    return nil
  end

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

  -- Get git branch
  local handle = io.popen(string.format("cd %q && git branch --show-current 2>/dev/null", cwd))
  if not handle then
    return nil
  end

  local branch = handle:read("*l")
  handle:close()

  if not branch or #branch == 0 then
    return nil
  end

  -- Check if dirty
  local status_handle =
    io.popen(string.format("cd %q && git status --porcelain 2>/dev/null | head -1", cwd))
  local is_dirty = false
  if status_handle then
    local status_line = status_handle:read("*l")
    status_handle:close()
    is_dirty = status_line ~= nil and #status_line > 0
  end

  local status_icon = is_dirty and Icons.get("git", "dirty") or Icons.get("git", "clean")

  return {
    text = branch .. " " .. status_icon,
    fg = Colors.base("crust"),
    bg = is_dirty and Colors.accent("peach") or Colors.accent("green"),
    icon = Icons.get("git", "branch"),
    priority = 20,
  }
end

return M

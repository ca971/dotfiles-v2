--- @module "bar.segments.shell""
--- @description Active shell indicator segment.
--- Shows which shell is running in the current pane.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")

local M = {}

--- Render the shell segment.
--- @param wezterm table The wezterm module
--- @param context table Render context
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  local pane = context.pane
  if not pane then
    return nil
  end

  local process = pane:get_foreground_process_name() or ""
  local shell_name = process:match("([^/\\]+)$") or "shell"
  shell_name = shell_name:gsub("%.exe$", "")

  -- Only show for known shells
  local known = { zsh = true, fish = true, bash = true, nu = true, pwsh = true, cmd = true }
  if not known[shell_name:lower()] then
    return nil
  end

  local icon = Icons.shell(shell_name:lower())

  return {
    text = shell_name,
    fg = Colors.base("text"),
    bg = Colors.base("surface1"),
    icon = icon,
    priority = 50,
  }
end

return M

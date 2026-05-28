--- @module "bar.segments.tools""
--- @description Tool detection segment.
--- Shows detected DevOps tools (tmux, docker, podman, kubectl,
--- docker-compose, helm, terraform, git).
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")
local ProcessModule = require("lib.process")
local Settings = require("core.settings")

local M = {}

--- @type table<number, table>
--- Tools to check with their icon category.
local TOOL_CHECKS = {
  { name = "tmux", icon_cat = "tool", icon_name = "tmux" },
  { name = "docker", icon_cat = "devops", icon_name = "docker" },
  { name = "podman", icon_cat = "devops", icon_name = "podman" },
  { name = "kubectl", icon_cat = "devops", icon_name = "kubernetes" },
  { name = "docker-compose", icon_cat = "devops", icon_name = "docker" },
  { name = "helm", icon_cat = "devops", icon_name = "helm" },
  { name = "terraform", icon_cat = "devops", icon_name = "terraform" },
}

--- Render the tools segment.
--- @param wezterm table The wezterm module
--- @param context table Render context
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  if not Settings.get("features.tool_detection", true) then
    return nil
  end

  local detector = ProcessModule.get_detector({
    platform_info = context.platform_info,
  })

  local parts = {}

  for _, tool in ipairs(TOOL_CHECKS) do
    if detector:is_available(tool.name) then
      local icon = Icons.get(tool.icon_cat, tool.icon_name)
      parts[#parts + 1] = icon
    end
  end

  if #parts == 0 then
    return nil
  end

  return {
    text = table.concat(parts, " "),
    fg = Colors.accent("sapphire"),
    bg = Colors.base("surface0"),
    priority = 46,
  }
end

return M

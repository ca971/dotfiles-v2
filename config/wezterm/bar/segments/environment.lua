--- @module "bar.segments.environment""
--- @description Environment detection segment.
--- Shows the current environment context: Docker, Kubernetes, SSH,
--- VPS, Proxmox, OPNsense, WSL, or local machine.
--- This is the "Information Center" core segment.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")
local Settings = require("core.settings")

local M = {}

--- Render the environment segment.
--- @param wezterm table The wezterm module
--- @param context table Render context
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  if not Settings.get("features.environment_detection", true) then
    return nil
  end

  local info = context.platform_info
  if not info then
    return nil
  end

  local indicators = {}

  -- Priority order: most specific first
  if info.is_kubernetes then
    indicators[#indicators + 1] = {
      label = "K8s",
      icon = Icons.devops("kubernetes"),
      bg = Colors.accent("blue"),
    }
  end

  if info.is_docker then
    indicators[#indicators + 1] = {
      label = "Docker",
      icon = Icons.devops("docker"),
      bg = Colors.accent("sky"),
    }
  end

  if info.is_podman then
    indicators[#indicators + 1] = {
      label = "Podman",
      icon = Icons.devops("podman"),
      bg = Colors.accent("mauve"),
    }
  end

  if info.is_proxmox then
    indicators[#indicators + 1] = {
      label = "Proxmox",
      icon = Icons.devops("proxmox"),
      bg = Colors.accent("peach"),
    }
  end

  if info.is_opnsense then
    indicators[#indicators + 1] = {
      label = "OPNsense",
      icon = Icons.devops("opnsense"),
      bg = Colors.accent("flamingo"),
    }
  end

  if info.is_remote then
    local remote_type = info.is_mosh and "Mosh" or "SSH"
    local remote_icon = info.is_mosh and Icons.tool("mosh") or Icons.tool("ssh")
    indicators[#indicators + 1] = {
      label = remote_type,
      icon = remote_icon,
      bg = Colors.accent("yellow"),
    }
  end

  if info.is_vps and not info.is_proxmox then
    indicators[#indicators + 1] = {
      label = "VPS",
      icon = Icons.get("env", "cloud"),
      bg = Colors.accent("sapphire"),
    }
  end

  if info.is_wsl then
    indicators[#indicators + 1] = {
      label = "WSL" .. (info.wsl_version or ""),
      icon = Icons.get("env", "wsl"),
      bg = Colors.accent("peach"),
    }
  end

  -- If nothing detected, show "Local"
  if #indicators == 0 then
    return {
      text = "Local",
      fg = Colors.base("text"),
      bg = Colors.base("surface0"),
      icon = Icons.get("env", "local_machine"),
      priority = 40,
    }
  end

  -- Combine all indicators
  local labels = {}
  for _, ind in ipairs(indicators) do
    labels[#labels + 1] = ind.icon .. " " .. ind.label
  end

  -- Use the first indicator's colors as the segment color
  local primary = indicators[1]

  return {
    text = table.concat(labels, " │ "),
    fg = Colors.base("crust"),
    bg = primary.bg,
    priority = 5,
  }
end

return M

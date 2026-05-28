--- @module "bar.segments.network""
--- @description Network/VPN status segment.
--- Shows network connectivity and VPN status.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")
local Settings = require("core.settings")

local M = {}

--- Render the network segment.
--- @param wezterm table The wezterm module
--- @param context table Render context
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  if not Settings.get("features.network_indicator", false) then
    return nil
  end

  -- Check for VPN (common VPN interfaces/env vars)
  local vpn_active = false
  local handle = io.popen("ip link show 2>/dev/null | grep -qE 'tun|wg|vpn' && echo yes || echo no")
  if handle then
    local result = handle:read("*l")
    handle:close()
    vpn_active = result == "yes"
  end

  if vpn_active then
    return {
      text = "VPN",
      fg = Colors.base("crust"),
      bg = Colors.accent("green"),
      icon = Icons.tool("vpn"),
      priority = 55,
    }
  end

  return nil
end

return M

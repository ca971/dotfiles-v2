--- @module "events.update_status""
--- @description Update-status event handler (delegates to bar module).
--- This is registered by bar/init.lua directly.
--- This file exists for explicit event documentation and potential overrides.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local M = {}

--- Register the update-status event.
--- Note: The actual registration is done by Bar.register().
--- This module provides a hook for additional status processing.
--- @param wezterm table The wezterm module
--- @param platform_info table Platform info
function M.register(wezterm, platform_info)
  -- Bar.register() handles the primary update-status event.
  -- Additional status processing can be added here.
end

return M

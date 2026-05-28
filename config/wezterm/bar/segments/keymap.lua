--- @module "bar.segments.keymap""
--- @description Active keymap/keyboard layout segment.
--- Shows the current keyboard layout indicator.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")

local M = {}

--- Render the keymap segment.
--- @param wezterm table The wezterm module
--- @param context table Render context
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  -- Keyboard layout detection is platform-specific and limited
  -- This segment is available for users who want to customize it
  -- via local overrides

  return nil -- Disabled by default; enable via local override
end

return M

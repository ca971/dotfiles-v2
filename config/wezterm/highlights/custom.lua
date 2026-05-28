--- @module "highlights.custom""
--- @description User-defined custom highlight patterns.
--- This file is intended for user customization via local overrides.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local M = {}

--- Get custom hyperlink rules.
--- Override in local/highlights.lua for custom patterns.
--- @return table rules Array of WezTerm hyperlink rules
function M.get_rules()
  return {}
end

return M

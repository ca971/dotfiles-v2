--- @module "highlights.errors""
--- @description Error and warning output pattern rules.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local M = {}

--- Get error/warning pattern rules.
--- @return table rules Array of WezTerm hyperlink rules
function M.get_rules()
  return {
    -- Common error patterns: filename:line:col
    {
      regex = "[\\w./\\-]+\\.[\\w]+:\\d+:\\d+",
      format = "$0",
    },
  }
end

return M

--- @module "highlights.paths""
--- @description File path pattern rules.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local M = {}

--- Get file path hyperlink rules.
--- @return table rules Array of WezTerm hyperlink rules
function M.get_rules()
  return {
    -- Unix file paths with line numbers (e.g., /path/to/file.lua:42)
    {
      regex = "(?:/[\\w.\\-]+)+(?::\\d+)?",
      format = "$0",
    },
    -- Relative paths starting with ./ or ../
    {
      regex = "\\.{1,2}/[\\w./\\-]+",
      format = "$0",
    },
  }
end

return M

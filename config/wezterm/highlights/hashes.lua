--- @module "highlights.hashes""
--- @description Git hash and UUID pattern rules.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local M = {}

--- Get hash/UUID hyperlink rules.
--- @return table rules Array of WezTerm hyperlink rules
function M.get_rules()
  return {
    -- Git commit hashes (7-40 hex chars, word-bounded)
    {
      regex = "\\b[0-9a-f]{7,40}\\b",
      format = "$0",
    },
    -- UUIDs
    {
      regex = "\\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\\b",
      format = "$0",
    },
  }
end

return M

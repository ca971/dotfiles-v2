--- @module "highlights.urls""
--- @description URL pattern hyperlink rules.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local M = {}

--- Get URL hyperlink rules.
--- @return table rules Array of WezTerm hyperlink rules
function M.get_rules()
  return {
    -- Standard HTTP/HTTPS URLs
    {
      regex = "https?://[\\w@:%.\\-~#=/\\?&;,!$*+]+",
      format = "$0",
    },
    -- File URLs
    {
      regex = "file://[\\w@:%.\\-~#=/\\?&]+",
      format = "$0",
    },
  }
end

return M

--- @module "highlights.ips""
--- @description IP address pattern rules.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local M = {}

--- Get IP address hyperlink rules.
--- @return table rules Array of WezTerm hyperlink rules
function M.get_rules()
  return {
    -- IPv4 addresses
    {
      regex = "\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}(:\\d{1,5})?\\b",
      format = "http://$0",
    },
  }
end

return M

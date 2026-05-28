--- @module "highlights""
--- @description Highlight and hyperlink rules aggregator.
--- Loads all highlight pattern modules and builds the combined
--- hyperlink rules configuration for WezTerm.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local LoggerModule = require("lib.logger")

--- @class Highlights
--- @field _VERSION string Module version
local Highlights = {
  _VERSION = "1.0.0",
}

--- @type table<number, string>
--- Highlight modules to load.
local HIGHLIGHT_MODULES = {
  "highlights.urls",
  "highlights.ips",
  "highlights.hashes",
  "highlights.paths",
  "highlights.errors",
  "highlights.custom",
}

--- Build the combined hyperlink rules configuration.
--- @return table config Config keys with hyperlink_rules
function Highlights.build()
  local log = LoggerModule.create("highlights")
  local all_rules = {}

  for _, module_path in ipairs(HIGHLIGHT_MODULES) do
    local ok, mod = pcall(require, module_path)
    if ok and type(mod) == "table" and type(mod.get_rules) == "function" then
      local rules = mod.get_rules()
      if type(rules) == "table" then
        for _, rule in ipairs(rules) do
          all_rules[#all_rules + 1] = rule
        end
      end
    else
      log:debug("Highlight module skipped", { module = module_path })
    end
  end

  log:info("Highlight rules built", { count = tostring(#all_rules) })

  return {
    hyperlink_rules = all_rules,
  }
end

return Highlights

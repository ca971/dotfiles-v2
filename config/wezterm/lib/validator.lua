--- @module "lib.validator""
--- @description Configuration validation engine.
--- Validates WezTerm configuration tables against defined schemas,
--- reports errors and warnings, suggests corrections, and ensures
--- type safety for all configuration values.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Class = require("lib.class")
local Guard = require("lib.guard")
local LoggerModule = require("lib.logger")

--- @class ValidationResult
--- @field valid boolean Whether validation passed
--- @field errors table<number, string> List of error messages
--- @field warnings table<number, string> List of warning messages

--- @class FieldRule
--- @field type string Expected Lua type
--- @field required? boolean Whether the field is required
--- @field default? any Default value if missing
--- @field min? number Minimum value (for numbers)
--- @field max? number Maximum value (for numbers)
--- @field min_length? number Minimum string length
--- @field max_length? number Maximum string length
--- @field one_of? table Array of allowed values
--- @field pattern? string Lua pattern to match (strings)
--- @field validator? fun(value: any): boolean, string? Custom validator function
--- @field description? string Human-readable description

--- @class ConfigValidator
--- @field _schemas table<string, table<string, FieldRule>> Registered schemas
--- @field _log Logger Logger instance
local ConfigValidator = Class.new("ConfigValidator")

--- Initialize the validator.
--- @param opts? table Options
function ConfigValidator:init(opts)
  opts = opts or {}
  self._schemas = {}
  self._log = LoggerModule.create("validator")
end

--- Register a validation schema.
--- @param name string Schema name
--- @param schema table<string, FieldRule> Field rules
--- @return ConfigValidator self For method chaining
function ConfigValidator:register(name, schema)
  Guard.is_non_empty_string(name, "name")
  Guard.is_table(schema, "schema")
  self._schemas[name] = schema
  self._log:debug("Schema registered", { name = name })
  return self
end

--- Validate a single field against a rule.
--- @param field_name string The field name
--- @param value any The field value
--- @param rule FieldRule The validation rule
--- @return boolean valid
--- @return table<number, string> errors
--- @return table<number, string> warnings
--- @private
function ConfigValidator:_validate_field(field_name, value, rule)
  local errors = {}
  local warnings = {}

  -- Required check
  if value == nil then
    if rule.required then
      errors[#errors + 1] = string.format("Required field '%s' is missing", field_name)
    end
    return #errors == 0, errors, warnings
  end

  -- Type check
  if rule.type then
    local expected_types = {}
    for t in rule.type:gmatch("[^|]+") do
      expected_types[#expected_types + 1] = t
    end

    local type_match = false
    for _, t in ipairs(expected_types) do
      if type(value) == t then
        type_match = true
        break
      end
    end

    if not type_match then
      errors[#errors + 1] = string.format(
        "Field '%s': expected type '%s', got '%s'",
        field_name,
        rule.type,
        type(value)
      )
      return false, errors, warnings
    end
  end

  -- Number range
  if type(value) == "number" then
    if rule.min and value < rule.min then
      errors[#errors + 1] = string.format(
        "Field '%s': value %s is below minimum %s",
        field_name,
        tostring(value),
        tostring(rule.min)
      )
    end
    if rule.max and value > rule.max then
      errors[#errors + 1] = string.format(
        "Field '%s': value %s exceeds maximum %s",
        field_name,
        tostring(value),
        tostring(rule.max)
      )
    end
  end

  -- String constraints
  if type(value) == "string" then
    if rule.min_length and #value < rule.min_length then
      errors[#errors + 1] = string.format(
        "Field '%s': string length %d is below minimum %d",
        field_name,
        #value,
        rule.min_length
      )
    end
    if rule.max_length and #value > rule.max_length then
      warnings[#warnings + 1] = string.format(
        "Field '%s': string length %d exceeds recommended maximum %d",
        field_name,
        #value,
        rule.max_length
      )
    end
    if rule.pattern and not value:match(rule.pattern) then
      errors[#errors + 1] = string.format(
        "Field '%s': value '%s' does not match pattern '%s'",
        field_name,
        value,
        rule.pattern
      )
    end
  end

  -- Enum check
  if rule.one_of then
    local found = false
    for _, allowed in ipairs(rule.one_of) do
      if value == allowed then
        found = true
        break
      end
    end
    if not found then
      local allowed_str = table.concat(
        (function()
          local strs = {}
          for _, v in ipairs(rule.one_of) do
            strs[#strs + 1] = tostring(v)
          end
          return strs
        end)(),
        ", "
      )
      errors[#errors + 1] = string.format(
        "Field '%s': value '%s' must be one of [%s]",
        field_name,
        tostring(value),
        allowed_str
      )
    end
  end

  -- Custom validator
  if rule.validator then
    local ok, err = rule.validator(value)
    if not ok then
      errors[#errors + 1] =
        string.format("Field '%s': %s", field_name, err or "custom validation failed")
    end
  end

  return #errors == 0, errors, warnings
end

--- Validate a config table against a registered schema.
--- @param schema_name string The schema name
--- @param config table The configuration to validate
--- @return ValidationResult result The validation result
function ConfigValidator:validate(schema_name, config)
  Guard.is_non_empty_string(schema_name, "schema_name")
  Guard.is_table(config, "config")

  local schema = self._schemas[schema_name]
  if not schema then
    return {
      valid = false,
      errors = { string.format("Unknown schema '%s'", schema_name) },
      warnings = {},
    }
  end

  local all_errors = {}
  local all_warnings = {}

  for field_name, rule in pairs(schema) do
    local value = config[field_name]
    local _, errors, warnings = self:_validate_field(field_name, value, rule)

    for _, e in ipairs(errors) do
      all_errors[#all_errors + 1] = e
    end
    for _, w in ipairs(warnings) do
      all_warnings[#all_warnings + 1] = w
    end
  end

  --- @type ValidationResult
  local result = {
    valid = #all_errors == 0,
    errors = all_errors,
    warnings = all_warnings,
  }

  -- Log results
  if not result.valid then
    self._log:warn("Configuration validation failed", {
      schema = schema_name,
      error_count = tostring(#result.errors),
    })
    for _, err in ipairs(result.errors) do
      self._log:error("  " .. err)
    end
  else
    self._log:debug("Configuration validation passed", {
      schema = schema_name,
      warnings = tostring(#result.warnings),
    })
  end

  for _, warn in ipairs(result.warnings) do
    self._log:warn("  " .. warn)
  end

  return result
end

--- Apply defaults from a schema to a config table.
--- Missing fields with defaults will be populated.
--- @param schema_name string The schema name
--- @param config table The configuration to fill defaults
--- @return table config The config with defaults applied
function ConfigValidator:apply_defaults(schema_name, config)
  Guard.is_non_empty_string(schema_name, "schema_name")
  Guard.is_table(config, "config")

  local schema = self._schemas[schema_name]
  if not schema then
    self._log:warn("Cannot apply defaults: unknown schema", { schema = schema_name })
    return config
  end

  for field_name, rule in pairs(schema) do
    if config[field_name] == nil and rule.default ~= nil then
      config[field_name] = rule.default
    end
  end

  return config
end

--- Validate and apply defaults in one step.
--- @param schema_name string The schema name
--- @param config table The configuration
--- @return table config The config with defaults
--- @return ValidationResult result Validation result
function ConfigValidator:validate_and_apply(schema_name, config)
  config = self:apply_defaults(schema_name, config)
  local result = self:validate(schema_name, config)
  return config, result
end

--- List registered schemas.
--- @return table<number, string> names Array of schema names
function ConfigValidator:list_schemas()
  local names = {}
  for name, _ in pairs(self._schemas) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

---------------------------------------------------------------------------
-- Module API
---------------------------------------------------------------------------

--- @class ValidatorModule
local M = {
  ConfigValidator = ConfigValidator,
  _instance = nil,
}

--- Get or create the singleton validator.
--- @return ConfigValidator validator The singleton instance
function M.get_validator()
  if not M._instance then
    M._instance = ConfigValidator()
  end
  return M._instance
end

--- Register a schema on the singleton.
--- @param name string Schema name
--- @param schema table<string, FieldRule> Field rules
function M.register(name, schema)
  M.get_validator():register(name, schema)
end

--- Validate using the singleton.
--- @param schema_name string Schema name
--- @param config table Config to validate
--- @return ValidationResult result
function M.validate(schema_name, config)
  return M.get_validator():validate(schema_name, config)
end

--- Reset singleton (for testing).
function M.reset()
  M._instance = nil
end

return M

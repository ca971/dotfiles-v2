--- @module "lib.guard""
--- @description Defensive programming utilities for runtime validation.
--- Provides type assertions, nil checks, range validation, enum validation,
--- and pattern matching guards with descriptive error messages.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

--- @class Guard
--- @field _VERSION string Module version
local Guard = {
  _VERSION = "1.0.0",
}

--- Assert that a value is not nil.
--- @param value any The value to check
--- @param name? string The variable name for error messages
--- @return any value The value if not nil
function Guard.not_nil(value, name)
  if value == nil then
    error(string.format("Expected '%s' to be non-nil", name or "value"), 2)
  end
  return value
end

--- Assert that a value is of a specific type.
--- @param value any The value to check
--- @param expected_type string The expected type (e.g. "string", "table")
--- @param name? string The variable name for error messages
--- @return any value The value if type matches
function Guard.is_type(value, expected_type, name)
  if type(value) ~= expected_type then
    error(
      string.format(
        "Expected '%s' to be of type '%s', got '%s'",
        name or "value",
        expected_type,
        type(value)
      ),
      2
    )
  end
  return value
end

--- Assert that a value is a string.
--- @param value any The value to check
--- @param name? string The variable name for error messages
--- @return string value The string value
function Guard.is_string(value, name)
  return Guard.is_type(value, "string", name)
end

--- Assert that a value is a number.
--- @param value any The value to check
--- @param name? string The variable name for error messages
--- @return number value The number value
function Guard.is_number(value, name)
  return Guard.is_type(value, "number", name)
end

--- Assert that a value is a table.
--- @param value any The value to check
--- @param name? string The variable name for error messages
--- @return table value The table value
function Guard.is_table(value, name)
  return Guard.is_type(value, "table", name)
end

--- Assert that a value is a function.
--- @param value any The value to check
--- @param name? string The variable name for error messages
--- @return function value The function value
function Guard.is_function(value, name)
  return Guard.is_type(value, "function", name)
end

--- Assert that a value is a boolean.
--- @param value any The value to check
--- @param name? string The variable name for error messages
--- @return boolean value The boolean value
function Guard.is_boolean(value, name)
  return Guard.is_type(value, "boolean", name)
end

--- Assert that a value is a non-empty string.
--- @param value any The value to check
--- @param name? string The variable name for error messages
--- @return string value The non-empty string
function Guard.is_non_empty_string(value, name)
  Guard.is_string(value, name)
  if #value == 0 then
    error(string.format("Expected '%s' to be a non-empty string", name or "value"), 2)
  end
  return value
end

--- Assert that a number is within a range [min, max].
--- @param value number The value to check
--- @param min number Minimum allowed value
--- @param max number Maximum allowed value
--- @param name? string The variable name for error messages
--- @return number value The value if in range
function Guard.in_range(value, min, max, name)
  Guard.is_number(value, name)
  if value < min or value > max then
    error(
      string.format(
        "Expected '%s' to be in range [%s, %s], got %s",
        name or "value",
        tostring(min),
        tostring(max),
        tostring(value)
      ),
      2
    )
  end
  return value
end

--- Assert that a value is one of the allowed values (enum check).
--- @param value any The value to check
--- @param allowed table Array of allowed values
--- @param name? string The variable name for error messages
--- @return any value The value if it's in the allowed list
function Guard.one_of(value, allowed, name)
  for _, v in ipairs(allowed) do
    if v == value then
      return value
    end
  end
  error(
    string.format(
      "Expected '%s' to be one of [%s], got '%s'",
      name or "value",
      table.concat(
        (function()
          local strs = {}
          for _, v in ipairs(allowed) do
            strs[#strs + 1] = tostring(v)
          end
          return strs
        end)(),
        ", "
      ),
      tostring(value)
    ),
    2
  )
end

--- Assert that a string matches a Lua pattern.
--- @param value string The string to check
--- @param pattern string The Lua pattern
--- @param name? string The variable name for error messages
--- @return string value The string if it matches
function Guard.matches(value, pattern, name)
  Guard.is_string(value, name)
  if not value:match(pattern) then
    error(
      string.format(
        "Expected '%s' to match pattern '%s', got '%s'",
        name or "value",
        pattern,
        value
      ),
      2
    )
  end
  return value
end

--- Assert that a table is non-empty.
--- @param value table The table to check
--- @param name? string The variable name for error messages
--- @return table value The non-empty table
function Guard.is_non_empty_table(value, name)
  Guard.is_table(value, name)
  if next(value) == nil then
    error(string.format("Expected '%s' to be a non-empty table", name or "value"), 2)
  end
  return value
end

--- Assert a condition with a custom message.
--- @param condition any The condition (truthy = pass)
--- @param message string The error message if condition is falsy
--- @return any condition The condition value if truthy
function Guard.assert(condition, message)
  if not condition then
    error(message or "Guard assertion failed", 2)
  end
  return condition
end

--- Coalesce: return the first non-nil value.
--- @param ... any Values to check
--- @return any value The first non-nil value
function Guard.coalesce(...)
  local args = { ... }
  for i = 1, select("#", ...) do
    if args[i] ~= nil then
      return args[i]
    end
  end
  return nil
end

--- Safe call: execute a function and return success + result or error.
--- @param fn function The function to call
--- @param ... any Arguments to pass
--- @return boolean success True if no error
--- @return any result The return value or error message
function Guard.safe_call(fn, ...)
  Guard.is_function(fn, "fn")
  return pcall(fn, ...)
end

--- Require a value with a default fallback.
--- @param value any The value to check
--- @param default any The default if value is nil
--- @return any result The value or default
function Guard.default(value, default)
  if value == nil then
    return default
  end
  return value
end

--- Validate a table against a schema of expected types.
--- @param tbl table The table to validate
--- @param schema table<string, string> Map of field_name -> expected_type
--- @param name? string Table name for error messages
--- @return table tbl The validated table
function Guard.validate_schema(tbl, schema, name)
  Guard.is_table(tbl, name)
  Guard.is_table(schema, "schema")
  local label = name or "table"

  for field, expected in pairs(schema) do
    local value = tbl[field]
    -- Handle "type|nil" syntax for optional fields
    if expected:match("|nil$") then
      if value ~= nil then
        local base_type = expected:gsub("|nil$", "")
        if type(value) ~= base_type then
          error(
            string.format(
              "Field '%s.%s' expected type '%s', got '%s'",
              label,
              field,
              expected,
              type(value)
            ),
            2
          )
        end
      end
    else
      if value == nil then
        error(
          string.format("Required field '%s.%s' is missing (expected '%s')", label, field, expected),
          2
        )
      end
      if type(value) ~= expected then
        error(
          string.format(
            "Field '%s.%s' expected type '%s', got '%s'",
            label,
            field,
            expected,
            type(value)
          ),
          2
        )
      end
    end
  end

  return tbl
end

return Guard

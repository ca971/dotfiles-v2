--- @module "lib.table_utils""
--- @description Comprehensive table utility functions for deep operations.
--- Provides deep_merge, deep_clone, freeze, flatten, keys, values,
--- map, filter, reduce, and equality checks.
--- All functions are pure (no side effects on inputs) unless stated otherwise.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

--- @class TableUtils
--- @field _VERSION string Module version
local TableUtils = {
  _VERSION = "1.0.0",
}

--- Deep clone a value (recursively copies tables).
--- Handles circular references via a seen-table.
--- @param value any The value to clone
--- @param seen? table Internal tracker for circular references
--- @return any clone The deep-cloned value
function TableUtils.deep_clone(value, seen)
  if type(value) ~= "table" then
    return value
  end

  seen = seen or {}
  if seen[value] then
    return seen[value]
  end

  local clone = {}
  seen[value] = clone

  for k, v in pairs(value) do
    clone[TableUtils.deep_clone(k, seen)] = TableUtils.deep_clone(v, seen)
  end

  local mt = getmetatable(value)
  if mt then
    setmetatable(clone, mt)
  end

  return clone
end

--- Deep merge multiple source tables into a new table.
--- Later sources override earlier ones. Tables are merged recursively;
--- non-table values are overwritten.
--- @param ... table Source tables to merge (left to right priority)
--- @return table merged A new merged table
function TableUtils.deep_merge(...)
  local sources = { ... }
  local result = {}

  for _, source in ipairs(sources) do
    if type(source) == "table" then
      for k, v in pairs(source) do
        if
          type(v) == "table"
          and type(result[k]) == "table"
          and not v[1] -- Don't merge arrays, replace them
        then
          result[k] = TableUtils.deep_merge(result[k], v)
        else
          result[k] = TableUtils.deep_clone(v)
        end
      end
    end
  end

  return result
end

--- Shallow merge (single level) multiple tables into a new table.
--- @param ... table Source tables
--- @return table merged A new shallow-merged table
function TableUtils.shallow_merge(...)
  local sources = { ... }
  local result = {}
  for _, source in ipairs(sources) do
    if type(source) == "table" then
      for k, v in pairs(source) do
        result[k] = v
      end
    end
  end
  return result
end

--- Freeze a table (make it read-only) recursively.
--- Any attempt to modify the table will raise an error.
--- @param tbl table The table to freeze
--- @param name? string Optional name for error messages
--- @return table frozen The frozen (proxied) table
function TableUtils.freeze(tbl, name)
  assert(type(tbl) == "table", "freeze() expects a table")
  local label = name or "frozen table"

  local frozen = {}
  for k, v in pairs(tbl) do
    if type(v) == "table" then
      frozen[k] = TableUtils.freeze(v, label .. "." .. tostring(k))
    else
      frozen[k] = v
    end
  end

  return setmetatable({}, {
    __index = frozen,
    __newindex = function(_, key, _)
      error(string.format("Attempt to modify read-only field '%s' on %s", tostring(key), label), 2)
    end,
    __pairs = function(_)
      return pairs(frozen)
    end,
    __ipairs = function(_)
      return ipairs(frozen)
    end,
    __len = function(_)
      return #frozen
    end,
    __tostring = function(_)
      return string.format("Frozen<%s>", label)
    end,
  })
end

--- Get all keys from a table.
--- @param tbl table The source table
--- @return table keys Array of keys
function TableUtils.keys(tbl)
  assert(type(tbl) == "table", "keys() expects a table")
  local result = {}
  for k, _ in pairs(tbl) do
    result[#result + 1] = k
  end
  return result
end

--- Get all values from a table.
--- @param tbl table The source table
--- @return table values Array of values
function TableUtils.values(tbl)
  assert(type(tbl) == "table", "values() expects a table")
  local result = {}
  for _, v in pairs(tbl) do
    result[#result + 1] = v
  end
  return result
end

--- Check if a table contains a specific value.
--- @param tbl table The table to search
--- @param target any The value to find
--- @return boolean found True if the value exists
function TableUtils.contains(tbl, target)
  if type(tbl) ~= "table" then
    return false
  end
  for _, v in pairs(tbl) do
    if v == target then
      return true
    end
  end
  return false
end

--- Map a function over table values (returns new table).
--- @param tbl table The source table (array-like)
--- @param fn fun(value: any, index: number): any The transform function
--- @return table mapped New array with transformed values
function TableUtils.map(tbl, fn)
  assert(type(tbl) == "table", "map() expects a table")
  assert(type(fn) == "function", "map() expects a function")
  local result = {}
  for i, v in ipairs(tbl) do
    result[i] = fn(v, i)
  end
  return result
end

--- Filter table values (returns new table).
--- @param tbl table The source table (array-like)
--- @param fn fun(value: any, index: number): boolean The predicate
--- @return table filtered New array with values that pass the predicate
function TableUtils.filter(tbl, fn)
  assert(type(tbl) == "table", "filter() expects a table")
  assert(type(fn) == "function", "filter() expects a function")
  local result = {}
  for i, v in ipairs(tbl) do
    if fn(v, i) then
      result[#result + 1] = v
    end
  end
  return result
end

--- Reduce a table to a single value.
--- @param tbl table The source table (array-like)
--- @param fn fun(acc: any, value: any, index: number): any The reducer
--- @param initial any The initial accumulator value
--- @return any result The reduced value
function TableUtils.reduce(tbl, fn, initial)
  assert(type(tbl) == "table", "reduce() expects a table")
  assert(type(fn) == "function", "reduce() expects a function")
  local acc = initial
  for i, v in ipairs(tbl) do
    acc = fn(acc, v, i)
  end
  return acc
end

--- Flatten a nested table (arrays only) to a single level.
--- @param tbl table The nested array
--- @param depth? number Maximum depth to flatten (default: infinite)
--- @return table flat The flattened array
function TableUtils.flatten(tbl, depth)
  assert(type(tbl) == "table", "flatten() expects a table")
  depth = depth or math.huge
  local result = {}

  local function _flatten(t, d)
    for _, v in ipairs(t) do
      if type(v) == "table" and d > 0 then
        _flatten(v, d - 1)
      else
        result[#result + 1] = v
      end
    end
  end

  _flatten(tbl, depth)
  return result
end

--- Deep equality check between two values.
--- @param a any First value
--- @param b any Second value
--- @return boolean equal True if deeply equal
function TableUtils.deep_equal(a, b)
  if type(a) ~= type(b) then
    return false
  end
  if type(a) ~= "table" then
    return a == b
  end

  -- Check all keys in a exist in b with equal values
  for k, v in pairs(a) do
    if not TableUtils.deep_equal(v, b[k]) then
      return false
    end
  end
  -- Check b has no extra keys
  for k, _ in pairs(b) do
    if a[k] == nil then
      return false
    end
  end

  return true
end

--- Get a nested value from a table using a dot-separated path.
--- @param tbl table The source table
--- @param path string Dot-separated path (e.g. "a.b.c")
--- @param default? any Default value if path not found
--- @return any value The value at the path or default
function TableUtils.get(tbl, path, default)
  if type(tbl) ~= "table" or type(path) ~= "string" then
    return default
  end

  local current = tbl
  for segment in path:gmatch("[^%.]+") do
    if type(current) ~= "table" then
      return default
    end
    current = current[segment]
    if current == nil then
      return default
    end
  end

  return current
end

--- Set a nested value in a table using a dot-separated path.
--- Creates intermediate tables as needed.
--- @param tbl table The target table (modified in place)
--- @param path string Dot-separated path
--- @param value any The value to set
--- @return table tbl The modified table
function TableUtils.set(tbl, path, value)
  assert(type(tbl) == "table", "set() expects a table")
  assert(type(path) == "string" and #path > 0, "set() expects a non-empty path")

  local segments = {}
  for segment in path:gmatch("[^%.]+") do
    segments[#segments + 1] = segment
  end

  local current = tbl
  for i = 1, #segments - 1 do
    local seg = segments[i]
    if type(current[seg]) ~= "table" then
      current[seg] = {}
    end
    current = current[seg]
  end

  current[segments[#segments]] = value
  return tbl
end

--- Count the number of entries in a table (works for non-array tables).
--- @param tbl table The table to count
--- @return number count Number of key-value pairs
function TableUtils.count(tbl)
  if type(tbl) ~= "table" then
    return 0
  end
  local n = 0
  for _ in pairs(tbl) do
    n = n + 1
  end
  return n
end

--- Check if a table is empty.
--- @param tbl table The table to check
--- @return boolean empty True if table has no entries
function TableUtils.is_empty(tbl)
  if type(tbl) ~= "table" then
    return true
  end
  return next(tbl) == nil
end

--- Pick specific keys from a table.
--- @param tbl table The source table
--- @param keys_list table Array of keys to pick
--- @return table picked New table with only the specified keys
function TableUtils.pick(tbl, keys_list)
  assert(type(tbl) == "table", "pick() expects a table")
  local result = {}
  for _, k in ipairs(keys_list) do
    if tbl[k] ~= nil then
      result[k] = tbl[k]
    end
  end
  return result
end

--- Omit specific keys from a table.
--- @param tbl table The source table
--- @param keys_list table Array of keys to omit
--- @return table result New table without the specified keys
function TableUtils.omit(tbl, keys_list)
  assert(type(tbl) == "table", "omit() expects a table")
  local omit_set = {}
  for _, k in ipairs(keys_list) do
    omit_set[k] = true
  end
  local result = {}
  for k, v in pairs(tbl) do
    if not omit_set[k] then
      result[k] = v
    end
  end
  return result
end

return TableUtils

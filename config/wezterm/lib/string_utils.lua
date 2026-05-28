--- @module "lib.string_utils""
--- @description Comprehensive string utility functions.
--- Provides trim, split, pad, truncate, template interpolation,
--- case conversion, and pattern-based helpers.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

--- @class StringUtils
--- @field _VERSION string Module version
local StringUtils = {
  _VERSION = "1.0.0",
}

--- Trim whitespace from both ends of a string.
--- @param s string The input string
--- @return string trimmed The trimmed string
function StringUtils.trim(s)
  if type(s) ~= "string" then
    return ""
  end
  return s:match("^%s*(.-)%s*$") or ""
end

--- Trim whitespace from the left side.
--- @param s string The input string
--- @return string trimmed The left-trimmed string
function StringUtils.ltrim(s)
  if type(s) ~= "string" then
    return ""
  end
  return s:match("^%s*(.*)$") or ""
end

--- Trim whitespace from the right side.
--- @param s string The input string
--- @return string trimmed The right-trimmed string
function StringUtils.rtrim(s)
  if type(s) ~= "string" then
    return ""
  end
  return s:match("^(.-)%s*$") or ""
end

--- Split a string by a delimiter.
--- @param s string The input string
--- @param delimiter? string The delimiter pattern (default: "%s+")
--- @return table parts Array of substrings
function StringUtils.split(s, delimiter)
  if type(s) ~= "string" then
    return {}
  end
  delimiter = delimiter or "%s+"
  local parts = {}

  if delimiter == "" then
    for i = 1, #s do
      parts[#parts + 1] = s:sub(i, i)
    end
    return parts
  end

  local pattern = string.format("([^%s]+)", delimiter:gsub("%%", ""))
  -- Use a more robust approach for literal delimiters
  local search_start = 1
  local delim_start, delim_end = s:find(delimiter, search_start, true)

  if not delim_start then
    -- Try as pattern
    for part in s:gmatch("([^" .. delimiter .. "]+)") do
      parts[#parts + 1] = part
    end
    if #parts == 0 and #s > 0 then
      parts[1] = s
    end
    return parts
  end

  while delim_start do
    local part = s:sub(search_start, delim_start - 1)
    if #part > 0 then
      parts[#parts + 1] = part
    end
    search_start = delim_end + 1
    delim_start, delim_end = s:find(delimiter, search_start, true)
  end

  local last = s:sub(search_start)
  if #last > 0 then
    parts[#parts + 1] = last
  end

  return parts
end

--- Join an array of strings with a separator.
--- @param parts table Array of strings
--- @param separator? string The separator (default: "")
--- @return string joined The joined string
function StringUtils.join(parts, separator)
  if type(parts) ~= "table" then
    return ""
  end
  separator = separator or ""
  return table.concat(parts, separator)
end

--- Check if a string starts with a prefix.
--- @param s string The input string
--- @param prefix string The prefix to check
--- @return boolean starts True if s starts with prefix
function StringUtils.starts_with(s, prefix)
  if type(s) ~= "string" or type(prefix) ~= "string" then
    return false
  end
  return s:sub(1, #prefix) == prefix
end

--- Check if a string ends with a suffix.
--- @param s string The input string
--- @param suffix string The suffix to check
--- @return boolean ends True if s ends with suffix
function StringUtils.ends_with(s, suffix)
  if type(s) ~= "string" or type(suffix) ~= "string" then
    return false
  end
  return suffix == "" or s:sub(-#suffix) == suffix
end

--- Pad a string on the left to reach a target length.
--- @param s string The input string
--- @param length number The target length
--- @param char? string The padding character (default: " ")
--- @return string padded The left-padded string
function StringUtils.lpad(s, length, char)
  s = tostring(s or "")
  char = char or " "
  local padding = length - #s
  if padding <= 0 then
    return s
  end
  return string.rep(char, padding) .. s
end

--- Pad a string on the right to reach a target length.
--- @param s string The input string
--- @param length number The target length
--- @param char? string The padding character (default: " ")
--- @return string padded The right-padded string
function StringUtils.rpad(s, length, char)
  s = tostring(s or "")
  char = char or " "
  local padding = length - #s
  if padding <= 0 then
    return s
  end
  return s .. string.rep(char, padding)
end

--- Center a string within a given width.
--- @param s string The input string
--- @param width number The total width
--- @param char? string The padding character (default: " ")
--- @return string centered The centered string
function StringUtils.center(s, width, char)
  s = tostring(s or "")
  char = char or " "
  local padding = width - #s
  if padding <= 0 then
    return s
  end
  local left = math.floor(padding / 2)
  local right = padding - left
  return string.rep(char, left) .. s .. string.rep(char, right)
end

--- Truncate a string to a maximum length with an ellipsis.
--- Handles multi-byte ellipsis characters correctly.
--- @param s string The input string
--- @param max_length number Maximum length including ellipsis
--- @param ellipsis? string The ellipsis string (default: "...")
--- @return string truncated The truncated string
function StringUtils.truncate(s, max_length, ellipsis)
  if type(s) ~= "string" then
    return ""
  end
  ellipsis = ellipsis or "..."
  if #s <= max_length then
    return s
  end
  local ellipsis_len = #ellipsis
  local truncated_len = max_length - ellipsis_len
  if truncated_len < 0 then
    truncated_len = 0
  end
  return s:sub(1, truncated_len) .. ellipsis
end

--- Simple template interpolation using ${key} placeholders.
--- @param template string The template string with ${key} placeholders
--- @param vars table<string, any> Variables to interpolate
--- @return string result The interpolated string
function StringUtils.interpolate(template, vars)
  if type(template) ~= "string" then
    return ""
  end
  vars = vars or {}
  return template:gsub("%${([^}]+)}", function(key)
    local val = vars[key]
    if val ~= nil then
      return tostring(val)
    end
    return "${" .. key .. "}"
  end)
end

--- Convert a string to snake_case.
--- @param s string The input string
--- @return string snake The snake_case string
function StringUtils.to_snake_case(s)
  if type(s) ~= "string" then
    return ""
  end
  local result = s:gsub("::", "/")
    :gsub("(%u+)(%u%l)", "%1_%2")
    :gsub("(%l)(%u)", "%1_%2")
    :gsub("%-", "_")
    :gsub("%s+", "_")
    :lower()
  return result
end

--- Convert a string to camelCase.
--- @param s string The input string (snake_case or kebab-case)
--- @return string camel The camelCase string
function StringUtils.to_camel_case(s)
  if type(s) ~= "string" then
    return ""
  end
  local result = s:gsub("[_%-](%w)", function(c)
    return c:upper()
  end)
  return result:sub(1, 1):lower() .. result:sub(2)
end

--- Check if a string is empty or only whitespace.
--- @param s string|nil The input string
--- @return boolean blank True if nil, empty, or whitespace-only
function StringUtils.is_blank(s)
  if type(s) ~= "string" then
    return true
  end
  return s:match("^%s*$") ~= nil
end

--- Escape special Lua pattern characters in a string.
--- @param s string The input string
--- @return string escaped The pattern-escaped string
function StringUtils.escape_pattern(s)
  if type(s) ~= "string" then
    return ""
  end
  return s:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

--- Count occurrences of a substring.
--- @param s string The input string
--- @param sub string The substring to count
--- @return number count Number of occurrences
function StringUtils.count(s, sub)
  if type(s) ~= "string" or type(sub) ~= "string" or #sub == 0 then
    return 0
  end
  local n = 0
  local start = 1
  while true do
    local pos = s:find(sub, start, true)
    if not pos then
      break
    end
    n = n + 1
    start = pos + 1
  end
  return n
end

--- Capitalize the first letter of each word.
--- @param s string The input string
--- @return string titled The title-cased string
function StringUtils.title_case(s)
  if type(s) ~= "string" then
    return ""
  end
  return s:gsub("(%a)([%w_']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end)
end

return StringUtils

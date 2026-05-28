--- @module "lib.path""
--- @description Cross-platform path manipulation utilities.
--- Handles path joining, normalization, home directory expansion,
--- separator detection, and config directory resolution
--- across Linux, macOS, Windows, BSD, and WSL.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Guard = require("lib.guard")

---------------------------------------------------------------------------
-- Safe WezTerm access helper
---------------------------------------------------------------------------

--- Safely attempt to load the wezterm module.
--- Returns the module table only if it's a real wezterm module.
--- @return table|nil wezterm The wezterm module or nil
local function get_wezterm()
  local ok, mod = pcall(require, "wezterm")
  if ok and type(mod) == "table" then
    return mod
  end
  return nil
end

--- @class Path
--- @field _VERSION string Module version
--- @field separator string OS path separator
--- @field is_windows boolean Whether running on Windows
local Path = {
  _VERSION = "1.0.0",
}

---------------------------------------------------------------------------
-- Platform detection (minimal, no circular deps with lib.platform)
---------------------------------------------------------------------------

--- Detect if running on Windows.
--- @return boolean is_windows True if on Windows
local function detect_windows()
  local sep = package.config:sub(1, 1)
  return sep == "\\"
end

Path.is_windows = detect_windows()
Path.separator = Path.is_windows and "\\" or "/"

---------------------------------------------------------------------------
-- Core path operations
---------------------------------------------------------------------------

--- Normalize a path: resolve separators and remove redundant slashes.
--- @param p string The path to normalize
--- @return string normalized The normalized path
function Path.normalize(p)
  if type(p) ~= "string" or #p == 0 then
    return ""
  end

  -- Unify separators
  local result = p:gsub("\\", "/")

  -- Remove redundant slashes (preserve leading // for UNC on Windows)
  result = result:gsub("//+", "/")

  -- Remove trailing slash (unless it's root)
  if #result > 1 and result:sub(-1) == "/" then
    result = result:sub(1, -2)
  end

  -- Convert back to OS separator if on Windows
  if Path.is_windows then
    result = result:gsub("/", "\\")
  end

  return result
end

--- Join path segments with the appropriate separator.
--- @param ... string Path segments to join
--- @return string joined The joined and normalized path
function Path.join(...)
  local segments = {}
  local args = { ... }

  for _, seg in ipairs(args) do
    if type(seg) == "string" and #seg > 0 then
      segments[#segments + 1] = seg
    end
  end

  if #segments == 0 then
    return ""
  end

  local joined = table.concat(segments, "/")
  return Path.normalize(joined)
end

--- Get the directory part of a path.
--- @param p string The full path
--- @return string dir The directory portion
function Path.dirname(p)
  if type(p) ~= "string" or #p == 0 then
    return "."
  end

  local normalized = p:gsub("\\", "/")
  local dir = normalized:match("^(.+)/[^/]*$")

  if not dir then
    return "."
  end

  if Path.is_windows then
    dir = dir:gsub("/", "\\")
  end

  return dir
end

--- Get the filename part of a path.
--- @param p string The full path
--- @return string basename The filename portion
function Path.basename(p)
  if type(p) ~= "string" or #p == 0 then
    return ""
  end

  local normalized = p:gsub("\\", "/")
  return normalized:match("([^/]+)$") or p
end

--- Get the file extension (with dot).
--- @param p string The file path
--- @return string ext The extension including dot, or empty string
function Path.extension(p)
  local base = Path.basename(p)
  return base:match("(%.[^%.]+)$") or ""
end

--- Expand ~ to the user's home directory.
--- @param p string The path potentially starting with ~
--- @return string expanded The expanded path
function Path.expand_home(p)
  if type(p) ~= "string" then
    return ""
  end

  if p:sub(1, 1) ~= "~" then
    return p
  end

  local home = Path.get_home()
  if p == "~" then
    return home
  end

  if p:sub(1, 2) == "~/" or p:sub(1, 2) == "~\\" then
    return Path.join(home, p:sub(3))
  end

  return p
end

--- Get the user's home directory.
--- @return string home The home directory path
function Path.get_home()
  local home = os.getenv("HOME")
    or os.getenv("USERPROFILE")
    or os.getenv("HOMEDRIVE") and (os.getenv("HOMEDRIVE") .. (os.getenv("HOMEPATH") or ""))
    or ""

  return Path.normalize(home)
end

--- Get the WezTerm configuration directory.
--- @return string config_dir The config directory path
function Path.get_config_dir()
  -- WezTerm provides this via its API
  local wez = get_wezterm()
  if wez and wez.config_dir then
    return Path.normalize(wez.config_dir)
  end

  -- Fallback: standard XDG/platform locations
  local xdg = os.getenv("XDG_CONFIG_HOME")
  if xdg then
    return Path.join(xdg, "wezterm")
  end

  if Path.is_windows then
    local appdata = os.getenv("APPDATA") or os.getenv("USERPROFILE")
    if appdata then
      return Path.join(appdata, ".config", "wezterm")
    end
  end

  return Path.join(Path.get_home(), ".config", "wezterm")
end

--- Get the local overrides directory.
--- @return string local_dir Path to the local/ directory
function Path.get_local_dir()
  return Path.join(Path.get_config_dir(), "local")
end

--- Check if a file exists and is readable.
--- Uses a portable approach compatible with Lua 5.4.
--- @param filepath string The file path to check
--- @return boolean exists True if file exists and is readable
function Path.file_exists(filepath)
  if type(filepath) ~= "string" then
    return false
  end

  -- Try WezTerm's glob first
  local wez = get_wezterm()
  if wez and wez.glob then
    local success, matches = pcall(wez.glob, filepath)
    return success and matches and #matches > 0
  end

  -- Fallback: try to open the file
  local f = io.open(filepath, "r")
  if f then
    f:close()
    return true
  end
  return false
end

--- Check if a directory exists.
--- @param dirpath string The directory path to check
--- @return boolean exists True if directory exists
function Path.dir_exists(dirpath)
  if type(dirpath) ~= "string" then
    return false
  end

  -- Try WezTerm's glob with trailing separator
  local wez = get_wezterm()
  if wez and wez.glob then
    local pattern = Path.join(dirpath, "*")
    local success, _ = pcall(wez.glob, pattern)
    if success then
      return true
    end
  end

  -- Fallback approach
  local test_path = Path.join(dirpath, ".")
  local f = io.open(test_path, "r")
  if f then
    f:close()
    return true
  end

  return false
end

--- Shorten a path by abbreviating parent directories.
--- For example: /home/user/.config/wezterm -> ~/.c/wezterm
--- @param p string The path to shorten
--- @param max_length? number Maximum length (default: 30)
--- @return string shortened The shortened path
function Path.shorten(p, max_length)
  if type(p) ~= "string" then
    return ""
  end
  max_length = max_length or 30

  -- Replace home with ~
  local home = Path.get_home()
  local shortened = p
  if home and #home > 0 then
    local escaped_home = home:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
    shortened = shortened:gsub("^" .. escaped_home, "~")
  end

  if #shortened <= max_length then
    return shortened
  end

  -- Abbreviate intermediate directories to first character
  local parts = {}
  for part in shortened:gmatch("[^/\\]+") do
    parts[#parts + 1] = part
  end

  if #parts <= 1 then
    return shortened
  end

  -- Keep first (~ or root indicator) and last, abbreviate middle
  local result = {}
  for i, part in ipairs(parts) do
    if i == #parts then
      result[#result + 1] = part
    elseif i == 1 and (part == "~" or part:match("^%a:$")) then
      result[#result + 1] = part
    else
      result[#result + 1] = part:sub(1, 1)
    end
  end

  return table.concat(result, Path.is_windows and "\\" or "/")
end

--- Convert a module path (dot notation) to a file path.
--- @param module_path string Dot-separated module path (e.g. "lib.logger")
--- @return string file_path The filesystem path
function Path.from_module(module_path)
  Guard.is_non_empty_string(module_path, "module_path")
  local file_path = module_path:gsub("%.", Path.separator)
  return file_path .. ".lua"
end

return Path

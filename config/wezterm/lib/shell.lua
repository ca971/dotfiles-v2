--- @module "lib.shell""
--- @description Shell detection and configuration provider.
--- Detects available shells on the system, identifies the user's default
--- and preferred shell, and provides launch arguments for each shell type.
--- Supports zsh, fish, bash, nushell, pwsh, and cmd across all platforms.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Class = require("lib.class")
local Guard = require("lib.guard")

--- @class ShellInfo
--- @field name string Shell identifier: "zsh"|"fish"|"bash"|"nushell"|"pwsh"|"cmd"|"unknown"
--- @field path string Full path to the shell executable
--- @field display_name string Human-readable name
--- @field args table Default launch arguments
--- @field is_login boolean Whether to launch as login shell

--- @class ShellDetector
--- @field _platform_info table Platform info from lib.platform
--- @field _available table<string, ShellInfo> Detected available shells
--- @field _default ShellInfo|nil The detected default shell
local ShellDetector = Class.new("ShellDetector")

---------------------------------------------------------------------------
-- Shell definitions
---------------------------------------------------------------------------

--- @type table<string, table>
--- Shell metadata templates per shell type.
local SHELL_DEFS = {
  zsh = {
    display_name = "Zsh",
    bins = { "/bin/zsh", "/usr/bin/zsh", "/usr/local/bin/zsh", "/opt/homebrew/bin/zsh" },
    win_bins = {},
    args = { "-l" },
    is_login = true,
  },
  fish = {
    display_name = "Fish",
    bins = { "/usr/bin/fish", "/usr/local/bin/fish", "/opt/homebrew/bin/fish" },
    win_bins = {},
    args = { "-l" },
    is_login = true,
  },
  bash = {
    display_name = "Bash",
    bins = { "/bin/bash", "/usr/bin/bash", "/usr/local/bin/bash", "/opt/homebrew/bin/bash" },
    win_bins = { "C:\\Program Files\\Git\\bin\\bash.exe" },
    args = { "-l" },
    is_login = true,
  },
  nushell = {
    display_name = "Nushell",
    bins = { "/usr/bin/nu", "/usr/local/bin/nu", "/opt/homebrew/bin/nu" },
    win_bins = {},
    args = { "--login" },
    is_login = true,
  },
  pwsh = {
    display_name = "PowerShell",
    bins = { "/usr/bin/pwsh", "/usr/local/bin/pwsh", "/opt/homebrew/bin/pwsh" },
    win_bins = {
      "C:\\Program Files\\PowerShell\\7\\pwsh.exe",
      "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
    },
    args = { "-NoLogo" },
    is_login = false,
  },
  cmd = {
    display_name = "Command Prompt",
    bins = {},
    win_bins = { "C:\\Windows\\System32\\cmd.exe" },
    args = {},
    is_login = false,
  },
}

---------------------------------------------------------------------------
-- Internal helpers
---------------------------------------------------------------------------

--- Check if a file exists.
--- @param filepath string Path to check
--- @return boolean exists
local function file_exists(filepath)
  local f = io.open(filepath, "r")
  if f then
    f:close()
    return true
  end
  return false
end

--- Find a shell binary from candidate paths.
--- @param candidates table Array of file paths to check
--- @return string|nil path The first existing path or nil
local function find_binary(candidates)
  for _, path in ipairs(candidates) do
    if file_exists(path) then
      return path
    end
  end
  return nil
end

--- Detect shell name from a path string.
--- @param shell_path string The shell path (e.g. "/bin/zsh")
--- @return string name The shell name or "unknown"
local function identify_shell(shell_path)
  if type(shell_path) ~= "string" then
    return "unknown"
  end

  local lower = shell_path:lower()

  if lower:match("zsh") then
    return "zsh"
  end
  if lower:match("fish") then
    return "fish"
  end
  if lower:match("bash") then
    return "bash"
  end
  if lower:match("nu") and not lower:match("nul") then
    return "nushell"
  end
  if lower:match("pwsh") or lower:match("powershell") then
    return "pwsh"
  end
  if lower:match("cmd") then
    return "cmd"
  end

  return "unknown"
end

---------------------------------------------------------------------------
-- ShellDetector methods
---------------------------------------------------------------------------

--- Initialize the shell detector.
--- @param platform_info? table Platform info (from lib.platform.detect())
function ShellDetector:init(platform_info)
  self._platform_info = platform_info or {}
  self._available = {}
  self._default = nil
  self._detected = false
end

--- Detect all available shells on the system.
--- @return ShellDetector self For method chaining
function ShellDetector:detect()
  local is_windows = self._platform_info.os == "windows"

  for name, def in pairs(SHELL_DEFS) do
    local candidates = is_windows and def.win_bins or def.bins
    local found_path = find_binary(candidates)

    -- Also try `which` / `where` as fallback
    if not found_path then
      local cmd = is_windows and ("where " .. name .. " 2>nul")
        or ("which " .. name .. " 2>/dev/null")
      local handle = io.popen(cmd)
      if handle then
        local result = handle:read("*l")
        handle:close()
        if result and #result > 0 and file_exists(result) then
          found_path = result
        end
      end
    end

    if found_path then
      --- @type ShellInfo
      self._available[name] = {
        name = name,
        path = found_path,
        display_name = def.display_name,
        args = def.args or {},
        is_login = def.is_login,
      }
    end
  end

  -- Detect default shell
  self:_detect_default()
  self._detected = true

  return self
end

--- Detect the user's default shell.
--- @private
function ShellDetector:_detect_default()
  local shell_env = os.getenv("SHELL") or os.getenv("COMSPEC") or ""
  local shell_name = identify_shell(shell_env)

  if shell_name ~= "unknown" and self._available[shell_name] then
    self._default = self._available[shell_name]
    return
  end

  -- Priority order for fallback
  local priority = { "zsh", "fish", "bash", "nushell", "pwsh", "cmd" }
  for _, name in ipairs(priority) do
    if self._available[name] then
      self._default = self._available[name]
      return
    end
  end
end

--- Ensure detection has been run.
--- @private
function ShellDetector:_ensure_detected()
  if not self._detected then
    self:detect()
  end
end

--- Get the default shell.
--- @return ShellInfo|nil shell The default shell info
function ShellDetector:get_default()
  self:_ensure_detected()
  return self._default
end

--- Get all available shells.
--- @return table<string, ShellInfo> shells Map of shell name to info
function ShellDetector:get_available()
  self:_ensure_detected()
  return self._available
end

--- Get a specific shell by name.
--- @param name string Shell name (e.g. "zsh", "fish")
--- @return ShellInfo|nil shell The shell info or nil
function ShellDetector:get(name)
  self:_ensure_detected()
  Guard.is_non_empty_string(name, "name")
  return self._available[name:lower()]
end

--- Check if a specific shell is available.
--- @param name string Shell name to check
--- @return boolean available True if the shell is installed
function ShellDetector:has(name)
  self:_ensure_detected()
  return self._available[name:lower()] ~= nil
end

--- Get shell names as an ordered list.
--- @return table<number, string> names Array of available shell names
function ShellDetector:list()
  self:_ensure_detected()
  local names = {}
  for name, _ in pairs(self._available) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

--- Build a WezTerm launch_menu entry for a shell.
--- @param name string Shell name
--- @param label? string Custom label
--- @return table|nil entry WezTerm launch menu entry or nil
function ShellDetector:build_launch_entry(name, label)
  local shell = self:get(name)
  if not shell then
    return nil
  end

  return {
    label = label or shell.display_name,
    args = { shell.path, table.unpack(shell.args) },
  }
end

--- Build launch menu entries for all available shells.
--- @return table entries Array of WezTerm launch menu entries
function ShellDetector:build_launch_menu()
  self:_ensure_detected()
  local entries = {}
  local order = { "zsh", "fish", "bash", "nushell", "pwsh", "cmd" }

  for _, name in ipairs(order) do
    local entry = self:build_launch_entry(name)
    if entry then
      entries[#entries + 1] = entry
    end
  end

  return entries
end

---------------------------------------------------------------------------
-- Module API
---------------------------------------------------------------------------

--- @class ShellModule
local M = {
  ShellDetector = ShellDetector,
  _instance = nil,
}

--- Get or create a singleton ShellDetector instance.
--- @param platform_info? table Platform info
--- @return ShellDetector detector The singleton detector
function M.get_detector(platform_info)
  if not M._instance then
    M._instance = ShellDetector(platform_info)
  end
  return M._instance
end

--- Quick-detect the default shell.
--- @param platform_info? table Platform info
--- @return ShellInfo|nil shell The default shell
function M.get_default(platform_info)
  return M.get_detector(platform_info):get_default()
end

--- Reset the singleton (for testing).
function M.reset()
  M._instance = nil
end

return M

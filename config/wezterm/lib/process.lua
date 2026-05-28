--- @module "lib.process""
--- @description Process and executable detection system.
--- Detects installed CLI tools, runtimes, and services.
--- Uses caching to avoid repeated filesystem/process lookups.
--- Provides version detection and availability checks.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local CacheModule = require("lib.cache")
local Class = require("lib.class")

--- @class ExecutableInfo
--- @field name string Executable name
--- @field path string|nil Full path to executable
--- @field available boolean Whether the executable was found
--- @field version string|nil Detected version string
--- @field category string Category: "runtime"|"tool"|"shell"|"service"

--- @class ProcessDetector
--- @field _cache Cache Cache instance for detection results
--- @field _platform_info table Platform info
local ProcessDetector = Class.new("ProcessDetector")

---------------------------------------------------------------------------
-- Executable definitions with version commands
---------------------------------------------------------------------------

--- @type table<string, table>
--- Registry of known executables with detection metadata.
local EXECUTABLES = {
  -- Runtimes
  node = {
    category = "runtime",
    display = "Node.js",
    version_cmd = "node --version",
    version_pattern = "v?(%d+%.%d+%.%d+)",
  },
  python = {
    category = "runtime",
    display = "Python",
    names = { "python3", "python" },
    version_cmd = "python3 --version 2>&1 || python --version 2>&1",
    version_pattern = "(%d+%.%d+%.%d+)",
  },
  ruby = {
    category = "runtime",
    display = "Ruby",
    version_cmd = "ruby --version",
    version_pattern = "ruby (%d+%.%d+%.%d+)",
  },
  go = {
    category = "runtime",
    display = "Go",
    version_cmd = "go version",
    version_pattern = "go(%d+%.%d+%.?%d*)",
  },
  rust = {
    category = "runtime",
    display = "Rust",
    names = { "rustc" },
    version_cmd = "rustc --version",
    version_pattern = "rustc (%d+%.%d+%.%d+)",
  },
  java = {
    category = "runtime",
    display = "Java",
    version_cmd = "java -version 2>&1",
    version_pattern = '"(%d+%.%d+%.%d+)"',
  },
  deno = {
    category = "runtime",
    display = "Deno",
    version_cmd = "deno --version",
    version_pattern = "deno (%d+%.%d+%.%d+)",
  },
  bun = {
    category = "runtime",
    display = "Bun",
    version_cmd = "bun --version",
    version_pattern = "(%d+%.%d+%.%d+)",
  },
  lua = {
    category = "runtime",
    display = "Lua",
    names = { "lua5.4", "lua5.3", "lua" },
    version_cmd = "lua -v 2>&1",
    version_pattern = "Lua (%d+%.%d+%.?%d*)",
  },

  -- Nix
  nix = {
    category = "runtime",
    display = "Nix",
    version_cmd = "nix --version",
    version_pattern = "nix .* (%d+%.%d+%.?%d*)",
  },

  -- Tools
  tmux = {
    category = "tool",
    display = "tmux",
    version_cmd = "tmux -V",
    version_pattern = "tmux (%d+%.%d+%w*)",
  },
  docker = {
    category = "tool",
    display = "Docker",
    version_cmd = "docker --version",
    version_pattern = "(%d+%.%d+%.%d+)",
  },
  podman = {
    category = "tool",
    display = "Podman",
    version_cmd = "podman --version",
    version_pattern = "(%d+%.%d+%.%d+)",
  },
  kubectl = {
    category = "tool",
    display = "kubectl",
    version_cmd = "kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null",
    version_pattern = "v?(%d+%.%d+%.%d+)",
  },
  ["docker-compose"] = {
    category = "tool",
    display = "Compose",
    names = { "docker-compose", "docker" },
    version_cmd = "docker compose version 2>/dev/null || docker-compose --version 2>/dev/null",
    version_pattern = "v?(%d+%.%d+%.%d+)",
  },
  helm = {
    category = "tool",
    display = "Helm",
    version_cmd = "helm version --short",
    version_pattern = "v?(%d+%.%d+%.%d+)",
  },
  terraform = {
    category = "tool",
    display = "Terraform",
    version_cmd = "terraform version",
    version_pattern = "v(%d+%.%d+%.%d+)",
  },
  git = {
    category = "tool",
    display = "Git",
    version_cmd = "git --version",
    version_pattern = "(%d+%.%d+%.%d+)",
  },
  nvim = {
    category = "tool",
    display = "Neovim",
    version_cmd = "nvim --version",
    version_pattern = "v(%d+%.%d+%.%d+)",
  },
  curl = {
    category = "tool",
    display = "cURL",
    version_cmd = "curl --version",
    version_pattern = "curl (%d+%.%d+%.%d+)",
  },
}

---------------------------------------------------------------------------
-- Internal helpers
---------------------------------------------------------------------------

--- Execute a command and capture output.
--- @param cmd string Shell command
--- @return string|nil output Trimmed output or nil
local function exec(cmd)
  local handle = io.popen(cmd .. " 2>/dev/null")
  if not handle then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  if result then
    result = result:match("^%s*(.-)%s*$")
    if #result > 0 then
      return result
    end
  end
  return nil
end

--- Find an executable using which/where.
--- @param name string Executable name
--- @param is_windows boolean Whether on Windows
--- @return string|nil path Full path or nil
local function find_executable(name, is_windows)
  local cmd = is_windows and string.format("where %s 2>nul", name)
    or string.format("which %s 2>/dev/null", name)

  local result = exec(cmd)
  if result then
    -- `which` might return multiple lines; take the first
    return result:match("^([^\n\r]+)")
  end
  return nil
end

---------------------------------------------------------------------------
-- ProcessDetector methods
---------------------------------------------------------------------------

--- Initialize the process detector.
--- @param opts? table Options
--- @field opts.platform_info? table Platform detection info
--- @field opts.cache_ttl? number Cache TTL in seconds (default: 300)
function ProcessDetector:init(opts)
  opts = opts or {}
  self._platform_info = opts.platform_info or {}
  local ttl = opts.cache_ttl or 300 -- 5 minutes
  self._cache = CacheModule.get("process", { default_ttl = ttl })
end

--- Detect a single executable.
--- @param name string The executable name (key in EXECUTABLES or raw binary name)
--- @return ExecutableInfo info Detection result
function ProcessDetector:detect(name)
  -- Check cache first
  local cache_key = "exec:" .. name
  if self._cache:has(cache_key) then
    return self._cache:get(cache_key)
  end

  local def = EXECUTABLES[name]
  local is_windows = self._platform_info.os == "windows"

  --- @type ExecutableInfo
  local info = {
    name = name,
    path = nil,
    available = false,
    version = nil,
    category = def and def.category or "unknown",
    display = def and def.display or name,
  }

  -- Determine binary names to search
  local names_to_try = { name }
  if def and def.names then
    names_to_try = def.names
  end

  -- Find the executable
  for _, bin_name in ipairs(names_to_try) do
    local path = find_executable(bin_name, is_windows)
    if path then
      info.path = path
      info.available = true
      break
    end
  end

  -- Get version if available and executable was found
  if info.available and def and def.version_cmd then
    local output = exec(def.version_cmd)
    if output and def.version_pattern then
      info.version = output:match(def.version_pattern)
    end
  end

  -- Cache the result
  self._cache:set(cache_key, info)
  return info
end

--- Detect multiple executables at once.
--- @param names table Array of executable names
--- @return table<string, ExecutableInfo> results Map of name to info
function ProcessDetector:detect_many(names)
  local results = {}
  for _, name in ipairs(names) do
    results[name] = self:detect(name)
  end
  return results
end

--- Detect all known executables in a category.
--- @param category string Category: "runtime"|"tool"|"shell"|"service"
--- @return table<string, ExecutableInfo> results Map of name to info
function ProcessDetector:detect_category(category)
  local results = {}
  for name, def in pairs(EXECUTABLES) do
    if def.category == category then
      results[name] = self:detect(name)
    end
  end
  return results
end

--- Detect all runtimes.
--- @return table<string, ExecutableInfo> results Runtime detection results
function ProcessDetector:detect_runtimes()
  return self:detect_category("runtime")
end

--- Detect all tools.
--- @return table<string, ExecutableInfo> results Tool detection results
function ProcessDetector:detect_tools()
  return self:detect_category("tool")
end

--- Check if a specific executable is available.
--- @param name string The executable name
--- @return boolean available True if found on the system
function ProcessDetector:is_available(name)
  local info = self:detect(name)
  return info.available
end

--- Get the version of an executable.
--- @param name string The executable name
--- @return string|nil version The version string or nil
function ProcessDetector:get_version(name)
  local info = self:detect(name)
  return info.version
end

--- Get a formatted summary of detected items.
--- @param category? string Optional category filter
--- @return string summary Human-readable summary
function ProcessDetector:summary(category)
  local items = category and self:detect_category(category)
    or self:detect_many((function()
      local all = {}
      for name, _ in pairs(EXECUTABLES) do
        all[#all + 1] = name
      end
      return all
    end)())

  local parts = {}
  for name, info in pairs(items) do
    if info.available then
      local version_str = info.version and (" v" .. info.version) or ""
      parts[#parts + 1] = string.format("%s%s", info.display or name, version_str)
    end
  end

  table.sort(parts)
  return table.concat(parts, ", ")
end

--- Invalidate cache for a specific executable or all.
--- @param name? string Executable name (nil = clear all)
function ProcessDetector:invalidate(name)
  if name then
    self._cache:remove("exec:" .. name)
  else
    self._cache:clear()
  end
end

---------------------------------------------------------------------------
-- Module API
---------------------------------------------------------------------------

--- @class ProcessModule
local M = {
  ProcessDetector = ProcessDetector,
  EXECUTABLES = EXECUTABLES,
  _instance = nil,
}

--- Get or create the singleton ProcessDetector.
--- @param opts? table Options
--- @return ProcessDetector detector The singleton instance
function M.get_detector(opts)
  if not M._instance then
    M._instance = ProcessDetector(opts)
  end
  return M._instance
end

--- Quick check if an executable is available.
--- @param name string Executable name
--- @return boolean available
function M.has(name)
  return M.get_detector():is_available(name)
end

--- Quick version check.
--- @param name string Executable name
--- @return string|nil version
function M.version(name)
  return M.get_detector():get_version(name)
end

--- Reset singleton (for testing).
function M.reset()
  M._instance = nil
  CacheModule.get("process"):clear()
end

return M

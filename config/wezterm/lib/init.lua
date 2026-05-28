--- @module "lib""
--- @description Library namespace loader and facade.
--- Provides centralized access to all shared utility modules.
--- Implements lazy loading to minimize startup overhead —
--- modules are only loaded when first accessed.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

--- @class Lib
--- @field class ClassSystem OOP class system
--- @field table_utils TableUtils Table utility functions
--- @field string_utils StringUtils String utility functions
--- @field guard Guard Defensive programming utilities
--- @field logger LoggerModule Structured logging system
--- @field path Path Cross-platform path utilities
--- @field platform Platform Platform detection
--- @field shell ShellModule Shell detection and configuration
--- @field cache CacheModule Caching and memoization
--- @field process ProcessModule Process/executable detection
--- @field secrets SecretsModule Secrets management
--- @field validator ValidatorModule Configuration validation
--- @field event_emitter EventEmitterModule Event bus system

--- Module registry for lazy loading.
--- Maps field name -> module path (relative to lib/).
--- @type table<string, string>
local MODULE_MAP = {
  class = "lib.class",
  table_utils = "lib.table_utils",
  string_utils = "lib.string_utils",
  guard = "lib.guard",
  logger = "lib.logger",
  path = "lib.path",
  platform = "lib.platform",
  shell = "lib.shell",
  cache = "lib.cache",
  process = "lib.process",
  secrets = "lib.secrets",
  validator = "lib.validator",
  event_emitter = "lib.event_emitter",
}

--- @type table<string, any>
--- Cache for already-loaded modules.
local _loaded = {}

--- @type Lib
local Lib = {}

--- Lazy-loading metatable: loads modules on first access.
setmetatable(Lib, {
  __index = function(self, key)
    -- Check if already loaded
    if _loaded[key] then
      return _loaded[key]
    end

    -- Check if this is a known module
    local module_path = MODULE_MAP[key]
    if not module_path then
      return nil
    end

    -- Load the module
    local ok, mod = pcall(require, module_path)
    if not ok then
      -- Log error but don't crash — return nil and let caller handle
      local err_msg = string.format(
        "[lib] Failed to load module '%s' from '%s': %s",
        key,
        module_path,
        tostring(mod)
      )
      -- Use raw print since logger might not be loaded yet
      print(err_msg)
      return nil
    end

    -- Cache and return
    _loaded[key] = mod
    rawset(self, key, mod)
    return mod
  end,

  __tostring = function(_)
    local loaded_names = {}
    for name, _ in pairs(_loaded) do
      loaded_names[#loaded_names + 1] = name
    end
    table.sort(loaded_names)

    local total = 0
    for _ in pairs(MODULE_MAP) do
      total = total + 1
    end

    return string.format(
      "Lib<%d/%d modules loaded: [%s]>",
      #loaded_names,
      total,
      table.concat(loaded_names, ", ")
    )
  end,
})

--- Preload all modules eagerly (useful for validation/testing).
--- @return Lib self The lib namespace with all modules loaded
function Lib.preload_all()
  for name, _ in pairs(MODULE_MAP) do
    local _ = Lib[name] -- Triggers lazy load
  end
  return Lib
end

--- Check if a specific module is loaded.
--- @param name string Module name
--- @return boolean loaded True if the module has been loaded
function Lib.is_loaded(name)
  return _loaded[name] ~= nil
end

--- List all available module names.
--- @return table<number, string> names Sorted array of module names
function Lib.available()
  local names = {}
  for name, _ in pairs(MODULE_MAP) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

--- List currently loaded module names.
--- @return table<number, string> names Sorted array of loaded module names
function Lib.loaded()
  local names = {}
  for name, _ in pairs(_loaded) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

--- Get the lib version info.
--- @return table version Version information
function Lib.version()
  return {
    name = "wezterm-enterprise-lib",
    version = "1.0.0",
    modules = #Lib.available(),
  }
end

--- Reset all loaded modules (for testing only).
--- @return nil
function Lib.reset()
  for name, _ in pairs(_loaded) do
    rawset(Lib, name, nil)
  end
  _loaded = {}
end

return Lib

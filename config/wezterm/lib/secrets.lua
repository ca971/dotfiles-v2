--- @module "lib.secrets""
--- @description Secure secrets management for WezTerm configuration.
--- Supports loading secrets from environment variables, local files,
--- and OS-specific keychains/credential stores. Secrets are never
--- logged or serialized to disk by the configuration itself.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Class = require("lib.class")
local Guard = require("lib.guard")
local LoggerModule = require("lib.logger")
local Path = require("lib.path")

--- @class Secret
--- @field key string The secret identifier
--- @field value string The secret value (sensitive)
--- @field source string Where the secret was loaded from
--- @field loaded_at number Timestamp when loaded

--- @class SecretsManager
--- @field _secrets table<string, Secret> Loaded secrets store
--- @field _sources table<string, boolean> Enabled secret sources
--- @field _log Logger Logger instance (never logs secret values)
local SecretsManager = Class.new("SecretsManager")

--- Redacted placeholder for logging.
--- @type string
local REDACTED = "********"

---------------------------------------------------------------------------
-- SecretsManager methods
---------------------------------------------------------------------------

--- Initialize the secrets manager.
--- @param opts? table Configuration options
--- @field opts.sources? table<string, boolean> Enable/disable sources
--- @field opts.env_prefix? string Environment variable prefix (default: "WEZTERM_")
--- @field opts.local_file? string Path to local secrets file
function SecretsManager:init(opts)
  opts = opts or {}
  self._secrets = {}
  self._env_prefix = opts.env_prefix or "WEZTERM_"
  self._log = LoggerModule.create("secrets")

  self._sources = {
    env = true,
    localfile = true,
    keychain = false, -- Opt-in for OS keychain
  }

  if opts.sources then
    for k, v in pairs(opts.sources) do
      self._sources[k] = v
    end
  end

  self._local_file = opts.local_file or Path.join(Path.get_local_dir(), "secrets.lua")
end

--- Load a secret from environment variables.
--- @param key string The secret key (will be prefixed)
--- @return string|nil value The secret value or nil
--- @private
function SecretsManager:_load_from_env(key)
  -- Try with prefix
  local prefixed_key = self._env_prefix .. key:upper():gsub("[^%w]", "_")
  local value = os.getenv(prefixed_key)

  if not value then
    -- Try without prefix
    value = os.getenv(key:upper():gsub("[^%w]", "_"))
  end

  if value and #value > 0 then
    self._log:debug("Secret loaded from environment", { key = key, source = "env" })
    return value
  end

  return nil
end

--- Load secrets from the local secrets file.
--- The file should return a table of key-value pairs.
--- @return table<string, string> secrets Loaded secrets
--- @private
function SecretsManager:_load_from_file()
  if not Path.file_exists(self._local_file) then
    self._log:debug("No local secrets file found", { path = self._local_file })
    return {}
  end

  local ok, result = pcall(dofile, self._local_file)
  if not ok then
    self._log:warn("Failed to load local secrets file", {
      path = self._local_file,
      error = tostring(result),
    })
    return {}
  end

  if type(result) ~= "table" then
    self._log:warn("Local secrets file did not return a table", {
      path = self._local_file,
    })
    return {}
  end

  self._log:debug("Loaded secrets from file", {
    path = self._local_file,
    count = tostring(#(function()
      local keys = {}
      for k in pairs(result) do
        keys[#keys + 1] = k
      end
      return keys
    end)()),
  })

  return result
end

--- Load a secret from macOS Keychain.
--- @param key string The keychain item label
--- @return string|nil value The secret value or nil
--- @private
function SecretsManager:_load_from_keychain(key)
  local service = "wezterm"
  local cmd =
    string.format('security find-generic-password -s "%s" -a "%s" -w 2>/dev/null', service, key)

  local handle = io.popen(cmd)
  if not handle then
    return nil
  end

  local result = handle:read("*a")
  handle:close()

  if result then
    result = result:match("^%s*(.-)%s*$")
    if #result > 0 then
      self._log:debug("Secret loaded from keychain", { key = key, source = "keychain" })
      return result
    end
  end

  return nil
end

--- Load all secrets from all enabled sources.
--- Environment variables take precedence over file values.
--- @return SecretsManager self For method chaining
function SecretsManager:load_all()
  -- 1. Load from file first (lowest priority)
  if self._sources.localfile then
    local file_secrets = self:_load_from_file()
    for key, value in pairs(file_secrets) do
      if type(value) == "string" and #value > 0 then
        self._secrets[key] = {
          key = key,
          value = value,
          source = "localfile",
          loaded_at = os.time(),
        }
      end
    end
  end

  -- 2. Environment variables override (highest priority)
  -- We don't enumerate all env vars; they're loaded on-demand via get()

  self._log:info("Secrets manager initialized", {
    sources = table.concat(
      (function()
        local enabled = {}
        for k, v in pairs(self._sources) do
          if v then
            enabled[#enabled + 1] = k
          end
        end
        return enabled
      end)(),
      ","
    ),
  })

  return self
end

--- Get a secret by key. Checks sources in priority order.
--- @param key string The secret key
--- @param default? string Default value if not found
--- @return string|nil value The secret value or default
function SecretsManager:get(key, default)
  Guard.is_non_empty_string(key, "key")

  -- 1. Check in-memory store first
  local cached = self._secrets[key]
  if cached then
    return cached.value
  end

  -- 2. Try environment (highest priority, always checked live)
  if self._sources.env then
    local env_value = self:_load_from_env(key)
    if env_value then
      self._secrets[key] = {
        key = key,
        value = env_value,
        source = "env",
        loaded_at = os.time(),
      }
      return env_value
    end
  end

  -- 3. Try keychain (if enabled)
  if self._sources.keychain then
    local keychain_value = self:_load_from_keychain(key)
    if keychain_value then
      self._secrets[key] = {
        key = key,
        value = keychain_value,
        source = "keychain",
        loaded_at = os.time(),
      }
      return keychain_value
    end
  end

  self._log:debug("Secret not found", { key = key })
  return default
end

--- Check if a secret exists (without returning its value).
--- @param key string The secret key
--- @return boolean exists True if the secret is available
function SecretsManager:has(key)
  return self:get(key) ~= nil
end

--- Set a secret in memory (runtime only, never persisted).
--- @param key string The secret key
--- @param value string The secret value
--- @return SecretsManager self For method chaining
function SecretsManager:set(key, value)
  Guard.is_non_empty_string(key, "key")
  Guard.is_string(value, "value")

  self._secrets[key] = {
    key = key,
    value = value,
    source = "runtime",
    loaded_at = os.time(),
  }

  self._log:debug("Secret set at runtime", { key = key, source = "runtime" })
  return self
end

--- List all loaded secret keys (never exposes values).
--- @return table<number, table> keys Array of {key, source} tables
function SecretsManager:list()
  local result = {}
  for key, secret in pairs(self._secrets) do
    result[#result + 1] = {
      key = key,
      source = secret.source,
      loaded_at = secret.loaded_at,
    }
  end
  table.sort(result, function(a, b)
    return a.key < b.key
  end)
  return result
end

--- Clear all secrets from memory.
--- @return SecretsManager self For method chaining
function SecretsManager:clear()
  self._secrets = {}
  self._log:info("All secrets cleared from memory")
  return self
end

--- Get a sanitized representation (for debugging, never shows values).
--- @return string repr A safe string representation
function SecretsManager:__tostring()
  local count = 0
  for _ in pairs(self._secrets) do
    count = count + 1
  end
  return string.format("SecretsManager<%d secrets loaded>", count)
end

---------------------------------------------------------------------------
-- Module API
---------------------------------------------------------------------------

--- @class SecretsModule
local M = {
  SecretsManager = SecretsManager,
  REDACTED = REDACTED,
  _instance = nil,
}

--- Get or create the singleton SecretsManager.
--- @param opts? table Options
--- @return SecretsManager manager The singleton instance
function M.get_manager(opts)
  if not M._instance then
    M._instance = SecretsManager(opts)
    M._instance:load_all()
  end
  return M._instance
end

--- Quick access to a secret.
--- @param key string Secret key
--- @param default? string Default value
--- @return string|nil value
function M.get(key, default)
  return M.get_manager():get(key, default)
end

--- Reset singleton (for testing).
function M.reset()
  if M._instance then
    M._instance:clear()
  end
  M._instance = nil
end

return M

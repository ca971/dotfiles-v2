--- @module "core.multiplexer""
--- @description Multiplexer domain configuration for SSH, TLS, and Unix domains.
--- Manages remote connection domains with secrets integration for
--- secure credential handling. Supports SSH jump hosts, port forwarding,
--- and domain-specific environment variables.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Guard = require("lib.guard")
local LoggerModule = require("lib.logger")
local SecretsModule = require("lib.secrets")
local Settings = require("core.settings")

--- @class Multiplexer
--- @field _VERSION string Module version
local Multiplexer = {
  _VERSION = "1.0.0",
}

--- @type Logger
local _log = nil

--- Lazy logger.
--- @return Logger
local function get_log()
  if not _log then
    _log = LoggerModule.create("multiplexer")
  end
  return _log
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Build SSH domain configurations.
--- Reads from settings and resolves secrets for credentials.
--- @return table domains Array of WezTerm SSH domain configs
function Multiplexer.build_ssh_domains(platform_info)
  local domains_config = Settings.get("multiplexer.ssh_domains", {})
  local domains = {}

  for _, domain_def in ipairs(domains_config) do
    if type(domain_def) == "table" and domain_def.name then
      local domain = {
        name = domain_def.name,
        remote_address = domain_def.remote_address or domain_def.host,
        username = domain_def.username,
        multiplexing = domain_def.multiplexing or "WezTerm",
        assume_shell = domain_def.assume_shell or "Posix",
        ssh_option = domain_def.ssh_option or {},
      }

      -- Resolve username from secrets if prefixed with "secret:"
      if domain.username and domain.username:match("^secret:") then
        local secret_key = domain.username:gsub("^secret:", "")
        domain.username = SecretsModule.get(secret_key, domain.username)
      end

      -- Resolve remote_address from secrets if needed
      if domain.remote_address and domain.remote_address:match("^secret:") then
        local secret_key = domain.remote_address:gsub("^secret:", "")
        domain.remote_address = SecretsModule.get(secret_key, domain.remote_address)
      end

      -- Remote directory
      if domain_def.remote_wezterm_path then
        domain.remote_wezterm_path = domain_def.remote_wezterm_path
      end

      domains[#domains + 1] = domain

      get_log():debug("SSH domain configured", {
        name = domain.name,
        address = domain.remote_address or "N/A",
      })
    end
  end

  get_log():info("SSH domains built", { count = tostring(#domains) })
  return domains
end

--- Build Unix domain configurations.
--- @return table domains Array of WezTerm Unix domain configs
function Multiplexer.build_unix_domains()
  local domains_config = Settings.get("multiplexer.unix_domains", {})
  local domains = {}

  for _, domain_def in ipairs(domains_config) do
    if type(domain_def) == "table" and domain_def.name then
      domains[#domains + 1] = {
        name = domain_def.name,
        socket_path = domain_def.socket_path,
        no_serve_automatically = domain_def.no_serve_automatically,
      }
    end
  end

  return domains
end

--- Build TLS domain configurations.
--- @return table domains Array of WezTerm TLS domain configs
function Multiplexer.build_tls_domains()
  local domains_config = Settings.get("multiplexer.tls_domains", {})
  local domains = {}

  for _, domain_def in ipairs(domains_config) do
    if type(domain_def) == "table" and domain_def.name then
      local domain = {
        name = domain_def.name,
        remote_address = domain_def.remote_address,
        bootstrap_via_ssh = domain_def.bootstrap_via_ssh,
      }

      -- Resolve certificates from secrets
      if domain_def.pem_private_key and domain_def.pem_private_key:match("^secret:") then
        local key = domain_def.pem_private_key:gsub("^secret:", "")
        domain.pem_private_key = SecretsModule.get(key)
      end

      if domain_def.pem_cert and domain_def.pem_cert:match("^secret:") then
        local key = domain_def.pem_cert:gsub("^secret:", "")
        domain.pem_cert = SecretsModule.get(key)
      end

      if domain_def.pem_ca and domain_def.pem_ca:match("^secret:") then
        local key = domain_def.pem_ca:gsub("^secret:", "")
        domain.pem_ca = SecretsModule.get(key)
      end

      domains[#domains + 1] = domain
    end
  end

  return domains
end

--- Build the complete multiplexer configuration.
--- @param platform_info? table Platform detection info
--- @return table config Multiplexer config keys to merge
function Multiplexer.build(platform_info)
  platform_info = platform_info or {}

  local config = {
    ssh_domains = Multiplexer.build_ssh_domains(platform_info),
    unix_domains = Multiplexer.build_unix_domains(),
    tls_clients = Multiplexer.build_tls_domains(),
  }

  get_log():info("Multiplexer configuration built", {
    ssh = tostring(#config.ssh_domains),
    unix = tostring(#config.unix_domains),
    tls = tostring(#config.tls_clients),
  })

  return config
end

return Multiplexer

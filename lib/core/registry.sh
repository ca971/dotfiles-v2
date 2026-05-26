#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/core/registry.sh
# @description OOP-style service registry and dependency resolver
# @class Registry
# @since 1.0.0
# @version 1.0.0
# @see docs/ARCHITECTURE.md
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────────────────────
# @field _REGISTRY_SERVICES
# @type associative array
# @description Maps service names to their source file paths
# ───────────────────────────────────────────────────────────────────────────────
declare -gA _REGISTRY_SERVICES=()

# ───────────────────────────────────────────────────────────────────────────────
# @field _REGISTRY_LOADED
# @type associative array
# @description Tracks which services have been sourced (prevents double-loading)
# ───────────────────────────────────────────────────────────────────────────────
declare -gA _REGISTRY_LOADED=()

# ═══════════════════════════════════════════════════════════════════════════════
# @description Register a service with its source file path
# @param $1 {string} Service name (e.g., "Platform", "Logger")
# @param $2 {string} Path to the source file
# @return 0 on success
# @example Registry::register "Platform" "lib/core/platform.sh"
# ═══════════════════════════════════════════════════════════════════════════════
Registry::register() {
    local name="${1:?Service name required}"
    local path="${2:?Source path required}"

    _REGISTRY_SERVICES["${name}"]="${path}"
    Logger::debug "Registry: registered service '${name}' -> ${path}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Load a registered service (source its file if not already loaded)
# @param $1 {string} Service name
# @return 0 on success, 1 if service not found
# ═══════════════════════════════════════════════════════════════════════════════
Registry::load() {
    local name="${1:?Service name required}"

    if [[ -n "${_REGISTRY_LOADED[${name}]:-}" ]]; then
        return 0
    fi

    local path="${_REGISTRY_SERVICES[${name}]:-}"
    if [[ -z "${path}" ]]; then
        Logger::error "Registry: unknown service '${name}'"
        return 1
    fi

    local full_path="${DOTFILES_DIR:-${HOME}/.dotfiles}/${path}"
    if [[ ! -f "${full_path}" ]]; then
        Logger::error "Registry: service file not found: ${full_path}"
        return 1
    fi

    # shellcheck source=/dev/null
    source "${full_path}"
    _REGISTRY_LOADED["${name}"]=1
    Logger::debug "Registry: loaded service '${name}'"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Load multiple services at once
# @param $@ {string} Service names
# @return 0 if all loaded, 1 if any fails
# @example Registry::load_all "Platform" "Logger" "FileSystem"
# ═══════════════════════════════════════════════════════════════════════════════
Registry::load_all() {
    local name
    for name in "$@"; do
        Registry::load "${name}" || return 1
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check if a service is registered
# @param $1 {string} Service name
# @return 0 if registered, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
Registry::has() {
    local name="${1:?Service name required}"
    [[ -n "${_REGISTRY_SERVICES[${name}]:-}" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check if a service is loaded (sourced)
# @param $1 {string} Service name
# @return 0 if loaded, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
Registry::is_loaded() {
    local name="${1:?Service name required}"
    [[ -n "${_REGISTRY_LOADED[${name}]:-}" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description List all registered services and their load status
# @return Prints service list to stdout
# ═══════════════════════════════════════════════════════════════════════════════
Registry::list() {
    local name
    echo "Registered services:"
    for name in "${!_REGISTRY_SERVICES[@]}"; do
        local status="not loaded"
        if [[ -n "${_REGISTRY_LOADED[${name}]:-}" ]]; then
            status="loaded"
        fi
        printf "  %-20s %-40s [%s]\n" "${name}" "${_REGISTRY_SERVICES[${name}]}" "${status}"
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Initialize the registry with all core services
# @return Registers all lib/core/ and lib/modules/ services
# ═══════════════════════════════════════════════════════════════════════════════
Registry::init() {
    Registry::register "Platform"    "lib/core/platform.sh"
    Registry::register "Shell"       "lib/core/shell.sh"
    Registry::register "Logger"      "lib/core/logger.sh"
    Registry::register "Validator"   "lib/core/validator.sh"
    Registry::register "FileSystem"  "lib/core/fs.sh"
    Registry::register "Network"     "lib/core/net.sh"
    Registry::register "Bootstrap"   "lib/modules/bootstrap.sh"
    Registry::register "Secrets"     "lib/modules/secrets.sh"
    Registry::register "Theme"       "lib/modules/theme.sh"
    Registry::register "Symlink"     "lib/modules/symlink.sh"
    Registry::register "Doctor"      "lib/modules/doctor.sh"
    Registry::register "HotLoad"     "lib/hotload/engine.sh"

    Logger::debug "Registry: initialized with core services"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Reset the registry (for testing purposes)
# @return Clears all registered and loaded services
# ═══════════════════════════════════════════════════════════════════════════════
Registry::reset() {
    _REGISTRY_SERVICES=()
    _REGISTRY_LOADED=()
}

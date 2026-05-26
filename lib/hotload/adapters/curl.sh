#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/hotload/adapters/curl.sh
# @description Curl/script installer adapter (priority 3)
# @class CurlAdapter
# @extends InstallerAdapter
# @since 1.0.0
# @version 1.0.0
#
# Executes custom install commands (curl scripts, wget, etc.)
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

CurlAdapter::is_available() {
    command -v curl >/dev/null 2>&1
}

CurlAdapter::install() {
    local _name="${1:?Tool name required}"
    local _version="${2:-latest}"
    local command="${3:?Install command required}"

    Logger::debug "CurlAdapter: running install command for ${_name}"
    eval "${command}" 2>&1 || return 1
    return 0
}

CurlAdapter::uninstall() {
    local _name="${1:?Tool name required}"
    local command="${2:-}"

    if [[ -z "${command}" ]]; then
        Logger::warn "CurlAdapter: no uninstall command for ${_name}"
        return 1
    fi

    Logger::debug "CurlAdapter: running uninstall command for ${_name}"
    eval "${command}" 2>&1 || return 1
    return 0
}

CurlAdapter::is_installed() {
    local name="${1:?Tool name required}"
    command -v "${name}" >/dev/null 2>&1
}

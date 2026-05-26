#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/hotload/adapters/uv.sh
# @description UV installer adapter for Python tools (priority 2)
# @class UvAdapter
# @extends InstallerAdapter
# @since 1.0.0
# @version 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

UvAdapter::is_available() {
    command -v uv >/dev/null 2>&1
}

UvAdapter::install() {
    local package="${1:?Package name required}"
    local version="${2:-}"

    Logger::debug "UvAdapter: installing ${package}"
    if [[ -n "${version}" ]] && [[ "${version}" != "latest" ]]; then
        uv tool install "${package}==${version}" 2>&1 || return 1
    else
        uv tool install "${package}" 2>&1 || return 1
    fi
    return 0
}

UvAdapter::uninstall() {
    local package="${1:?Package name required}"

    Logger::debug "UvAdapter: uninstalling ${package}"
    uv tool uninstall "${package}" 2>&1 || return 1
    return 0
}

UvAdapter::is_installed() {
    local package="${1:?Package name required}"
    uv tool list 2>/dev/null | grep -q "^${package} "
}

UvAdapter::get_version() {
    local package="${1:?Package name required}"
    uv tool list 2>/dev/null | grep "^${package} " | sed 's/.*v//'
}

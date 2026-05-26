#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/hotload/adapters/mise.sh
# @description Mise installer adapter (priority 1)
# @class MiseAdapter
# @extends InstallerAdapter
# @since 1.0.0
# @version 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

MiseAdapter::is_available() {
    command -v mise >/dev/null 2>&1
}

MiseAdapter::install() {
    local plugin="${1:?Plugin name required}"
    local version="${2:-latest}"

    Logger::debug "MiseAdapter: installing ${plugin}@${version}"
    mise install "${plugin}@${version}" 2>&1 || return 1
    mise use --global "${plugin}@${version}" 2>&1 || return 1
    return 0
}

MiseAdapter::uninstall() {
    local plugin="${1:?Plugin name required}"

    Logger::debug "MiseAdapter: uninstalling ${plugin}"
    mise uninstall "${plugin}" 2>&1 || return 1
    return 0
}

MiseAdapter::is_installed() {
    local plugin="${1:?Plugin name required}"
    mise ls --current 2>/dev/null | grep -q "^${plugin} " 2>/dev/null
}

MiseAdapter::get_version() {
    local plugin="${1:?Plugin name required}"
    mise ls --current 2>/dev/null | grep "^${plugin} " | awk '{print $2}'
}

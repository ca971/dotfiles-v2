#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/hotload/adapters/brew.sh
# @description Homebrew installer adapter — macOS fallback (priority 5)
# @class BrewAdapter
# @extends InstallerAdapter
# @since 1.0.0
# @version 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

BrewAdapter::is_available() {
    command -v brew >/dev/null 2>&1
}

BrewAdapter::install() {
    local package="${1:?Package name required}"
    local _version="${2:-}"

    Logger::debug "BrewAdapter: installing ${package}"
    brew install "${package}" 2>&1 || return 1
    return 0
}

BrewAdapter::uninstall() {
    local package="${1:?Package name required}"

    Logger::debug "BrewAdapter: uninstalling ${package}"
    brew uninstall "${package}" 2>&1 || return 1
    return 0
}

BrewAdapter::is_installed() {
    local package="${1:?Package name required}"
    brew list "${package}" >/dev/null 2>&1
}

BrewAdapter::get_version() {
    local package="${1:?Package name required}"
    brew list --versions "${package}" 2>/dev/null | awk '{print $2}'
}

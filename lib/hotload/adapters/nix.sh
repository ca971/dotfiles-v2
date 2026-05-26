#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/hotload/adapters/nix.sh
# @description Nix installer adapter (for Nix profile packages)
# @class NixAdapter
# @extends InstallerAdapter
# @since 1.0.0
# @version 1.0.0
# @see tools/nix/
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

NixAdapter::is_available() {
    command -v nix >/dev/null 2>&1
}

NixAdapter::install() {
    local package="${1:?Package required}"
    local _version="${2:-}"

    Logger::debug "NixAdapter: installing ${package}"
    nix profile install "nixpkgs#${package}" 2>&1 || return 1
    return 0
}

NixAdapter::uninstall() {
    local package="${1:?Package required}"

    Logger::debug "NixAdapter: uninstalling ${package}"
    nix profile remove "nixpkgs#${package}" 2>&1 || return 1
    return 0
}

NixAdapter::is_installed() {
    local package="${1:?Package required}"
    nix profile list 2>/dev/null | grep -q "${package}"
}

#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/hotload/adapters/cargo.sh
# @description Cargo installer adapter for Rust tools (priority 4)
# @class CargoAdapter
# @extends InstallerAdapter
# @since 1.0.0
# @version 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

CargoAdapter::is_available() {
    command -v cargo >/dev/null 2>&1
}

CargoAdapter::install() {
    local crate="${1:?Crate name required}"
    local version="${2:-}"

    Logger::debug "CargoAdapter: installing ${crate}"
    if [[ -n "${version}" ]] && [[ "${version}" != "latest" ]]; then
        cargo install "${crate}" --version "${version}" 2>&1 || return 1
    else
        cargo install "${crate}" 2>&1 || return 1
    fi
    return 0
}

CargoAdapter::uninstall() {
    local crate="${1:?Crate name required}"

    Logger::debug "CargoAdapter: uninstalling ${crate}"
    cargo uninstall "${crate}" 2>&1 || return 1
    return 0
}

CargoAdapter::is_installed() {
    local crate="${1:?Crate name required}"
    cargo install --list 2>/dev/null | grep -q "^${crate} "
}

#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file tools/nix/uninstall.sh
# @description Clean Nix removal (Determinate Systems uninstaller)
# @since 1.0.0
# @version 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

source "${DOTFILES_DIR}/lib/core/logger.sh"

main() {
    Logger::warn "This will completely remove Nix from your system."
    read -rp "Are you sure? [y/N] " confirm
    if [[ "${confirm}" != [yY] ]]; then
        Logger::info "Aborted."
        return 0
    fi

    Logger::info "Uninstalling Nix..."
    /nix/nix-installer uninstall 2>/dev/null || {
        Logger::warn "Determinate installer not found, trying manual removal..."
        sudo rm -rf /nix
        sudo rm -f /etc/nix
        rm -rf "${HOME}/.nix-profile"
        rm -rf "${HOME}/.nix-defexpr"
        rm -rf "${HOME}/.nix-channels"
        rm -rf "${XDG_DATA_HOME:-${HOME}/.local/share}/nix"
    }

    Logger::success "Nix uninstalled"
}

main

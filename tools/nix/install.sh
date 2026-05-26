#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file tools/nix/install.sh
# @description Nix daemon installer (Determinate Systems installer)
# @since 1.0.0
# @version 1.0.0
# @see https://github.com/DeterminateSystems/nix-installer
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

source "${DOTFILES_DIR}/lib/core/logger.sh"
source "${DOTFILES_DIR}/lib/core/validator.sh"

install_nix() {
    if Validator::command_exists "nix"; then
        Logger::info "Nix already installed: $(nix --version)"
        return 0
    fi

    Logger::info "Installing Nix (Determinate Systems installer)..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

    Logger::success "Nix installed successfully"
    Logger::info "Restart your shell to activate Nix"
}

configure_nix() {
    local nix_conf_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/nix"
    local nix_conf="${nix_conf_dir}/nix.conf"

    mkdir -p "${nix_conf_dir}"

    if [[ -f "${nix_conf}" ]] && grep -q "experimental-features" "${nix_conf}"; then
        Logger::debug "Nix flakes already enabled"
        return 0
    fi

    Logger::info "Enabling Nix flakes..."
    cat >> "${nix_conf}" << 'EOF'
experimental-features = nix-command flakes
warn-dirty = false
EOF

    Logger::success "Nix flakes enabled"
}

main() {
    install_nix
    configure_nix
}

main

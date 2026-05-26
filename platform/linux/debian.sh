#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file platform/linux/debian.sh
# @description Debian/Ubuntu-specific provisioning
# @since 1.0.0
# @version 1.0.0
# @see platform/linux/common.sh
#
# Covers: Debian, Ubuntu, Linux Mint, Pop!_OS
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

source "${DOTFILES_DIR}/lib/core/logger.sh"

Logger::info "Running Debian/Ubuntu-specific setup..."

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install Debian-specific packages not available via mise/uv
# ═══════════════════════════════════════════════════════════════════════════════
install_debian_packages() {
    Logger::info "Installing Debian-specific packages..."

    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends \
        zsh \
        fish \
        tmux \
        fontconfig \
        locales \
        ssh \
        gpg \
        gpg-agent \
        socat \
        xclip \
        xsel \
        wl-clipboard
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install Nerd Fonts
# ═══════════════════════════════════════════════════════════════════════════════
install_fonts() {
    local font_dir="${HOME}/.local/share/fonts"
    mkdir -p "${font_dir}"

    if find "${font_dir}" -name "*JetBrainsMono*" -print -quit 2>/dev/null | grep -q .; then
        Logger::debug "Nerd Fonts already installed"
        return 0
    fi

    Logger::info "Installing JetBrains Mono Nerd Font..."
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"

    curl -fsSL "${url}" -o "${tmp_dir}/font.tar.xz"
    tar -xf "${tmp_dir}/font.tar.xz" -C "${font_dir}"
    rm -rf "${tmp_dir}"

    fc-cache -f "${font_dir}"
    Logger::success "Nerd Fonts installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Clean up apt cache
# ═══════════════════════════════════════════════════════════════════════════════
cleanup() {
    sudo apt-get autoremove -y
    sudo apt-get clean
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Main entry point
# ═══════════════════════════════════════════════════════════════════════════════
main() {
    install_debian_packages
    install_fonts
    cleanup
    Logger::success "Debian setup complete"
}

main

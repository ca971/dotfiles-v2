#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file platform/linux/arch.sh
# @description Arch Linux-specific provisioning
# @since 1.0.0
# @version 1.0.0
# @see platform/linux/common.sh
#
# Covers: Arch Linux, Manjaro, EndeavourOS
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

source "${DOTFILES_DIR}/lib/core/logger.sh"
source "${DOTFILES_DIR}/lib/core/validator.sh"

Logger::info "Running Arch Linux-specific setup..."

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install yay AUR helper if not present
# ═══════════════════════════════════════════════════════════════════════════════
install_aur_helper() {
    if Validator::command_exists "yay"; then
        Logger::debug "yay already installed"
        return 0
    fi

    Logger::info "Installing yay AUR helper..."
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "${tmp_dir}/yay-bin"
    (cd "${tmp_dir}/yay-bin" && makepkg -si --noconfirm)
    rm -rf "${tmp_dir}"
    Logger::success "yay installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install Arch-specific packages not available via mise/uv
# ═══════════════════════════════════════════════════════════════════════════════
install_arch_packages() {
    Logger::info "Installing Arch-specific packages..."

    sudo pacman -Syu --noconfirm --needed \
        zsh \
        fish \
        tmux \
        fontconfig \
        openssh \
        gnupg \
        socat \
        xclip \
        xsel \
        wl-clipboard
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install Nerd Fonts from AUR
# ═══════════════════════════════════════════════════════════════════════════════
install_fonts() {
    if pacman -Qi ttf-jetbrains-mono-nerd >/dev/null 2>&1; then
        Logger::debug "Nerd Fonts already installed"
        return 0
    fi

    Logger::info "Installing Nerd Fonts..."
    yay -S --noconfirm ttf-jetbrains-mono-nerd ttf-firacode-nerd
    Logger::success "Nerd Fonts installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Enable useful systemd services
# ═══════════════════════════════════════════════════════════════════════════════
enable_services() {
    sudo systemctl enable --now sshd 2>/dev/null || true
    Logger::debug "Services configured"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Main entry point
# ═══════════════════════════════════════════════════════════════════════════════
main() {
    install_aur_helper
    install_arch_packages
    install_fonts
    enable_services
    Logger::success "Arch Linux setup complete"
}

main

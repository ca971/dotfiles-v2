#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file platform/linux/fedora.sh
# @description Fedora/RHEL-specific provisioning
# @since 1.0.0
# @version 1.0.0
# @see platform/linux/common.sh
#
# Covers: Fedora, RHEL, CentOS Stream, Rocky Linux
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

source "${DOTFILES_DIR}/lib/core/logger.sh"

Logger::info "Running Fedora-specific setup..."

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install Fedora-specific packages not available via mise/uv
# ═══════════════════════════════════════════════════════════════════════════════
install_fedora_packages() {
    Logger::info "Installing Fedora-specific packages..."

    sudo dnf install -y \
        zsh \
        fish \
        tmux \
        fontconfig \
        openssh-server \
        gnupg2 \
        socat \
        xclip \
        xsel \
        wl-clipboard \
        util-linux-user
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
# @description Enable COPR repos for additional packages
# ═══════════════════════════════════════════════════════════════════════════════
setup_repos() {
    # Enable RPM Fusion for multimedia codecs
    if ! rpm -q rpmfusion-free-release >/dev/null 2>&1; then
        Logger::info "Enabling RPM Fusion..."
        sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
            2>/dev/null || true
    fi
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
    setup_repos
    install_fedora_packages
    install_fonts
    enable_services
    Logger::success "Fedora setup complete"
}

main

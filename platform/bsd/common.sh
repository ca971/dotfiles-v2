#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file platform/bsd/common.sh
# @description BSD-specific provisioning (FreeBSD, OpenBSD, NetBSD)
# @since 1.0.0
# @version 1.0.0
# @see platform/linux/common.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

source "${DOTFILES_DIR}/lib/core/logger.sh"
source "${DOTFILES_DIR}/lib/core/platform.sh"

Logger::info "Running BSD-specific setup..."

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install base packages via pkg
# ═══════════════════════════════════════════════════════════════════════════════
install_bsd_packages() {
    Logger::info "Installing BSD base packages..."

    case "${PLATFORM_OS}" in
        freebsd)
            sudo pkg install -y \
                bash \
                zsh \
                fish \
                tmux \
                git \
                curl \
                gnupg \
                fontconfig \
                xclip
            ;;
        openbsd)
            sudo pkg_add -I \
                bash \
                zsh \
                fish \
                tmux \
                git \
                curl \
                gnupg
            ;;
        netbsd)
            sudo pkgin -y install \
                bash \
                zsh \
                fish \
                tmux \
                git \
                curl \
                gnupg
            ;;
    esac

    Logger::success "BSD packages installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Set up XDG directories
# ═══════════════════════════════════════════════════════════════════════════════
setup_xdg_dirs() {
    local -a dirs=(
        "${HOME}/.config"
        "${HOME}/.local/share"
        "${HOME}/.local/state"
        "${HOME}/.cache"
        "${HOME}/.local/bin"
    )

    local dir
    for dir in "${dirs[@]}"; do
        [[ -d "${dir}" ]] || mkdir -p "${dir}"
    done

    Logger::debug "XDG directories created"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install Nerd Fonts manually
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

    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f "${font_dir}"
    fi

    Logger::success "Nerd Fonts installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Set default shell to zsh
# ═══════════════════════════════════════════════════════════════════════════════
set_default_shell() {
    local zsh_path
    zsh_path="$(command -v zsh 2>/dev/null || echo "")"

    if [[ -z "${zsh_path}" ]]; then
        return 0
    fi

    local current_shell
    current_shell="$(getent passwd "$(whoami)" 2>/dev/null | cut -d: -f7 || echo "")"

    if [[ "${current_shell}" == "${zsh_path}" ]]; then
        return 0
    fi

    chsh -s "${zsh_path}" 2>/dev/null || sudo chsh -s "${zsh_path}" "$(whoami)"
    Logger::success "Default shell changed to zsh"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Main entry point
# ═══════════════════════════════════════════════════════════════════════════════
main() {
    install_bsd_packages
    setup_xdg_dirs
    install_fonts
    set_default_shell
    Logger::success "BSD setup complete"
}

main

#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file platform/linux/common.sh
# @description Common Linux setup (shared across all distros)
# @since 1.0.0
# @version 1.0.0
# @see platform/linux/debian.sh, platform/linux/arch.sh, platform/linux/fedora.sh
#
# Called by bootstrap.sh before distro-specific scripts.
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

source "${DOTFILES_DIR}/lib/core/logger.sh"
source "${DOTFILES_DIR}/lib/core/platform.sh"
source "${DOTFILES_DIR}/lib/core/fs.sh"

Logger::info "Running common Linux setup..."

# ═══════════════════════════════════════════════════════════════════════════════
# @description Ensure essential build tools are available
# ═══════════════════════════════════════════════════════════════════════════════
install_build_essentials() {
    Logger::info "Checking build essentials..."

    local pm
    pm="$(Platform::package_manager)" || return 1

    case "${pm}" in
        apt)
            sudo apt-get update -qq
            sudo apt-get install -y --no-install-recommends \
                build-essential curl git ca-certificates gnupg \
                unzip zip wget pkg-config libssl-dev
            ;;
        dnf)
            sudo dnf groupinstall -y "Development Tools"
            sudo dnf install -y curl git ca-certificates gnupg2 \
                unzip zip wget pkg-config openssl-devel
            ;;
        pacman)
            sudo pacman -Syu --noconfirm --needed \
                base-devel curl git ca-certificates gnupg \
                unzip zip wget pkg-config openssl
            ;;
        apk)
            sudo apk add --no-cache \
                build-base curl git ca-certificates gnupg \
                unzip zip wget pkgconf openssl-dev
            ;;
    esac

    Logger::success "Build essentials ready"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Set up XDG directories
# ═══════════════════════════════════════════════════════════════════════════════
setup_xdg_dirs() {
    Logger::debug "Ensuring XDG directories exist..."

    local -a dirs=(
        "${XDG_CONFIG_HOME:-${HOME}/.config}"
        "${XDG_DATA_HOME:-${HOME}/.local/share}"
        "${XDG_STATE_HOME:-${HOME}/.local/state}"
        "${XDG_CACHE_HOME:-${HOME}/.cache}"
        "${HOME}/.local/bin"
    )

    local dir
    for dir in "${dirs[@]}"; do
        FileSystem::mkdir "${dir}"
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Configure systemd user session (if available)
# ═══════════════════════════════════════════════════════════════════════════════
setup_systemd_user() {
    if ! command -v systemctl >/dev/null 2>&1; then
        return 0
    fi

    # Enable lingering for user services
    if command -v loginctl >/dev/null 2>&1; then
        loginctl enable-linger "$(whoami)" 2>/dev/null || true
    fi

    Logger::debug "Systemd user session configured"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Set default shell to zsh if available
# ═══════════════════════════════════════════════════════════════════════════════
set_default_shell() {
    local zsh_path
    zsh_path="$(command -v zsh 2>/dev/null || echo "")"

    if [[ -z "${zsh_path}" ]]; then
        Logger::debug "zsh not found, skipping default shell change"
        return 0
    fi

    local current_shell
    current_shell="$(getent passwd "$(whoami)" | cut -d: -f7)"

    if [[ "${current_shell}" == "${zsh_path}" ]]; then
        Logger::debug "Default shell already zsh"
        return 0
    fi

    if ! grep -q "${zsh_path}" /etc/shells; then
        echo "${zsh_path}" | sudo tee -a /etc/shells >/dev/null
    fi

    sudo chsh -s "${zsh_path}" "$(whoami)"
    Logger::success "Default shell changed to zsh"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Configure locale
# ═══════════════════════════════════════════════════════════════════════════════
setup_locale() {
    if locale -a 2>/dev/null | grep -qi "en_US.utf8"; then
        Logger::debug "en_US.UTF-8 locale already available"
        return 0
    fi

    Logger::info "Generating en_US.UTF-8 locale..."
    if command -v locale-gen >/dev/null 2>&1; then
        sudo locale-gen en_US.UTF-8
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Main entry point
# ═══════════════════════════════════════════════════════════════════════════════
main() {
    install_build_essentials
    setup_xdg_dirs
    setup_systemd_user
    setup_locale
    set_default_shell
    Logger::success "Common Linux setup complete"
}

main

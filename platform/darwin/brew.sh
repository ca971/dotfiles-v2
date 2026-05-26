#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file platform/darwin/brew.sh
# @description Homebrew installation and initial setup for macOS
# @since 1.0.0
# @version 1.0.0
# @see platform/darwin/Brewfile
#
# Installs Homebrew if missing, then installs packages from Brewfile.
# This is a FALLBACK for tools not available via mise/uv/curl.
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

source "${DOTFILES_DIR}/lib/core/logger.sh"
source "${DOTFILES_DIR}/lib/core/validator.sh"

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install Homebrew if not present
# ═══════════════════════════════════════════════════════════════════════════════
install_homebrew() {
    if Validator::command_exists "brew"; then
        Logger::debug "Homebrew already installed"
        return 0
    fi

    Logger::info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to current session PATH
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    Logger::success "Homebrew installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install packages from Brewfile
# ═══════════════════════════════════════════════════════════════════════════════
install_brewfile() {
    local brewfile="${DOTFILES_DIR}/platform/darwin/Brewfile"

    if [[ ! -f "${brewfile}" ]]; then
        Logger::warn "Brewfile not found: ${brewfile}"
        return 0
    fi

    Logger::info "Installing Brewfile packages..."
    brew bundle --file="${brewfile}" --no-lock

    Logger::success "Brewfile packages installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Configure Homebrew settings
# ═══════════════════════════════════════════════════════════════════════════════
configure_homebrew() {
    # Opt out of analytics
    brew analytics off 2>/dev/null || true

    # Cleanup old versions
    brew cleanup --prune=30 2>/dev/null || true

    Logger::debug "Homebrew configured"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Main entry point
# ═══════════════════════════════════════════════════════════════════════════════
main() {
    install_homebrew
    configure_homebrew
    install_brewfile
}

main

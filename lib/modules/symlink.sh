#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/modules/symlink.sh
# @description Symlink manager for config files and local overrides
# @class SymlinkManager
# @since 1.0.0
# @version 1.0.0
# @see docs/ARCHITECTURE.md
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# @description Create all standard config symlinks
# @return Number of created/updated symlinks
# ═══════════════════════════════════════════════════════════════════════════════
SymlinkManager::setup_configs() {
    local xdg_config="${XDG_CONFIG_HOME:-${HOME}/.config}"
    local count=0

    Logger::info "SymlinkManager: setting up config symlinks..."

    local -a configs=(
        "starship"
        "git"
        "bat"
        "lazygit"
        "atuin"
        "yazi"
        "zellij"
        "tmux"
        "wezterm"
        "broot"
        "btop"
        "direnv"
        "mise"
        "nix"
    )

    local config
    for config in "${configs[@]}"; do
        local src="${DOTFILES_DIR}/config/${config}"
        local dst="${xdg_config}/${config}"

        if [[ ! -d "${src}" ]] || [[ -z "$(ls -A "${src}" 2>/dev/null)" ]]; then
            continue
        fi

        if FileSystem::symlink "${src}" "${dst}" 1; then
            (( count++ ))
        fi
    done

    Logger::success "SymlinkManager: ${count} config symlinks created"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Create shell RC file symlinks (optional, for ZDOTDIR approach)
# ═══════════════════════════════════════════════════════════════════════════════
SymlinkManager::setup_shell_links() {
    Logger::debug "SymlinkManager: setting up shell entry points..."

    # Zsh: create ~/.zshenv to redirect to our ZDOTDIR
    local zshenv="${HOME}/.zshenv"
    if [[ ! -f "${zshenv}" ]] || ! grep -q "ZDOTDIR" "${zshenv}" 2>/dev/null; then
        cat > "${zshenv}" << EOF
export ZDOTDIR="\${HOME}/.dotfiles/shells/zsh"
source "\${ZDOTDIR}/.zshenv"
EOF
        Logger::debug "SymlinkManager: created ~/.zshenv (ZDOTDIR redirect)"
    fi

    # Fish: symlink config dir to ~/.config/fish
    local fish_dst="${XDG_CONFIG_HOME:-${HOME}/.config}/fish"
    local fish_src="${DOTFILES_DIR}/shells/fish"
    if [[ ! -L "${fish_dst}" ]] && [[ -d "${fish_src}" ]]; then
        [[ -d "$(dirname "${fish_dst}")" ]] || mkdir -p "$(dirname "${fish_dst}")"
        rm -rf "${fish_dst}" 2>/dev/null || true
        ln -sf "${fish_src}" "${fish_dst}"
        Logger::debug "SymlinkManager: linked ~/.config/fish -> shells/fish"
    fi

    # Git config
    local git_config="${HOME}/.gitconfig"
    if [[ ! -f "${git_config}" ]] && [[ ! -L "${git_config}" ]]; then
        cat > "${git_config}" << EOF
[include]
    path = ${DOTFILES_DIR}/config/git/config
EOF
        Logger::debug "SymlinkManager: created ~/.gitconfig include"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Verify all symlinks are valid (not broken)
# @return Number of broken symlinks found
# ═══════════════════════════════════════════════════════════════════════════════
SymlinkManager::verify() {
    local xdg_config="${XDG_CONFIG_HOME:-${HOME}/.config}"
    local broken=0

    Logger::info "SymlinkManager: verifying symlinks..."

    local link
    while IFS= read -r link; do
        if [[ -L "${link}" ]] && [[ ! -e "${link}" ]]; then
            Logger::warn "SymlinkManager: broken symlink: ${link} -> $(readlink "${link}")"
            (( broken++ ))
        fi
    done < <(find "${xdg_config}" -maxdepth 1 -type l 2>/dev/null)

    if [[ "${broken}" -eq 0 ]]; then
        Logger::success "SymlinkManager: all symlinks valid"
    else
        Logger::warn "SymlinkManager: ${broken} broken symlinks found"
    fi

    return "${broken}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Remove all managed symlinks (for clean uninstall)
# ═══════════════════════════════════════════════════════════════════════════════
SymlinkManager::cleanup() {
    local xdg_config="${XDG_CONFIG_HOME:-${HOME}/.config}"

    Logger::info "SymlinkManager: removing managed symlinks..."

    local link target
    while IFS= read -r link; do
        target="$(readlink "${link}" 2>/dev/null || echo "")"
        if [[ "${target}" == "${DOTFILES_DIR}"* ]]; then
            rm -f "${link}"
            Logger::debug "SymlinkManager: removed ${link}"
        fi
    done < <(find "${xdg_config}" -maxdepth 1 -type l 2>/dev/null)

    Logger::success "SymlinkManager: cleanup complete"
}

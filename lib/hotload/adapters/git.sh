#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/hotload/adapters/git.sh
# @description Git config adapter — clone config repos at bootstrap
# @class GitAdapter
# @extends InstallerAdapter
# @since 1.0.0
# @version 1.0.0
#
# Usage:
#   GitAdapter::install "https://github.com/user/repo.git" "main" "~/.config/tool"
#
# Clones a config repository to the target path. If the target already exists
# and is a git repo, it pulls instead (upgrade). Handles the case where the
# target is an existing non-git directory by backing it up.
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

GitAdapter::is_available() {
    command -v git >/dev/null 2>&1
}

GitAdapter::install() {
    local repo="${1:?Git repo URL required}"
    local ref="${2:-main}"
    local target="${3:?Target path required}"

    # Expand ~ in target
    target="${target/#\~/${HOME}}"

    Logger::debug "GitAdapter: installing config from ${repo} (ref=${ref}) to ${target}"

    # If target already exists and is a git repo, pull
    if [[ -d "${target}/.git" ]]; then
        Logger::info "GitAdapter: ${target} exists, pulling updates..."
        if ! git -C "${target}" fetch origin "${ref}" 2>&1; then
            Logger::error "GitAdapter: failed to fetch ${repo}"
            return 1
        fi
        if ! git -C "${target}" checkout "${ref}" 2>&1; then
            Logger::warn "GitAdapter: could not checkout ${ref}, staying on current branch"
        fi
        if ! git -C "${target}" pull origin "${ref}" --ff-only 2>&1; then
            Logger::warn "GitAdapter: could not fast-forward pull, repo may have local changes"
        fi
        return 0
    fi

    # If target exists but is not a git repo, back it up
    if [[ -e "${target}" ]]; then
        local backup
        backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
        Logger::warn "GitAdapter: ${target} exists but is not a git repo"
        Logger::info "GitAdapter: moving to ${backup}"
        mv "${target}" "${backup}"
    fi

    # Create parent directory
    local parent
    parent="$(dirname "${target}")"
    mkdir -p "${parent}"

    # Clone the repo
    if ! git clone --branch "${ref}" --single-branch "${repo}" "${target}" 2>&1; then
        # Fallback: clone without branch constraint, then checkout
        Logger::warn "GitAdapter: branch '${ref}' not found, cloning default branch"
        if ! git clone --single-branch "${repo}" "${target}" 2>&1; then
            Logger::error "GitAdapter: failed to clone ${repo}"
            return 1
        fi
    fi

    Logger::success "GitAdapter: cloned ${repo} → ${target}"
    return 0
}

GitAdapter::uninstall() {
    local repo="${1:?Git repo URL required}"
    local ref="${2:-main}"
    local target="${3:?Target path required}"

    target="${target/#\~/${HOME}}"

    if [[ -d "${target}" ]]; then
        Logger::debug "GitAdapter: removing ${target}"
        rm -rf "${target}"
        Logger::success "GitAdapter: removed ${target}"
    else
        Logger::debug "GitAdapter: ${target} not found, nothing to uninstall"
    fi
    return 0
}

GitAdapter::is_installed() {
    local repo="${1:?Git repo URL required}"
    local ref="${2:-main}"
    local target="${3:?Target path required}"

    target="${target/#\~/${HOME}}"

    # Check that target exists and is a git repo with matching remote
    if [[ -d "${target}/.git" ]]; then
        local remote_url
        remote_url="$(git -C "${target}" remote get-url origin 2>/dev/null || echo "")"
        if [[ "${remote_url}" == "${repo}" ]] || [[ "${remote_url}" == "${repo}.git" ]]; then
            return 0
        fi
    fi
    return 1
}

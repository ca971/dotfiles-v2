#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file tools/nix/hooks/activate.bash
# @description Bash/Zsh hook for activating Nix environments via direnv
# @since 1.0.0
# @version 1.0.0
#
# Usage in project .envrc:
#   source_env ~/.dotfiles/tools/nix/hooks/activate.bash
#   use_nix_env python
# ═══════════════════════════════════════════════════════════════════════════════

use_nix_env() {
    local env_name="${1:?Environment name required}"
    local env_dir="${DOTFILES_DIR:-${HOME}/.dotfiles}/tools/nix/envs/${env_name}"

    if [[ ! -d "${env_dir}" ]]; then
        log_error "Nix environment not found: ${env_name}"
        return 1
    fi

    watch_file "${env_dir}/flake.nix"
    watch_file "${env_dir}/flake.lock"

    log_status "loading nix env: ${env_name}"
    use flake "${env_dir}"
}

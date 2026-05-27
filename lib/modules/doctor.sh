#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/modules/doctor.sh
# @description System health check and diagnostic tool
# @class Doctor
# @since 1.0.0
# @version 1.0.0
# @see bin/dotfiles
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# @description Run all diagnostic checks
# @return 0 if healthy, 1+ for number of issues found
# ═══════════════════════════════════════════════════════════════════════════════
Doctor::run() {
    local issues=0

    echo ""
    Logger::info "Running dotfiles health check..."
    echo ""

    Doctor::check_hard_deps || (( issues += $? ))
    Doctor::check_vault_permissions || (( issues += $? ))
    Doctor::check_generated_files || (( issues += $? ))
    Doctor::check_symlinks || (( issues += $? ))
    Doctor::check_state || (( issues += $? ))
    Doctor::check_shell_config || (( issues += $? ))
    Doctor::check_starship || (( issues += $? ))
    Doctor::check_tools || (( issues += $? ))
    Doctor::check_default_shell || (( issues += $? ))

    echo ""
    if [[ "${issues}" -eq 0 ]]; then
        Logger::success "All checks passed! System is healthy."
    else
        Logger::warn "${issues} issue(s) found. Run with --verbose for details."
    fi

    return "${issues}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check hard dependencies are available
# @return Number of missing dependencies
# ═══════════════════════════════════════════════════════════════════════════════
Doctor::check_hard_deps() {
    local missing=0
    local -a deps=("bash" "curl" "git" "jq" "mise" "uv" "python3")

    printf "  %-30s" "Hard dependencies"

    local dep
    for dep in "${deps[@]}"; do
        if ! command -v "${dep}" >/dev/null 2>&1; then
            (( missing++ ))
            Logger::debug "Doctor: missing dependency: ${dep}"
        fi
    done

    if [[ "${missing}" -eq 0 ]]; then
        echo "[OK] all ${#deps[@]} deps found"
    else
        echo "[FAIL] ${missing} missing"
    fi

    return "${missing}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check vault directory permissions
# @return Number of permission issues
# ═══════════════════════════════════════════════════════════════════════════════
Doctor::check_vault_permissions() {
    local errors=0

    printf "  %-30s" "Vault permissions"

    local -a dirs=(
        "${DOTFILES_DIR}/local/secrets"
        "${DOTFILES_DIR}/local/ssh"
        "${DOTFILES_DIR}/local/ssh/keys"
    )

    local dir
    for dir in "${dirs[@]}"; do
        if [[ ! -d "${dir}" ]]; then
            continue
        fi

        local perms
        if [[ "$(uname -s)" == "Darwin" ]]; then
            perms="$(stat -f '%A' "${dir}")"
        else
            perms="$(stat -c '%a' "${dir}")"
        fi

        if [[ "${perms}" != "700" ]]; then
            (( errors++ ))
        fi
    done

    if [[ "${errors}" -eq 0 ]]; then
        echo "[OK] all restricted dirs are 700"
    else
        echo "[FAIL] ${errors} dirs with wrong permissions"
    fi

    return "${errors}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check generated shell files exist
# @return Number of missing generated files
# ═══════════════════════════════════════════════════════════════════════════════
Doctor::check_generated_files() {
    local missing=0

    printf "  %-30s" "Generated configs"

    local -a shells=("bash" "zsh" "fish" "nushell")
    local shell

    for shell in "${shells[@]}"; do
        local gen_dir="${DOTFILES_DIR}/shells/${shell}/generated"
        if [[ ! -d "${gen_dir}" ]] || [[ -z "$(ls -A "${gen_dir}" 2>/dev/null)" ]]; then
            (( missing++ ))
        fi
    done

    if [[ "${missing}" -eq 0 ]]; then
        echo "[OK] all 4 shells have generated configs"
    else
        echo "[FAIL] ${missing} shells missing generated configs"
        Logger::debug "Doctor: run 'dotfiles-gen generate --all' to fix"
    fi

    return "${missing}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check XDG config symlinks
# @return Number of broken symlinks
# ═══════════════════════════════════════════════════════════════════════════════
Doctor::check_symlinks() {
    local broken=0

    printf "  %-30s" "Config symlinks"

    local xdg_config="${XDG_CONFIG_HOME:-${HOME}/.config}"
    local link
    while IFS= read -r link; do
        if [[ -L "${link}" ]] && [[ ! -e "${link}" ]]; then
            (( broken++ ))
        fi
    done < <(find "${xdg_config}" -maxdepth 1 -type l 2>/dev/null)

    if [[ "${broken}" -eq 0 ]]; then
        echo "[OK] no broken symlinks"
    else
        echo "[FAIL] ${broken} broken symlinks"
    fi

    return "${broken}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check state.json integrity
# @return 0 if valid, 1 if corrupt/missing
# ═══════════════════════════════════════════════════════════════════════════════
Doctor::check_state() {
    local state_file="${DOTFILES_DIR}/local/state.json"

    printf "  %-30s" "State file"

    if [[ ! -f "${state_file}" ]]; then
        echo "[FAIL] missing"
        return 1
    fi

    if ! jq empty "${state_file}" 2>/dev/null; then
        echo "[FAIL] invalid JSON"
        return 1
    fi

    local version
    version="$(jq -r '.version // 0' "${state_file}")"
    if [[ "${version}" -lt 1 ]]; then
        echo "[FAIL] invalid version"
        return 1
    fi

    echo "[OK] valid (v${version})"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check current shell configuration is properly sourced
# @return 0 if OK, 1 if issues found
# ═══════════════════════════════════════════════════════════════════════════════
Doctor::check_shell_config() {
    printf "  %-30s" "Shell integration"

    if [[ -z "${DOTFILES_DIR:-}" ]]; then
        echo "[FAIL] DOTFILES_DIR not set"
        return 1
    fi

    if [[ ! -d "${DOTFILES_DIR}" ]]; then
        echo "[FAIL] DOTFILES_DIR does not exist"
        return 1
    fi

    echo "[OK] DOTFILES_DIR=${DOTFILES_DIR}"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check starship prompt is configured and functional
# @return 0 if OK, 1 if issues found
# ═══════════════════════════════════════════════════════════════════════════════
Doctor::check_starship() {
    printf "  %-30s" "Starship prompt"

    if ! command -v starship >/dev/null 2>&1; then
        echo "[WARN] not installed (install via: just install starship)"
        return 0  # warn but not an error
    fi

    local config="${STARSHIP_CONFIG:-${XDG_CONFIG_HOME:-${HOME}/.config}/starship/base.toml}"
    if [[ ! -f "${config}" ]]; then
        echo "[FAIL] config not found: ${config}"
        return 1
    fi

    local version
    version="$(starship --version 2>/dev/null | head -1)"
    echo "[OK] ${version:-installed}"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check tool installation status (quick count, not full audit)
# @return 0 if all profile tools installed, N for missing count
# ═══════════════════════════════════════════════════════════════════════════════
Doctor::check_tools() {
    printf "  %-30s" "Profile tools"

    local state_file="${DOTFILES_DIR}/local/state.json"
    if [[ ! -f "${state_file}" ]]; then
        echo "[WARN] no state file yet (run bootstrap first)"
        return 0
    fi

    local total installed
    total="$(jq '.tools | length' "${state_file}" 2>/dev/null || echo 0)"
    installed="$(jq '[.tools[] | select(.installed == true)] | length' "${state_file}" 2>/dev/null || echo 0)"

    if [[ "${total}" -eq 0 ]]; then
        echo "[WARN] no tools tracked yet"
        return 0
    fi

    local missing=$((total - installed))
    if [[ "${missing}" -eq 0 ]]; then
        echo "[OK] ${installed}/${total} tools installed"
    else
        echo "[WARN] ${installed}/${total} installed (${missing} missing)"
    fi

    return 0  # informational only
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check that the default shell is a configured one
# @return 0 if OK, 1 if default shell is not configured
# ═══════════════════════════════════════════════════════════════════════════════
Doctor::check_default_shell() {
    printf "  %-30s" "Default shell"

    local current_shell
    current_shell="${SHELL:-/bin/sh}"

    # Check if current shell has generated configs
    local shell_name
    shell_name="$(basename "${current_shell}")"
    local gen_dir="${DOTFILES_DIR}/shells/${shell_name}/generated"

    if [[ -d "${gen_dir}" ]] && [[ -n "$(ls -A "${gen_dir}" 2>/dev/null)" ]]; then
        echo "[OK] ${shell_name} (configured)"
    elif [[ "${shell_name}" == "bash" ]] || [[ "${shell_name}" == "zsh" ]] \
      || [[ "${shell_name}" == "fish" ]] || [[ "${shell_name}" == "nu" ]]; then
        echo "[WARN] ${shell_name} (configs not generated — run dotfiles-gen)"
    else
        echo "[INFO] ${shell_name} (not a dotfiles-managed shell)"
    fi

    return 0
}

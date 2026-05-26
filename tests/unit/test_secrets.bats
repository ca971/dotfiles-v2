#!/usr/bin/env bats
# ═══════════════════════════════════════════════════════════════════════════════
# @file tests/unit/test_secrets.bats
# @description Unit tests for vault, secrets, doctor, and local overrides
# @since 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

setup() {
    export DOTFILES_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_COLOR=0
    export LOG_LEVEL=4
    source "${DOTFILES_DIR}/lib/core/logger.sh"
    source "${DOTFILES_DIR}/lib/core/platform.sh"
    source "${DOTFILES_DIR}/lib/core/validator.sh"
    source "${DOTFILES_DIR}/lib/core/fs.sh"

    _test_state="$(mktemp)"
    export STATE_FILE="${_test_state}"
    echo '{"version":1,"tools":{},"nix_envs":{},"theme":"minimal"}' > "${STATE_FILE}"
}

teardown() {
    rm -f "${_test_state}"
    rm -rf "${_test_vault:-}" 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SecretVault
# ═══════════════════════════════════════════════════════════════════════════════

@test "SecretVault::init creates directory structure" {
    source "${DOTFILES_DIR}/lib/modules/secrets.sh"
    SecretVault::init

    [[ -d "${DOTFILES_DIR}/local/secrets" ]]
    [[ -d "${DOTFILES_DIR}/local/ssh" ]]
    [[ -d "${DOTFILES_DIR}/local/ssh/keys" ]]
    [[ -d "${DOTFILES_DIR}/local/shell" ]]
    [[ -d "${DOTFILES_DIR}/local/config" ]]
}

@test "SecretVault::verify_permissions passes on correct perms" {
    source "${DOTFILES_DIR}/lib/modules/secrets.sh"
    SecretVault::verify_permissions
}

@test "SecretVault::fix_permissions sets 700 on restricted dirs" {
    source "${DOTFILES_DIR}/lib/modules/secrets.sh"
    chmod 755 "${DOTFILES_DIR}/local/secrets" 2>/dev/null || true
    SecretVault::fix_permissions

    local perms
    if [[ "$(uname -s)" == "Darwin" ]]; then
        perms="$(stat -f '%A' "${DOTFILES_DIR}/local/secrets")"
    else
        perms="$(stat -c '%a' "${DOTFILES_DIR}/local/secrets")"
    fi
    [[ "${perms}" == "700" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Doctor
# ═══════════════════════════════════════════════════════════════════════════════

@test "Doctor::check_hard_deps finds all required tools" {
    source "${DOTFILES_DIR}/lib/modules/doctor.sh"
    run Doctor::check_hard_deps
    [[ "${output}" == *"[OK]"* ]]
}

@test "Doctor::check_vault_permissions passes" {
    source "${DOTFILES_DIR}/lib/modules/doctor.sh"
    run Doctor::check_vault_permissions
    [[ "${output}" == *"[OK]"* ]]
}

@test "Doctor::check_generated_files passes when generated exists" {
    source "${DOTFILES_DIR}/lib/modules/doctor.sh"
    run Doctor::check_generated_files
    [[ "${output}" == *"[OK]"* ]]
}

@test "Doctor::check_state passes with valid state" {
    source "${DOTFILES_DIR}/lib/modules/doctor.sh"
    run Doctor::check_state
    [[ "${output}" == *"[OK]"* ]]
}

@test "Doctor::check_shell_config passes" {
    source "${DOTFILES_DIR}/lib/modules/doctor.sh"
    run Doctor::check_shell_config
    [[ "${output}" == *"[OK]"* ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# dotfiles CLI
# ═══════════════════════════════════════════════════════════════════════════════

@test "dotfiles --help shows usage" {
    run bash -c "DOTFILES_DIR='${DOTFILES_DIR}' '${DOTFILES_DIR}/bin/dotfiles' --help"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"Usage"* ]]
    [[ "${output}" == *"install"* ]]
    [[ "${output}" == *"doctor"* ]]
}

@test "dotfiles --version shows version" {
    run bash -c "DOTFILES_DIR='${DOTFILES_DIR}' '${DOTFILES_DIR}/bin/dotfiles' --version"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "dotfiles 1.0.0" ]]
}

@test "dotfiles doctor exits with 0" {
    DOTFILES_DIR="${DOTFILES_DIR}" LOG_COLOR=0 NO_COLOR=1 \
        bash "${DOTFILES_DIR}/bin/dotfiles" doctor >/dev/null 2>&1
}

# ═══════════════════════════════════════════════════════════════════════════════
# Local overrides
# ═══════════════════════════════════════════════════════════════════════════════

@test "local override files exist for all shells" {
    [[ -f "${DOTFILES_DIR}/local/shell/bash.local" ]]
    [[ -f "${DOTFILES_DIR}/local/shell/zsh.local" ]]
    [[ -f "${DOTFILES_DIR}/local/shell/fish.local" ]]
    [[ -f "${DOTFILES_DIR}/local/shell/nushell.local" ]]
}

@test "local env.local exists" {
    [[ -f "${DOTFILES_DIR}/local/env.local" ]]
}

@test "local gitconfig.local exists" {
    [[ -f "${DOTFILES_DIR}/local/gitconfig.local" ]]
}

@test "local state.json is valid JSON" {
    jq empty "${DOTFILES_DIR}/local/state.json"
}

# ═══════════════════════════════════════════════════════════════════════════════
# SymlinkManager
# ═══════════════════════════════════════════════════════════════════════════════

@test "SymlinkManager::verify returns 0 when no broken links" {
    source "${DOTFILES_DIR}/lib/modules/symlink.sh"
    export XDG_CONFIG_HOME="$(mktemp -d)"
    run SymlinkManager::verify
    [[ "${status}" -eq 0 ]]
    rm -rf "${XDG_CONFIG_HOME}"
}

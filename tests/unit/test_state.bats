#!/usr/bin/env bats
# ═══════════════════════════════════════════════════════════════════════════════
# @file tests/unit/test_state.bats
# @description Unit tests for lib/hotload/state.sh
# @since 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

setup() {
    export DOTFILES_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_COLOR=0
    export LOG_LEVEL=4
    source "${DOTFILES_DIR}/lib/core/logger.sh"

    # Use a temporary state file for each test
    _test_state="$(mktemp)"
    export STATE_FILE="${_test_state}"
    echo '{"version":1,"tools":{},"nix_envs":{},"theme":"minimal"}' > "${STATE_FILE}"
    source "${DOTFILES_DIR}/lib/hotload/state.sh"
}

teardown() {
    rm -f "${_test_state}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# StateManager::init
# ═══════════════════════════════════════════════════════════════════════════════

@test "StateManager::init creates state file if missing" {
    rm -f "${STATE_FILE}"
    StateManager::init
    [[ -f "${STATE_FILE}" ]]
}

@test "StateManager::init preserves existing state" {
    StateManager::mark_installed "test-tool" "mise" "1.0.0"
    StateManager::init
    StateManager::is_installed "test-tool"
}

# ═══════════════════════════════════════════════════════════════════════════════
# StateManager::mark_installed / is_installed
# ═══════════════════════════════════════════════════════════════════════════════

@test "StateManager::mark_installed records tool" {
    StateManager::mark_installed "bat" "mise" "0.24.0"
    StateManager::is_installed "bat"
}

@test "StateManager::is_installed returns false for unknown tool" {
    ! StateManager::is_installed "nonexistent-tool"
}

@test "StateManager::mark_installed stores method" {
    StateManager::mark_installed "commitizen" "uv" "3.0.0"
    local method
    method="$(StateManager::get_method "commitizen")"
    [[ "${method}" == "uv" ]]
}

@test "StateManager::mark_installed stores version" {
    StateManager::mark_installed "eza" "mise" "0.18.0"
    local version
    version="$(StateManager::get '.tools.eza.version')"
    [[ "${version}" == "0.18.0" ]]
}

@test "StateManager::mark_installed stores timestamp" {
    StateManager::mark_installed "fd" "mise" "9.0.0"
    local ts
    ts="$(StateManager::get '.tools.fd.installed_at')"
    [[ "${ts}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# StateManager::mark_uninstalled
# ═══════════════════════════════════════════════════════════════════════════════

@test "StateManager::mark_uninstalled removes tool" {
    StateManager::mark_installed "bat" "mise" "0.24.0"
    StateManager::mark_uninstalled "bat"
    ! StateManager::is_installed "bat"
}

# ═══════════════════════════════════════════════════════════════════════════════
# StateManager::list_installed
# ═══════════════════════════════════════════════════════════════════════════════

@test "StateManager::list_installed shows all installed tools" {
    StateManager::mark_installed "bat" "mise" "0.24.0"
    StateManager::mark_installed "eza" "mise" "0.18.0"
    StateManager::mark_installed "commitizen" "uv" "3.0.0"

    local output
    output="$(StateManager::list_installed)"
    [[ "${output}" == *"bat"* ]]
    [[ "${output}" == *"eza"* ]]
    [[ "${output}" == *"commitizen"* ]]
}

@test "StateManager::list_installed is sorted" {
    StateManager::mark_installed "zoxide" "mise" "0.9.0"
    StateManager::mark_installed "bat" "mise" "0.24.0"
    StateManager::mark_installed "eza" "mise" "0.18.0"

    local first
    first="$(StateManager::list_installed | head -1)"
    [[ "${first}" == "bat" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# StateManager::get / set
# ═══════════════════════════════════════════════════════════════════════════════

@test "StateManager::get reads value" {
    local theme
    theme="$(StateManager::get '.theme')"
    [[ "${theme}" == "minimal" ]]
}

@test "StateManager::set writes value" {
    StateManager::set ".theme" '"full"'
    local theme
    theme="$(StateManager::get '.theme')"
    [[ "${theme}" == "full" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# StateManager::get_theme / set_theme
# ═══════════════════════════════════════════════════════════════════════════════

@test "StateManager::get_theme returns default" {
    local theme
    theme="$(StateManager::get_theme)"
    [[ "${theme}" == "minimal" ]]
}

@test "StateManager::set_theme updates theme" {
    StateManager::set_theme "powerline"
    local theme
    theme="$(StateManager::get_theme)"
    [[ "${theme}" == "powerline" ]]
}

#!/usr/bin/env bats
# ═══════════════════════════════════════════════════════════════════════════════
# @file tests/unit/test_hotload.bats
# @description Unit tests for the hot-loading engine and adapters
# @since 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

setup() {
    export DOTFILES_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_COLOR=0
    export LOG_LEVEL=4
    source "${DOTFILES_DIR}/lib/core/logger.sh"
    source "${DOTFILES_DIR}/lib/core/platform.sh"
    source "${DOTFILES_DIR}/lib/core/validator.sh"

    _test_state="$(mktemp)"
    export STATE_FILE="${_test_state}"
    echo '{"version":1,"tools":{},"nix_envs":{},"theme":"minimal"}' > "${STATE_FILE}"

    source "${DOTFILES_DIR}/lib/hotload/state.sh"
    source "${DOTFILES_DIR}/lib/hotload/adapters/_base.sh"
    source "${DOTFILES_DIR}/lib/hotload/adapters/mise.sh"
    source "${DOTFILES_DIR}/lib/hotload/adapters/uv.sh"
    source "${DOTFILES_DIR}/lib/hotload/adapters/curl.sh"
    source "${DOTFILES_DIR}/lib/hotload/adapters/cargo.sh"
    source "${DOTFILES_DIR}/lib/hotload/adapters/brew.sh"
    source "${DOTFILES_DIR}/lib/hotload/adapters/nix.sh"
    source "${DOTFILES_DIR}/lib/hotload/adapters/system.sh"
    source "${DOTFILES_DIR}/lib/hotload/install.sh"
    source "${DOTFILES_DIR}/lib/hotload/uninstall.sh"
}

teardown() {
    rm -f "${_test_state}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Adapter availability
# ═══════════════════════════════════════════════════════════════════════════════

@test "MiseAdapter::is_available returns true when mise exists" {
    if ! command -v mise >/dev/null 2>&1; then
        skip "mise not installed"
    fi
    MiseAdapter::is_available
}

@test "UvAdapter::is_available returns true when uv exists" {
    if ! command -v uv >/dev/null 2>&1; then
        skip "uv not installed"
    fi
    UvAdapter::is_available
}

@test "CurlAdapter::is_available returns true" {
    CurlAdapter::is_available
}

@test "BrewAdapter::is_available on macOS" {
    if [[ "$(uname -s)" != "Darwin" ]]; then
        skip "Not on macOS"
    fi
    BrewAdapter::is_available
}

@test "NixAdapter::is_available returns status" {
    # Just ensure it doesn't crash
    NixAdapter::is_available || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# Tool descriptor parsing
# ═══════════════════════════════════════════════════════════════════════════════

@test "tool descriptor bat.toml exists and has content" {
    [[ -f "${DOTFILES_DIR}/tools/available/bat.toml" ]]
    [[ -s "${DOTFILES_DIR}/tools/available/bat.toml" ]]
}

@test "tool descriptor bat.toml has meta.name" {
    grep -q 'name = "bat"' "${DOTFILES_DIR}/tools/available/bat.toml"
}

@test "tool descriptor bat.toml has verify command" {
    grep -q 'verify = "bat --version"' "${DOTFILES_DIR}/tools/available/bat.toml"
}

@test "tool descriptor bat.toml has install section" {
    grep -q '^\[\[install\]\]' "${DOTFILES_DIR}/tools/available/bat.toml"
}

@test "tool descriptor commitizen.toml uses uv method" {
    grep -q 'method = "uv"' "${DOTFILES_DIR}/tools/available/commitizen.toml"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Method resolution
# ═══════════════════════════════════════════════════════════════════════════════

@test "ToolInstaller::resolve_method finds method for bat" {
    if ! command -v taplo >/dev/null 2>&1; then
        skip "taplo not installed (required for TOML parsing)"
    fi
    local result
    result="$(ToolInstaller::resolve_method "bat")"
    [[ -n "${result}" ]]
    [[ "${result}" == *"|"* ]]
}

@test "ToolInstaller::resolve_method resolves mise for bat on this platform" {
    if ! command -v taplo >/dev/null 2>&1; then
        skip "taplo not installed"
    fi
    if ! command -v mise >/dev/null 2>&1; then
        skip "mise not installed"
    fi
    local result
    result="$(ToolInstaller::resolve_method "bat")"
    [[ "${result}" == mise* ]]
}

@test "ToolInstaller::resolve_method resolves uv for commitizen" {
    if ! command -v taplo >/dev/null 2>&1; then
        skip "taplo not installed"
    fi
    if ! command -v uv >/dev/null 2>&1; then
        skip "uv not installed"
    fi
    local result
    result="$(ToolInstaller::resolve_method "commitizen")"
    [[ "${result}" == uv* ]]
}

@test "ToolInstaller::resolve_method fails for nonexistent tool" {
    ! ToolInstaller::resolve_method "this-tool-does-not-exist-xyz"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Full install/uninstall cycle (integration with state)
# ═══════════════════════════════════════════════════════════════════════════════

@test "ToolInstaller::install skips already installed tools" {
    StateManager::mark_installed "bat" "mise" "0.24.0"
    # Should return 0 (success) without doing anything
    ToolInstaller::install "bat"
}

@test "ToolUninstaller::uninstall warns for non-installed tools" {
    ! ToolUninstaller::uninstall "nonexistent-tool-xyz"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Engine listing
# ═══════════════════════════════════════════════════════════════════════════════

@test "HotLoadEngine::list_available returns tools" {
    source "${DOTFILES_DIR}/lib/hotload/engine.sh"
    local output
    output="$(HotLoadEngine::list_available)"
    [[ "${output}" == *"bat"* ]]
    [[ "${output}" == *"eza"* ]]
    [[ "${output}" == *"commitizen"* ]]
}

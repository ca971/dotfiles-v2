#!/usr/bin/env bats
# ═══════════════════════════════════════════════════════════════════════════════
# @file tests/integration/test_nix_envs.bats
# @description Integration tests for Nix environment manager
# @since 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

setup() {
    export DOTFILES_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_COLOR=0
    export LOG_LEVEL=4

    _test_state="$(mktemp)"
    export STATE_FILE="${_test_state}"
    echo '{"version":1,"tools":{},"nix_envs":{},"theme":"minimal"}' > "${STATE_FILE}"
}

teardown() {
    rm -f "${_test_state}"
    # Clean up test env if created
    rm -rf "${DOTFILES_DIR}/tools/nix/envs/test-env-bats"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Structure validation
# ═══════════════════════════════════════════════════════════════════════════════

@test "nix manifest.toml exists" {
    [[ -s "${DOTFILES_DIR}/tools/nix/manifest.toml" ]]
}

@test "nix install.sh exists and is executable" {
    [[ -s "${DOTFILES_DIR}/tools/nix/install.sh" ]]
    [[ -x "${DOTFILES_DIR}/tools/nix/install.sh" ]]
}

@test "nix uninstall.sh exists and is executable" {
    [[ -s "${DOTFILES_DIR}/tools/nix/uninstall.sh" ]]
    [[ -x "${DOTFILES_DIR}/tools/nix/uninstall.sh" ]]
}

@test "all environments have manifest.toml" {
    local env_dir
    for env_dir in "${DOTFILES_DIR}"/tools/nix/envs/*/; do
        local env_name
        env_name="$(basename "${env_dir}")"
        [[ -s "${env_dir}/manifest.toml" ]]
    done
}

@test "all environments have flake.nix" {
    local env_dir
    for env_dir in "${DOTFILES_DIR}"/tools/nix/envs/*/; do
        [[ -s "${env_dir}/flake.nix" ]]
    done
}

@test "9 environments exist (8 envs + template)" {
    local count
    count="$(find "${DOTFILES_DIR}/tools/nix/envs" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
    [[ "${count}" -eq 9 ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Flake structure
# ═══════════════════════════════════════════════════════════════════════════════

@test "default flake.nix references nixpkgs-unstable" {
    grep -q "nixpkgs-unstable" "${DOTFILES_DIR}/tools/nix/envs/default/flake.nix"
}

@test "default flake.nix uses flake-utils" {
    grep -q "flake-utils" "${DOTFILES_DIR}/tools/nix/envs/default/flake.nix"
}

@test "python flake.nix includes uv and ruff" {
    grep -q "uv" "${DOTFILES_DIR}/tools/nix/envs/python/flake.nix"
    grep -q "ruff" "${DOTFILES_DIR}/tools/nix/envs/python/flake.nix"
}

@test "rust flake.nix includes rust-analyzer" {
    grep -q "rust-analyzer" "${DOTFILES_DIR}/tools/nix/envs/rust/flake.nix"
}

@test "devops flake.nix includes terraform and kubectl" {
    grep -q "terraform" "${DOTFILES_DIR}/tools/nix/envs/devops/flake.nix"
    grep -q "kubectl" "${DOTFILES_DIR}/tools/nix/envs/devops/flake.nix"
}

# ═══════════════════════════════════════════════════════════════════════════════
# CLI commands
# ═══════════════════════════════════════════════════════════════════════════════

@test "dotfiles-nix list shows environments" {
    local output
    output="$(bash "${DOTFILES_DIR}/bin/dotfiles-nix" list 2>&1)"
    [[ "${output}" == *"default"* ]]
    [[ "${output}" == *"python"* ]]
    [[ "${output}" == *"rust"* ]]
}

@test "dotfiles-nix list shows enabled status" {
    local output
    output="$(bash "${DOTFILES_DIR}/bin/dotfiles-nix" list 2>&1)"
    [[ "${output}" == *"active"* ]]
}

@test "dotfiles-nix list shows disabled environments" {
    local output
    output="$(bash "${DOTFILES_DIR}/bin/dotfiles-nix" list 2>&1)"
    [[ "${output}" == *"off"* ]]
}

@test "dotfiles-nix create makes new environment" {
    bash "${DOTFILES_DIR}/bin/dotfiles-nix" create test-env-bats 2>&1
    [[ -d "${DOTFILES_DIR}/tools/nix/envs/test-env-bats" ]]
    [[ -f "${DOTFILES_DIR}/tools/nix/envs/test-env-bats/flake.nix" ]]
    [[ -f "${DOTFILES_DIR}/tools/nix/envs/test-env-bats/manifest.toml" ]]
}

@test "dotfiles-nix create updates names in manifest" {
    bash "${DOTFILES_DIR}/bin/dotfiles-nix" create test-env-bats 2>&1
    grep -q 'name = "test-env-bats"' "${DOTFILES_DIR}/tools/nix/envs/test-env-bats/manifest.toml"
}

@test "dotfiles-nix create rejects existing environment" {
    bash "${DOTFILES_DIR}/bin/dotfiles-nix" create test-env-bats 2>&1
    ! bash "${DOTFILES_DIR}/bin/dotfiles-nix" create test-env-bats 2>&1
}

@test "dotfiles-nix disable sets enabled to false" {
    bash "${DOTFILES_DIR}/bin/dotfiles-nix" create test-env-bats 2>&1
    bash "${DOTFILES_DIR}/bin/dotfiles-nix" disable test-env-bats 2>&1
    grep -q 'enabled = false' "${DOTFILES_DIR}/tools/nix/envs/test-env-bats/manifest.toml"
}

@test "dotfiles-nix enable sets enabled to true" {
    bash "${DOTFILES_DIR}/bin/dotfiles-nix" create test-env-bats 2>&1
    bash "${DOTFILES_DIR}/bin/dotfiles-nix" disable test-env-bats 2>&1
    bash "${DOTFILES_DIR}/bin/dotfiles-nix" enable test-env-bats 2>&1
    grep -q 'enabled = true' "${DOTFILES_DIR}/tools/nix/envs/test-env-bats/manifest.toml"
}

@test "dotfiles-nix help shows usage" {
    local output
    output="$(bash "${DOTFILES_DIR}/bin/dotfiles-nix" --help 2>&1)"
    [[ "${output}" == *"Usage"* ]]
    [[ "${output}" == *"enter"* ]]
    [[ "${output}" == *"create"* ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Hooks
# ═══════════════════════════════════════════════════════════════════════════════

@test "activation hooks exist for all shells" {
    [[ -s "${DOTFILES_DIR}/tools/nix/hooks/activate.bash" ]]
    [[ -s "${DOTFILES_DIR}/tools/nix/hooks/activate.zsh" ]]
    [[ -s "${DOTFILES_DIR}/tools/nix/hooks/activate.fish" ]]
    [[ -s "${DOTFILES_DIR}/tools/nix/hooks/activate.nu" ]]
}

@test "bash hook defines use_nix_env function" {
    grep -q "use_nix_env" "${DOTFILES_DIR}/tools/nix/hooks/activate.bash"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Config
# ═══════════════════════════════════════════════════════════════════════════════

@test "nix.conf enables flakes" {
    grep -q "flakes" "${DOTFILES_DIR}/config/nix/nix.conf"
}

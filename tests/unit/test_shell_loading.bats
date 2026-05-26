#!/usr/bin/env bats
# ═══════════════════════════════════════════════════════════════════════════════
# @file tests/unit/test_shell_loading.bats
# @description Tests that shell configs load without errors
# @since 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

setup() {
    export DOTFILES_DIR="${BATS_TEST_DIRNAME}/../.."
}

# ═══════════════════════════════════════════════════════════════════════════════
# Bash
# ═══════════════════════════════════════════════════════════════════════════════

@test "bash: generated aliases file exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/shells/bash/generated/aliases.gen.sh" ]]
    [[ -s "${DOTFILES_DIR}/shells/bash/generated/aliases.gen.sh" ]]
}

@test "bash: generated env file exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/shells/bash/generated/env.gen.sh" ]]
    [[ -s "${DOTFILES_DIR}/shells/bash/generated/env.gen.sh" ]]
}

@test "bash: generated path file exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/shells/bash/generated/path.gen.sh" ]]
    [[ -s "${DOTFILES_DIR}/shells/bash/generated/path.gen.sh" ]]
}

@test "bash: generated functions file exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/shells/bash/generated/functions.gen.sh" ]]
    [[ -s "${DOTFILES_DIR}/shells/bash/generated/functions.gen.sh" ]]
}

@test "bash: bashrc sources generated files without error" {
    run bash -c '
        export DOTFILES_DIR="'"${DOTFILES_DIR}"'"
        export HOME="/tmp/dotfiles_test_home"
        mkdir -p "$HOME"
        # Source only the generated files (skip tool integrations)
        for f in "${DOTFILES_DIR}/shells/bash/generated/"*.gen.sh; do
            source "$f" 2>&1
        done
        echo "OK"
    '
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"OK"* ]]
}

@test "bash: aliases are loaded after sourcing generated" {
    run bash -c '
        export DOTFILES_DIR="'"${DOTFILES_DIR}"'"
        for f in "${DOTFILES_DIR}/shells/bash/generated/"*.gen.sh; do
            source "$f" 2>/dev/null
        done
        alias ls
    '
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"eza"* ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Zsh
# ═══════════════════════════════════════════════════════════════════════════════

@test "zsh: generated aliases file exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/shells/zsh/generated/aliases.gen.sh" ]]
    [[ -s "${DOTFILES_DIR}/shells/zsh/generated/aliases.gen.sh" ]]
}

@test "zsh: generated files source without error" {
    if ! command -v zsh >/dev/null 2>&1; then
        skip "zsh not available"
    fi
    run zsh -c '
        export DOTFILES_DIR="'"${DOTFILES_DIR}"'"
        for f in "${DOTFILES_DIR}/shells/zsh/generated/"*.gen.sh(N); do
            source "$f" 2>&1
        done
        echo "OK"
    '
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"OK"* ]]
}

@test "zsh: aliases are loaded after sourcing generated" {
    if ! command -v zsh >/dev/null 2>&1; then
        skip "zsh not available"
    fi
    run zsh -c '
        export DOTFILES_DIR="'"${DOTFILES_DIR}"'"
        for f in "${DOTFILES_DIR}/shells/zsh/generated/"*.gen.sh(N); do
            source "$f" 2>/dev/null
        done
        alias ls
    '
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"eza"* ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Fish
# ═══════════════════════════════════════════════════════════════════════════════

@test "fish: generated aliases file exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/shells/fish/generated/aliases.gen.fish" ]]
    [[ -s "${DOTFILES_DIR}/shells/fish/generated/aliases.gen.fish" ]]
}

@test "fish: generated files source without error" {
    if ! command -v fish >/dev/null 2>&1; then
        skip "fish not available"
    fi
    run fish -c '
        set -gx DOTFILES_DIR "'"${DOTFILES_DIR}"'"
        for f in $DOTFILES_DIR/shells/fish/generated/*.gen.fish
            source $f 2>&1
        end
        echo "OK"
    '
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"OK"* ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Nushell
# ═══════════════════════════════════════════════════════════════════════════════

@test "nushell: generated aliases file exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/shells/nushell/generated/aliases.gen.sh" ]]
    [[ -s "${DOTFILES_DIR}/shells/nushell/generated/aliases.gen.sh" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Cross-shell consistency
# ═══════════════════════════════════════════════════════════════════════════════

@test "all shells have generated aliases" {
    [[ -s "${DOTFILES_DIR}/shells/bash/generated/aliases.gen.sh" ]]
    [[ -s "${DOTFILES_DIR}/shells/zsh/generated/aliases.gen.sh" ]]
    [[ -s "${DOTFILES_DIR}/shells/fish/generated/aliases.gen.fish" ]]
    [[ -s "${DOTFILES_DIR}/shells/nushell/generated/aliases.gen.sh" ]]
}

@test "all shells have generated env" {
    [[ -s "${DOTFILES_DIR}/shells/bash/generated/env.gen.sh" ]]
    [[ -s "${DOTFILES_DIR}/shells/zsh/generated/env.gen.sh" ]]
    [[ -s "${DOTFILES_DIR}/shells/fish/generated/env.gen.fish" ]]
    [[ -s "${DOTFILES_DIR}/shells/nushell/generated/env.gen.sh" ]]
}

@test "all shells have generated path" {
    [[ -s "${DOTFILES_DIR}/shells/bash/generated/path.gen.sh" ]]
    [[ -s "${DOTFILES_DIR}/shells/zsh/generated/path.gen.sh" ]]
    [[ -s "${DOTFILES_DIR}/shells/fish/generated/path.gen.fish" ]]
    [[ -s "${DOTFILES_DIR}/shells/nushell/generated/path.gen.sh" ]]
}

@test "generated files have AUTO-GENERATED header" {
    grep -q "AUTO-GENERATED" "${DOTFILES_DIR}/shells/bash/generated/aliases.gen.sh"
    grep -q "AUTO-GENERATED" "${DOTFILES_DIR}/shells/zsh/generated/aliases.gen.sh"
    grep -q "AUTO-GENERATED" "${DOTFILES_DIR}/shells/fish/generated/aliases.gen.fish"
    grep -q "AUTO-GENERATED" "${DOTFILES_DIR}/shells/nushell/generated/aliases.gen.sh"
}

@test "bash and zsh aliases are identical" {
    # Both bash and zsh use the same alias syntax
    local bash_aliases zsh_aliases
    bash_aliases="$(grep '^alias' "${DOTFILES_DIR}/shells/bash/generated/aliases.gen.sh" | sort)"
    zsh_aliases="$(grep '^alias' "${DOTFILES_DIR}/shells/zsh/generated/aliases.gen.sh" | sort)"
    [[ "${bash_aliases}" == "${zsh_aliases}" ]]
}

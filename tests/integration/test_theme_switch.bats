#!/usr/bin/env bats
# ═══════════════════════════════════════════════════════════════════════════════
# @file tests/integration/test_theme_switch.bats
# @description Integration tests for starship theme switcher and configs
# @since 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

setup() {
    export DOTFILES_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_COLOR=0
    export LOG_LEVEL=4

    _test_state="$(mktemp)"
    export STATE_FILE="${_test_state}"
    echo '{"version":1,"tools":{},"nix_envs":{},"theme":"minimal"}' > "${STATE_FILE}"

    export XDG_CONFIG_HOME="$(mktemp -d)"
}

teardown() {
    rm -f "${_test_state}"
    rm -rf "${XDG_CONFIG_HOME}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Starship theme files
# ═══════════════════════════════════════════════════════════════════════════════

@test "starship base.toml exists and is valid TOML" {
    [[ -s "${DOTFILES_DIR}/config/starship/base.toml" ]]
    if command -v taplo >/dev/null 2>&1; then
        taplo check "${DOTFILES_DIR}/config/starship/base.toml"
    fi
}

@test "starship minimal theme exists and is valid TOML" {
    [[ -s "${DOTFILES_DIR}/config/starship/themes/minimal.toml" ]]
    if command -v taplo >/dev/null 2>&1; then
        taplo check "${DOTFILES_DIR}/config/starship/themes/minimal.toml"
    fi
}

@test "starship full theme exists and is valid TOML" {
    [[ -s "${DOTFILES_DIR}/config/starship/themes/full.toml" ]]
    if command -v taplo >/dev/null 2>&1; then
        taplo check "${DOTFILES_DIR}/config/starship/themes/full.toml"
    fi
}

@test "starship powerline theme exists and is valid TOML" {
    [[ -s "${DOTFILES_DIR}/config/starship/themes/powerline.toml" ]]
    if command -v taplo >/dev/null 2>&1; then
        taplo check "${DOTFILES_DIR}/config/starship/themes/powerline.toml"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Theme switcher
# ═══════════════════════════════════════════════════════════════════════════════

@test "dotfiles-theme shows current theme" {
    local output
    output="$(bash "${DOTFILES_DIR}/bin/dotfiles-theme" 2>&1)"
    [[ "${output}" == *"minimal"* ]]
}

@test "dotfiles-theme switches to full" {
    bash "${DOTFILES_DIR}/bin/dotfiles-theme" full 2>&1
    [[ -f "${XDG_CONFIG_HOME}/starship.toml" ]]
    grep -q "catppuccin_mocha" "${XDG_CONFIG_HOME}/starship.toml"
}

@test "dotfiles-theme switches to powerline" {
    bash "${DOTFILES_DIR}/bin/dotfiles-theme" powerline 2>&1
    grep -q "bg:blue" "${XDG_CONFIG_HOME}/starship.toml"
}

@test "dotfiles-theme switches to minimal" {
    bash "${DOTFILES_DIR}/bin/dotfiles-theme" minimal 2>&1
    grep -q "disabled = true" "${XDG_CONFIG_HOME}/starship.toml"
}

@test "dotfiles-theme rejects invalid theme" {
    ! bash "${DOTFILES_DIR}/bin/dotfiles-theme" invalid_theme 2>&1
}

@test "dotfiles-theme persists theme in state" {
    bash "${DOTFILES_DIR}/bin/dotfiles-theme" full 2>&1
    local theme
    theme="$(jq -r '.theme' "${STATE_FILE}")"
    [[ "${theme}" == "full" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Tool configs
# ═══════════════════════════════════════════════════════════════════════════════

@test "git config exists and has core section" {
    [[ -s "${DOTFILES_DIR}/config/git/config" ]]
    grep -q "\[core\]" "${DOTFILES_DIR}/config/git/config"
}

@test "git config uses delta as pager" {
    grep -q "pager = delta" "${DOTFILES_DIR}/config/git/config"
}

@test "git config includes local overrides" {
    grep -q "gitconfig.local" "${DOTFILES_DIR}/config/git/config"
}

@test "git ignore exists and covers OS artifacts" {
    [[ -s "${DOTFILES_DIR}/config/git/ignore" ]]
    grep -q ".DS_Store" "${DOTFILES_DIR}/config/git/ignore"
    grep -q "node_modules" "${DOTFILES_DIR}/config/git/ignore"
}

@test "bat config exists and sets theme" {
    [[ -s "${DOTFILES_DIR}/config/bat/config" ]]
    grep -q "Catppuccin" "${DOTFILES_DIR}/config/bat/config"
}

@test "tmux config exists and sets prefix to Ctrl+a" {
    [[ -s "${DOTFILES_DIR}/config/tmux/tmux.conf" ]]
    grep -q "prefix C-a" "${DOTFILES_DIR}/config/tmux/tmux.conf"
}

@test "lazygit config exists and uses delta" {
    [[ -s "${DOTFILES_DIR}/config/lazygit/config.yml" ]]
    grep -q "delta" "${DOTFILES_DIR}/config/lazygit/config.yml"
}

@test "atuin config exists and uses fuzzy search" {
    [[ -s "${DOTFILES_DIR}/config/atuin/config.toml" ]]
    grep -q 'search_mode = "fuzzy"' "${DOTFILES_DIR}/config/atuin/config.toml"
}

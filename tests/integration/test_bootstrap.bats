#!/usr/bin/env bats
# ═══════════════════════════════════════════════════════════════════════════════
# @file tests/integration/test_bootstrap.bats
# @description Integration tests for platform detection and bootstrap routing
# @since 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

setup() {
    export DOTFILES_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_COLOR=0
    export LOG_LEVEL=4
    source "${DOTFILES_DIR}/lib/core/logger.sh"
    source "${DOTFILES_DIR}/lib/core/platform.sh"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Platform script existence
# ═══════════════════════════════════════════════════════════════════════════════

@test "platform/darwin/defaults.sh exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/platform/darwin/defaults.sh" ]]
    [[ -s "${DOTFILES_DIR}/platform/darwin/defaults.sh" ]]
}

@test "platform/darwin/brew.sh exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/platform/darwin/brew.sh" ]]
    [[ -s "${DOTFILES_DIR}/platform/darwin/brew.sh" ]]
}

@test "platform/darwin/Brewfile exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/platform/darwin/Brewfile" ]]
    [[ -s "${DOTFILES_DIR}/platform/darwin/Brewfile" ]]
}

@test "platform/linux/common.sh exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/platform/linux/common.sh" ]]
    [[ -s "${DOTFILES_DIR}/platform/linux/common.sh" ]]
}

@test "platform/linux/debian.sh exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/platform/linux/debian.sh" ]]
    [[ -s "${DOTFILES_DIR}/platform/linux/debian.sh" ]]
}

@test "platform/linux/arch.sh exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/platform/linux/arch.sh" ]]
    [[ -s "${DOTFILES_DIR}/platform/linux/arch.sh" ]]
}

@test "platform/linux/fedora.sh exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/platform/linux/fedora.sh" ]]
    [[ -s "${DOTFILES_DIR}/platform/linux/fedora.sh" ]]
}

@test "platform/linux/wsl.sh exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/platform/linux/wsl.sh" ]]
    [[ -s "${DOTFILES_DIR}/platform/linux/wsl.sh" ]]
}

@test "platform/bsd/common.sh exists and is non-empty" {
    [[ -f "${DOTFILES_DIR}/platform/bsd/common.sh" ]]
    [[ -s "${DOTFILES_DIR}/platform/bsd/common.sh" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Platform detection routing
# ═══════════════════════════════════════════════════════════════════════════════

@test "current platform is detected correctly" {
    Platform::detect
    [[ -n "${PLATFORM_OS}" ]]
    [[ -n "${PLATFORM_ARCH}" ]]
}

@test "darwin platform has brew as package manager" {
    if [[ "${PLATFORM_OS}" != "darwin" ]]; then
        skip "Not on macOS"
    fi
    local pm
    pm="$(Platform::package_manager)"
    [[ "${pm}" == "brew" ]]
}

@test "linux platform resolves correct package manager" {
    if [[ "${PLATFORM_OS}" != "linux" ]]; then
        skip "Not on Linux"
    fi
    local pm
    pm="$(Platform::package_manager)"
    [[ "${pm}" =~ ^(apt|dnf|pacman|apk|zypper|xbps|nix)$ ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Script structure validation
# ═══════════════════════════════════════════════════════════════════════════════

@test "all platform scripts have set -euo pipefail" {
    local script
    for script in platform/darwin/defaults.sh platform/darwin/brew.sh \
                  platform/linux/common.sh platform/linux/debian.sh \
                  platform/linux/arch.sh platform/linux/fedora.sh \
                  platform/linux/wsl.sh platform/bsd/common.sh; do
        grep -q "set -euo pipefail" "${DOTFILES_DIR}/${script}"
    done
}

@test "all platform scripts source logger" {
    local script
    for script in platform/darwin/defaults.sh platform/darwin/brew.sh \
                  platform/linux/common.sh platform/linux/debian.sh \
                  platform/linux/arch.sh platform/linux/fedora.sh \
                  platform/linux/wsl.sh platform/bsd/common.sh; do
        grep -q "lib/core/logger.sh" "${DOTFILES_DIR}/${script}"
    done
}

@test "platform scripts with functions call main at the end" {
    local script
    for script in platform/darwin/brew.sh \
                  platform/linux/common.sh platform/linux/debian.sh \
                  platform/linux/arch.sh platform/linux/fedora.sh \
                  platform/linux/wsl.sh platform/bsd/common.sh; do
        grep -q "^main" "${DOTFILES_DIR}/${script}"
    done
}

@test "bootstrap.sh runs linux/common.sh before distro script" {
    # Verify the scripts array ordering in bootstrap.sh
    local common_line distro_line
    common_line=$(grep -n "linux/common.sh" "${DOTFILES_DIR}/bootstrap.sh" | head -1 | cut -d: -f1)
    distro_line=$(grep -n "linux/debian.sh" "${DOTFILES_DIR}/bootstrap.sh" | head -1 | cut -d: -f1)
    [[ "${common_line}" -lt "${distro_line}" ]]
}

@test "bootstrap.sh runs wsl.sh after distro script" {
    local distro_line wsl_line
    distro_line=$(grep -n "linux/debian.sh" "${DOTFILES_DIR}/bootstrap.sh" | head -1 | cut -d: -f1)
    wsl_line=$(grep -n "linux/wsl.sh" "${DOTFILES_DIR}/bootstrap.sh" | head -1 | cut -d: -f1)
    [[ "${wsl_line}" -gt "${distro_line}" ]]
}

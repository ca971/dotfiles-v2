#!/usr/bin/env bats
# ═══════════════════════════════════════════════════════════════════════════════
# @file tests/unit/test_platform.bats
# @description Unit tests for lib/core/platform.sh
# @since 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

setup() {
    export DOTFILES_DIR="${BATS_TEST_DIRNAME}/../.."
    source "${DOTFILES_DIR}/lib/core/logger.sh"
    source "${DOTFILES_DIR}/lib/core/platform.sh"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Platform::detect_os
# ═══════════════════════════════════════════════════════════════════════════════

@test "Platform::detect_os sets PLATFORM_OS to a known value" {
    Platform::detect_os
    [[ "${PLATFORM_OS}" =~ ^(darwin|linux|freebsd|openbsd|netbsd|unknown)$ ]]
}

@test "Platform::detect_os is non-empty" {
    Platform::detect_os
    [[ -n "${PLATFORM_OS}" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Platform::detect_arch
# ═══════════════════════════════════════════════════════════════════════════════

@test "Platform::detect_arch sets PLATFORM_ARCH to a known value" {
    Platform::detect_arch
    [[ "${PLATFORM_ARCH}" =~ ^(x86_64|aarch64|armv7l|i686|.+)$ ]]
}

@test "Platform::detect_arch is non-empty" {
    Platform::detect_arch
    [[ -n "${PLATFORM_ARCH}" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Platform::detect_distro
# ═══════════════════════════════════════════════════════════════════════════════

@test "Platform::detect_distro sets PLATFORM_DISTRO" {
    Platform::detect_os
    Platform::detect_distro
    [[ -n "${PLATFORM_DISTRO}" ]]
}

@test "Platform::detect_distro returns OS name on non-linux" {
    PLATFORM_OS="darwin"
    Platform::detect_distro
    [[ "${PLATFORM_DISTRO}" == "darwin" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Platform::detect_wsl
# ═══════════════════════════════════════════════════════════════════════════════

@test "Platform::detect_wsl sets PLATFORM_IS_WSL to 0 on non-linux" {
    PLATFORM_OS="darwin"
    Platform::detect_wsl
    [[ "${PLATFORM_IS_WSL}" -eq 0 ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Platform::detect_ssh
# ═══════════════════════════════════════════════════════════════════════════════

@test "Platform::detect_ssh detects SSH_CLIENT" {
    export SSH_CLIENT="192.168.1.1 12345 22"
    Platform::detect_ssh
    [[ "${PLATFORM_IS_SSH}" -eq 1 ]]
}

@test "Platform::detect_ssh returns 0 without SSH vars" {
    unset SSH_CLIENT SSH_TTY SSH_CONNECTION 2>/dev/null || true
    Platform::detect_ssh
    [[ "${PLATFORM_IS_SSH}" -eq 0 ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Platform::is
# ═══════════════════════════════════════════════════════════════════════════════

@test "Platform::is matches current OS" {
    Platform::detect
    Platform::is "${PLATFORM_OS}"
}

@test "Platform::is returns false for wrong OS" {
    PLATFORM_OS="darwin"
    ! Platform::is "linux"
}

@test "Platform::is handles linux.distro format" {
    PLATFORM_OS="linux"
    PLATFORM_DISTRO="debian"
    Platform::is "linux.debian"
}

@test "Platform::is handles wsl specifier" {
    PLATFORM_IS_WSL=1
    Platform::is "wsl"
}

@test "Platform::is handles bsd specifier" {
    PLATFORM_OS="freebsd"
    Platform::is "bsd"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Platform::package_manager
# ═══════════════════════════════════════════════════════════════════════════════

@test "Platform::package_manager returns brew on darwin" {
    PLATFORM_OS="darwin"
    local result
    result="$(Platform::package_manager)"
    [[ "${result}" == "brew" ]]
}

@test "Platform::package_manager returns apt on debian" {
    PLATFORM_OS="linux"
    PLATFORM_DISTRO="debian"
    local result
    result="$(Platform::package_manager)"
    [[ "${result}" == "apt" ]]
}

@test "Platform::package_manager returns pacman on arch" {
    PLATFORM_OS="linux"
    PLATFORM_DISTRO="arch"
    local result
    result="$(Platform::package_manager)"
    [[ "${result}" == "pacman" ]]
}

@test "Platform::package_manager returns dnf on fedora" {
    PLATFORM_OS="linux"
    PLATFORM_DISTRO="fedora"
    local result
    result="$(Platform::package_manager)"
    [[ "${result}" == "dnf" ]]
}

@test "Platform::package_manager returns pkg on freebsd" {
    PLATFORM_OS="freebsd"
    local result
    result="$(Platform::package_manager)"
    [[ "${result}" == "pkg" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Platform::detect (full)
# ═══════════════════════════════════════════════════════════════════════════════

@test "Platform::detect populates all fields" {
    Platform::detect
    [[ -n "${PLATFORM_OS}" ]]
    [[ -n "${PLATFORM_DISTRO}" ]]
    [[ -n "${PLATFORM_ARCH}" ]]
}

@test "Platform::summary produces output" {
    Platform::detect
    local output
    output="$(Platform::summary)"
    [[ "${output}" == *"OS:"* ]]
    [[ "${output}" == *"Arch:"* ]]
}

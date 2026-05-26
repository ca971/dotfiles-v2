#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/hotload/adapters/system.sh
# @description System package manager adapter — last resort (priority 6)
# @class SystemAdapter
# @extends InstallerAdapter
# @since 1.0.0
# @version 1.0.0
#
# Dispatches to apt/dnf/pacman/apk/pkg based on detected platform.
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

SystemAdapter::is_available() {
    Platform::package_manager >/dev/null 2>&1
}

SystemAdapter::install() {
    local package="${1:?Package name required}"
    local _version="${2:-}"

    local pm
    pm="$(Platform::package_manager)" || return 1

    Logger::debug "SystemAdapter: installing ${package} via ${pm}"

    case "${pm}" in
        apt)     sudo apt-get install -y "${package}" 2>&1 ;;
        dnf)     sudo dnf install -y "${package}" 2>&1 ;;
        pacman)  sudo pacman -S --noconfirm --needed "${package}" 2>&1 ;;
        apk)     sudo apk add "${package}" 2>&1 ;;
        pkg)     sudo pkg install -y "${package}" 2>&1 ;;
        zypper)  sudo zypper install -y "${package}" 2>&1 ;;
        *)       Logger::error "SystemAdapter: unsupported package manager: ${pm}"; return 1 ;;
    esac
}

SystemAdapter::uninstall() {
    local package="${1:?Package name required}"

    local pm
    pm="$(Platform::package_manager)" || return 1

    Logger::debug "SystemAdapter: uninstalling ${package} via ${pm}"

    case "${pm}" in
        apt)     sudo apt-get remove -y "${package}" 2>&1 ;;
        dnf)     sudo dnf remove -y "${package}" 2>&1 ;;
        pacman)  sudo pacman -Rs --noconfirm "${package}" 2>&1 ;;
        apk)     sudo apk del "${package}" 2>&1 ;;
        pkg)     sudo pkg delete -y "${package}" 2>&1 ;;
        zypper)  sudo zypper remove -y "${package}" 2>&1 ;;
        *)       return 1 ;;
    esac
}

SystemAdapter::is_installed() {
    local package="${1:?Package name required}"

    local pm
    pm="$(Platform::package_manager)" || return 1

    case "${pm}" in
        apt)     dpkg -l "${package}" 2>/dev/null | grep -q "^ii" ;;
        dnf)     rpm -q "${package}" >/dev/null 2>&1 ;;
        pacman)  pacman -Qi "${package}" >/dev/null 2>&1 ;;
        apk)     apk info -e "${package}" >/dev/null 2>&1 ;;
        pkg)     pkg info "${package}" >/dev/null 2>&1 ;;
        zypper)  rpm -q "${package}" >/dev/null 2>&1 ;;
        *)       return 1 ;;
    esac
}

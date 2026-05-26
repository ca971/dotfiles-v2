#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/hotload/adapters/_base.sh
# @description Abstract base class for installer adapters
# @abstract class InstallerAdapter
# @since 1.0.0
# @version 1.0.0
# @see lib/hotload/engine.sh
#
# Each adapter implements:
#   Adapter::is_available   - Can this adapter run on the current system?
#   Adapter::install        - Install a tool
#   Adapter::uninstall      - Uninstall a tool
#   Adapter::is_installed   - Check if a tool is installed via this adapter
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# @abstract
# @description Check if this adapter's backend is available on the system
# @return 0 if available, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
InstallerAdapter::is_available() {
    Logger::error "InstallerAdapter::is_available() not implemented"
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# @abstract
# @description Install a tool using this adapter
# @param $1 {string} Package/plugin name
# @param $2 {string} Version (or "latest")
# @param $3 {string} [optional] Additional install command
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
InstallerAdapter::install() {
    Logger::error "InstallerAdapter::install() not implemented"
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# @abstract
# @description Uninstall a tool using this adapter
# @param $1 {string} Package/plugin name
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
InstallerAdapter::uninstall() {
    Logger::error "InstallerAdapter::uninstall() not implemented"
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# @abstract
# @description Check if a tool is currently installed via this adapter
# @param $1 {string} Package/plugin name
# @return 0 if installed, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
InstallerAdapter::is_installed() {
    Logger::error "InstallerAdapter::is_installed() not implemented"
    return 1
}

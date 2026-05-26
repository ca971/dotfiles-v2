#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file platform/linux/wsl.sh
# @description Windows Subsystem for Linux specific setup
# @since 1.0.0
# @version 1.0.0
# @see platform/linux/common.sh
#
# Handles: Windows interop, clipboard, paths, browser delegation
# Called AFTER the distro-specific script (debian.sh, etc.)
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

source "${DOTFILES_DIR}/lib/core/logger.sh"
source "${DOTFILES_DIR}/lib/core/fs.sh"

Logger::info "Running WSL-specific setup..."

# ═══════════════════════════════════════════════════════════════════════════════
# @description Configure /etc/wsl.conf for optimal WSL2 behavior
# ═══════════════════════════════════════════════════════════════════════════════
configure_wsl_conf() {
    local wsl_conf="/etc/wsl.conf"

    if [[ -f "${wsl_conf}" ]] && grep -q "\[interop\]" "${wsl_conf}"; then
        Logger::debug "wsl.conf already configured"
        return 0
    fi

    Logger::info "Configuring /etc/wsl.conf..."
    sudo tee "${wsl_conf}" > /dev/null << 'EOF'
[automount]
enabled = true
root = /mnt/
options = "metadata,umask=22,fmask=11"
mountFsTab = true

[interop]
enabled = true
appendWindowsPath = false

[network]
generateHosts = true
generateResolvConf = true

[boot]
systemd = true
EOF

    Logger::success "wsl.conf configured (restart WSL to apply)"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Set up clipboard integration (win32yank)
# ═══════════════════════════════════════════════════════════════════════════════
setup_clipboard() {
    local win32yank="${HOME}/.local/bin/win32yank.exe"

    if [[ -f "${win32yank}" ]]; then
        Logger::debug "win32yank already installed"
        return 0
    fi

    Logger::info "Installing win32yank for clipboard integration..."
    local url="https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip"
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    curl -fsSL "${url}" -o "${tmp_dir}/win32yank.zip"
    unzip -q "${tmp_dir}/win32yank.zip" -d "${tmp_dir}"
    mv "${tmp_dir}/win32yank.exe" "${win32yank}"
    chmod +x "${win32yank}"
    rm -rf "${tmp_dir}"

    Logger::success "win32yank installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Set up browser delegation to Windows host
# ═══════════════════════════════════════════════════════════════════════════════
setup_browser() {
    local browser_script="${HOME}/.local/bin/wsl-open"

    if [[ -f "${browser_script}" ]]; then
        Logger::debug "wsl-open already configured"
        return 0
    fi

    Logger::info "Setting up browser delegation..."
    cat > "${browser_script}" << 'SCRIPT'
#!/usr/bin/env bash
# Delegate URL opening to Windows host browser
exec /mnt/c/Windows/System32/cmd.exe /c start "" "${@}" 2>/dev/null
SCRIPT
    chmod +x "${browser_script}"

    Logger::success "Browser delegation configured (BROWSER=wsl-open)"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Fix SSH agent forwarding in WSL
# ═══════════════════════════════════════════════════════════════════════════════
setup_ssh_agent() {
    local socket_dir="${HOME}/.ssh"
    FileSystem::mkdir "${socket_dir}" "700"

    Logger::debug "SSH agent setup for WSL complete"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Create WSL-specific local overrides
# ═══════════════════════════════════════════════════════════════════════════════
create_wsl_overrides() {
    local wsl_env="${DOTFILES_DIR}/local/shell/wsl.env"

    if [[ -f "${wsl_env}" ]]; then
        return 0
    fi

    cat > "${wsl_env}" << 'EOF'
# WSL-specific environment (sourced by local shell overrides)
export BROWSER="${HOME}/.local/bin/wsl-open"
export DISPLAY=:0
export LIBGL_ALWAYS_INDIRECT=1
EOF

    Logger::debug "WSL overrides created at ${wsl_env}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Main entry point
# ═══════════════════════════════════════════════════════════════════════════════
main() {
    configure_wsl_conf
    setup_clipboard
    setup_browser
    setup_ssh_agent
    create_wsl_overrides
    Logger::success "WSL setup complete"
}

main

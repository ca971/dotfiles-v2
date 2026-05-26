#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/core/platform.sh
# @description Cross-platform OS/distro/architecture detection engine
# @class Platform
# @since 1.0.0
# @version 1.0.0
# @see docs/ARCHITECTURE.md
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────────────────────
# @field PLATFORM_OS
# @type string
# @description Detected operating system (darwin, linux, freebsd, openbsd, netbsd)
# ───────────────────────────────────────────────────────────────────────────────
declare -g PLATFORM_OS=""

# ───────────────────────────────────────────────────────────────────────────────
# @field PLATFORM_DISTRO
# @type string
# @description Linux distribution (debian, ubuntu, arch, fedora, alpine, nixos, unknown)
# ───────────────────────────────────────────────────────────────────────────────
declare -g PLATFORM_DISTRO=""

# ───────────────────────────────────────────────────────────────────────────────
# @field PLATFORM_ARCH
# @type string
# @description CPU architecture (x86_64, aarch64, armv7l)
# ───────────────────────────────────────────────────────────────────────────────
declare -g PLATFORM_ARCH=""

# ───────────────────────────────────────────────────────────────────────────────
# @field PLATFORM_IS_WSL
# @type boolean (0|1)
# @description Whether running inside Windows Subsystem for Linux
# ───────────────────────────────────────────────────────────────────────────────
declare -g PLATFORM_IS_WSL=0

# ───────────────────────────────────────────────────────────────────────────────
# @field PLATFORM_IS_CONTAINER
# @type boolean (0|1)
# @description Whether running inside a container (Docker, Podman, LXC)
# ───────────────────────────────────────────────────────────────────────────────
declare -g PLATFORM_IS_CONTAINER=0

# ───────────────────────────────────────────────────────────────────────────────
# @field PLATFORM_IS_SSH
# @type boolean (0|1)
# @description Whether running inside an SSH session
# ───────────────────────────────────────────────────────────────────────────────
declare -g PLATFORM_IS_SSH=0

# ───────────────────────────────────────────────────────────────────────────────
# @field PLATFORM_HAS_GUI
# @type boolean (0|1)
# @description Whether a graphical display is available
# ───────────────────────────────────────────────────────────────────────────────
declare -g PLATFORM_HAS_GUI=0

# ═══════════════════════════════════════════════════════════════════════════════
# @description Detect the operating system kernel
# @return Sets PLATFORM_OS global variable
# ═══════════════════════════════════════════════════════════════════════════════
Platform::detect_os() {
    local kernel
    kernel="$(uname -s | tr '[:upper:]' '[:lower:]')"

    case "${kernel}" in
        darwin)  PLATFORM_OS="darwin" ;;
        linux)   PLATFORM_OS="linux" ;;
        freebsd) PLATFORM_OS="freebsd" ;;
        openbsd) PLATFORM_OS="openbsd" ;;
        netbsd)  PLATFORM_OS="netbsd" ;;
        *)       PLATFORM_OS="unknown" ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Detect Linux distribution from /etc/os-release
# @return Sets PLATFORM_DISTRO global variable
# ═══════════════════════════════════════════════════════════════════════════════
Platform::detect_distro() {
    PLATFORM_DISTRO="unknown"

    if [[ "${PLATFORM_OS}" != "linux" ]]; then
        PLATFORM_DISTRO="${PLATFORM_OS}"
        return 0
    fi

    if [[ -f /etc/os-release ]]; then
        local id
        id="$(. /etc/os-release && echo "${ID:-unknown}")"
        case "${id}" in
            debian|ubuntu|linuxmint|pop) PLATFORM_DISTRO="debian" ;;
            arch|manjaro|endeavouros)    PLATFORM_DISTRO="arch" ;;
            fedora|rhel|centos|rocky)    PLATFORM_DISTRO="fedora" ;;
            alpine)                      PLATFORM_DISTRO="alpine" ;;
            nixos)                       PLATFORM_DISTRO="nixos" ;;
            opensuse*|sles)              PLATFORM_DISTRO="suse" ;;
            void)                        PLATFORM_DISTRO="void" ;;
            *)                           PLATFORM_DISTRO="${id}" ;;
        esac
    elif [[ -f /etc/debian_version ]]; then
        PLATFORM_DISTRO="debian"
    elif [[ -f /etc/arch-release ]]; then
        PLATFORM_DISTRO="arch"
    elif [[ -f /etc/fedora-release ]]; then
        PLATFORM_DISTRO="fedora"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Detect CPU architecture and normalize naming
# @return Sets PLATFORM_ARCH global variable
# ═══════════════════════════════════════════════════════════════════════════════
Platform::detect_arch() {
    local machine
    machine="$(uname -m)"

    case "${machine}" in
        x86_64|amd64)    PLATFORM_ARCH="x86_64" ;;
        aarch64|arm64)   PLATFORM_ARCH="aarch64" ;;
        armv7l|armhf)    PLATFORM_ARCH="armv7l" ;;
        i686|i386)       PLATFORM_ARCH="i686" ;;
        *)               PLATFORM_ARCH="${machine}" ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Detect if running inside WSL (Windows Subsystem for Linux)
# @return Sets PLATFORM_IS_WSL global variable (0 or 1)
# ═══════════════════════════════════════════════════════════════════════════════
Platform::detect_wsl() {
    PLATFORM_IS_WSL=0

    if [[ "${PLATFORM_OS}" != "linux" ]]; then
        return 0
    fi

    if [[ -f /proc/version ]] && grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
        PLATFORM_IS_WSL=1
    elif [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        PLATFORM_IS_WSL=1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Detect if running inside a container (Docker, Podman, LXC)
# @return Sets PLATFORM_IS_CONTAINER global variable (0 or 1)
# ═══════════════════════════════════════════════════════════════════════════════
Platform::detect_container() {
    PLATFORM_IS_CONTAINER=0

    if [[ -f /.dockerenv ]]; then
        PLATFORM_IS_CONTAINER=1
    elif [[ -f /run/.containerenv ]]; then
        PLATFORM_IS_CONTAINER=1
    elif [[ -f /proc/1/cgroup ]] && grep -q "docker\|lxc\|kubepods\|containerd" /proc/1/cgroup 2>/dev/null; then
        PLATFORM_IS_CONTAINER=1
    elif [[ "${container:-}" == "lxc" ]]; then
        PLATFORM_IS_CONTAINER=1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Detect if running inside an SSH session
# @return Sets PLATFORM_IS_SSH global variable (0 or 1)
# ═══════════════════════════════════════════════════════════════════════════════
Platform::detect_ssh() {
    PLATFORM_IS_SSH=0

    if [[ -n "${SSH_CLIENT:-}" ]] || [[ -n "${SSH_TTY:-}" ]] || [[ -n "${SSH_CONNECTION:-}" ]]; then
        PLATFORM_IS_SSH=1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Detect if a graphical display server is available
# @return Sets PLATFORM_HAS_GUI global variable (0 or 1)
# ═══════════════════════════════════════════════════════════════════════════════
Platform::detect_gui() {
    PLATFORM_HAS_GUI=0

    case "${PLATFORM_OS}" in
        darwin)
            PLATFORM_HAS_GUI=1
            ;;
        linux)
            if [[ -n "${DISPLAY:-}" ]] || [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
                PLATFORM_HAS_GUI=1
            fi
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Run all detection routines and populate global state
# @return Sets all PLATFORM_* global variables
# ═══════════════════════════════════════════════════════════════════════════════
Platform::detect() {
    Platform::detect_os
    Platform::detect_distro
    Platform::detect_arch
    Platform::detect_wsl
    Platform::detect_container
    Platform::detect_ssh
    Platform::detect_gui
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check if current platform matches a given specifier
# @param $1 {string} Platform specifier (darwin, linux, linux.debian, wsl, bsd)
# @return 0 if match, 1 otherwise
# @example Platform::is "linux.debian" && echo "Debian-based system"
# ═══════════════════════════════════════════════════════════════════════════════
Platform::is() {
    local spec="${1:?Platform specifier required}"

    case "${spec}" in
        darwin)
            [[ "${PLATFORM_OS}" == "darwin" ]]
            ;;
        linux)
            [[ "${PLATFORM_OS}" == "linux" ]]
            ;;
        linux.*)
            local distro="${spec#linux.}"
            [[ "${PLATFORM_OS}" == "linux" ]] && [[ "${PLATFORM_DISTRO}" == "${distro}" ]]
            ;;
        wsl)
            [[ "${PLATFORM_IS_WSL}" -eq 1 ]]
            ;;
        bsd)
            [[ "${PLATFORM_OS}" == "freebsd" ]] || [[ "${PLATFORM_OS}" == "openbsd" ]] || [[ "${PLATFORM_OS}" == "netbsd" ]]
            ;;
        container)
            [[ "${PLATFORM_IS_CONTAINER}" -eq 1 ]]
            ;;
        ssh)
            [[ "${PLATFORM_IS_SSH}" -eq 1 ]]
            ;;
        gui)
            [[ "${PLATFORM_HAS_GUI}" -eq 1 ]]
            ;;
        *)
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Get the system package manager command for the current platform
# @return Prints the package manager name (brew, apt, dnf, pacman, pkg, apk)
# @throws Returns 1 if no known package manager found
# ═══════════════════════════════════════════════════════════════════════════════
Platform::package_manager() {
    case "${PLATFORM_OS}" in
        darwin)
            echo "brew"
            ;;
        linux)
            case "${PLATFORM_DISTRO}" in
                debian)  echo "apt" ;;
                arch)    echo "pacman" ;;
                fedora)  echo "dnf" ;;
                alpine)  echo "apk" ;;
                suse)    echo "zypper" ;;
                void)    echo "xbps" ;;
                nixos)   echo "nix" ;;
                *)       return 1 ;;
            esac
            ;;
        freebsd|openbsd|netbsd)
            echo "pkg"
            ;;
        *)
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Print a summary of detected platform information
# @return Prints formatted platform summary to stdout
# ═══════════════════════════════════════════════════════════════════════════════
Platform::summary() {
    cat <<-EOF
	Platform Summary:
	  OS:        ${PLATFORM_OS}
	  Distro:    ${PLATFORM_DISTRO}
	  Arch:      ${PLATFORM_ARCH}
	  WSL:       ${PLATFORM_IS_WSL}
	  Container: ${PLATFORM_IS_CONTAINER}
	  SSH:       ${PLATFORM_IS_SSH}
	  GUI:       ${PLATFORM_HAS_GUI}
	EOF
}

# Auto-detect on source
Platform::detect

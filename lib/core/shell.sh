#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/core/shell.sh
# @description Shell detection and capability introspection
# @class ShellDetector
# @since 1.0.0
# @version 1.0.0
# @see docs/ARCHITECTURE.md
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────────────────────
# @field SHELL_NAME
# @type string
# @description Current shell name (bash, zsh, fish, nushell)
# ───────────────────────────────────────────────────────────────────────────────
declare -g SHELL_NAME=""

# ───────────────────────────────────────────────────────────────────────────────
# @field SHELL_VERSION
# @type string
# @description Current shell version string
# ───────────────────────────────────────────────────────────────────────────────
declare -g SHELL_VERSION=""

# ───────────────────────────────────────────────────────────────────────────────
# @field SHELL_IS_INTERACTIVE
# @type boolean (0|1)
# @description Whether shell is running interactively
# ───────────────────────────────────────────────────────────────────────────────
declare -g SHELL_IS_INTERACTIVE=0

# ───────────────────────────────────────────────────────────────────────────────
# @field SHELL_IS_LOGIN
# @type boolean (0|1)
# @description Whether shell is a login shell
# ───────────────────────────────────────────────────────────────────────────────
declare -g SHELL_IS_LOGIN=0

# ═══════════════════════════════════════════════════════════════════════════════
# @description Detect the current shell name from process or environment
# @return Sets SHELL_NAME global variable
# ═══════════════════════════════════════════════════════════════════════════════
ShellDetector::detect_name() {
    SHELL_NAME=""

    if [[ -n "${BASH_VERSION:-}" ]]; then
        SHELL_NAME="bash"
    elif [[ -n "${ZSH_VERSION:-}" ]]; then
        SHELL_NAME="zsh"
    elif [[ -n "${FISH_VERSION:-}" ]]; then
        SHELL_NAME="fish"
    elif [[ -n "${NU_VERSION:-}" ]]; then
        SHELL_NAME="nushell"
    else
        local shell_path
        shell_path="$(ps -p $$ -o comm= 2>/dev/null || echo "")"
        case "${shell_path}" in
            *bash)    SHELL_NAME="bash" ;;
            *zsh)     SHELL_NAME="zsh" ;;
            *fish)    SHELL_NAME="fish" ;;
            *nu)      SHELL_NAME="nushell" ;;
            *)        SHELL_NAME="unknown" ;;
        esac
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Detect the current shell version
# @return Sets SHELL_VERSION global variable
# ═══════════════════════════════════════════════════════════════════════════════
ShellDetector::detect_version() {
    SHELL_VERSION=""

    case "${SHELL_NAME}" in
        bash)
            SHELL_VERSION="${BASH_VERSION:-unknown}"
            ;;
        zsh)
            SHELL_VERSION="${ZSH_VERSION:-unknown}"
            ;;
        fish)
            SHELL_VERSION="${FISH_VERSION:-unknown}"
            ;;
        nushell)
            SHELL_VERSION="${NU_VERSION:-unknown}"
            ;;
        *)
            SHELL_VERSION="unknown"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Detect if shell is running interactively
# @return Sets SHELL_IS_INTERACTIVE global variable (0 or 1)
# ═══════════════════════════════════════════════════════════════════════════════
ShellDetector::detect_interactive() {
    SHELL_IS_INTERACTIVE=0

    case "${SHELL_NAME}" in
        bash)
            if [[ "$-" == *i* ]]; then
                SHELL_IS_INTERACTIVE=1
            fi
            ;;
        zsh)
            if [[ -o interactive ]] 2>/dev/null; then
                SHELL_IS_INTERACTIVE=1
            fi
            ;;
        *)
            if [[ -t 0 ]]; then
                SHELL_IS_INTERACTIVE=1
            fi
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Detect if shell is a login shell
# @return Sets SHELL_IS_LOGIN global variable (0 or 1)
# ═══════════════════════════════════════════════════════════════════════════════
ShellDetector::detect_login() {
    SHELL_IS_LOGIN=0

    case "${SHELL_NAME}" in
        bash)
            if shopt -q login_shell 2>/dev/null; then
                SHELL_IS_LOGIN=1
            fi
            ;;
        zsh)
            if [[ -o login ]] 2>/dev/null; then
                SHELL_IS_LOGIN=1
            fi
            ;;
        *)
            if [[ "${0}" == -* ]]; then
                SHELL_IS_LOGIN=1
            fi
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Run all shell detection routines
# @return Sets all SHELL_* global variables
# ═══════════════════════════════════════════════════════════════════════════════
ShellDetector::detect() {
    ShellDetector::detect_name
    ShellDetector::detect_version
    ShellDetector::detect_interactive
    ShellDetector::detect_login
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check if current shell matches a given name
# @param $1 {string} Shell name to check (bash, zsh, fish, nushell)
# @return 0 if match, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
ShellDetector::is() {
    local name="${1:?Shell name required}"
    [[ "${SHELL_NAME}" == "${name}" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check if current shell version meets minimum requirement
# @param $1 {string} Minimum version (e.g., "4.0")
# @return 0 if version >= minimum, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
ShellDetector::version_gte() {
    local required="${1:?Version required}"
    local current="${SHELL_VERSION%%(*}"

    local IFS='.'
    local -a req_parts curr_parts
    read -ra req_parts <<< "${required}"
    read -ra curr_parts <<< "${current}"

    local i
    for i in "${!req_parts[@]}"; do
        local req_num="${req_parts[i]:-0}"
        local curr_num="${curr_parts[i]:-0}"

        if (( curr_num > req_num )); then
            return 0
        elif (( curr_num < req_num )); then
            return 1
        fi
    done

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Get the path to the generated config directory for current shell
# @return Prints the path to shells/<name>/generated/
# ═══════════════════════════════════════════════════════════════════════════════
ShellDetector::generated_dir() {
    local dotfiles_dir="${DOTFILES_DIR:-${HOME}/.dotfiles}"
    echo "${dotfiles_dir}/shells/${SHELL_NAME}/generated"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Print shell detection summary
# @return Prints formatted shell info to stdout
# ═══════════════════════════════════════════════════════════════════════════════
ShellDetector::summary() {
    cat <<-EOF
	Shell Summary:
	  Name:        ${SHELL_NAME}
	  Version:     ${SHELL_VERSION}
	  Interactive: ${SHELL_IS_INTERACTIVE}
	  Login:       ${SHELL_IS_LOGIN}
	EOF
}

# Auto-detect on source
ShellDetector::detect

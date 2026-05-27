#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file install.sh
# @description One-liner bootstrap entry point (curl-pipeable)
# @since 1.0.0
# @version 1.1.0
# @see bootstrap.sh
#
# One-liner (installs minimal profile by default):
#   curl -fsSL https://raw.githubusercontent.com/ca/dotfiles/main/install.sh | bash
#
# With custom profile:
#   curl -fsSL https://raw.githubusercontent.com/ca/dotfiles/main/install.sh | bash -s -- --profile dev
#
# Dry-run:
#   curl -fsSL https://raw.githubusercontent.com/ca/dotfiles/main/install.sh | bash -s -- --dry-run
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────────────────────
# Configuration
# ───────────────────────────────────────────────────────────────────────────────
readonly DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/ca/dotfiles.git}"
readonly DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/.dotfiles}"
readonly DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"

# ───────────────────────────────────────────────────────────────────────────────
# Colors (safe for non-interactive)
# ───────────────────────────────────────────────────────────────────────────────
if [[ -t 1 ]] && [[ "${NO_COLOR:-}" != "1" ]]; then
    readonly RED="\033[31m"
    readonly GREEN="\033[32m"
    readonly YELLOW="\033[33m"
    readonly BLUE="\033[34m"
    readonly RESET="\033[0m"
else
    readonly RED="" GREEN="" YELLOW="" BLUE="" RESET=""
fi

# ───────────────────────────────────────────────────────────────────────────────
# Helpers
# ───────────────────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${RESET} $*" >&2; }
success() { echo -e "${GREEN}[OK]${RESET}   $*" >&2; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $*" >&2; }
error()   { echo -e "${RED}[ERR]${RESET}  $*" >&2; }
fatal()   { error "$*"; exit 1; }

# ═══════════════════════════════════════════════════════════════════════════════
# @description Verify minimal system requirements before proceeding
# ═══════════════════════════════════════════════════════════════════════════════
preflight_check() {
    info "Running preflight checks..."

    if ! command -v bash >/dev/null 2>&1; then
        fatal "bash is required but not found"
    fi

    local bash_major
    bash_major="${BASH_VERSION%%.*}"
    if (( bash_major < 4 )); then
        fatal "bash >= 4.0 required (found: ${BASH_VERSION})"
    fi

    if ! command -v curl >/dev/null 2>&1; then
        fatal "curl is required but not found"
    fi

    if ! command -v git >/dev/null 2>&1; then
        fatal "git is required but not found"
    fi

    success "Preflight checks passed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Clone or update the dotfiles repository
# ═══════════════════════════════════════════════════════════════════════════════
clone_dotfiles() {
    if [[ -d "${DOTFILES_DIR}" ]]; then
        info "Dotfiles directory exists, pulling latest..."
        git -C "${DOTFILES_DIR}" pull --rebase --quiet origin "${DOTFILES_BRANCH}"
        success "Dotfiles updated"
    else
        info "Cloning dotfiles repository..."
        git clone --branch "${DOTFILES_BRANCH}" --depth 1 "${DOTFILES_REPO}" "${DOTFILES_DIR}"
        success "Dotfiles cloned to ${DOTFILES_DIR}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Hand off to the full bootstrap script
# ═══════════════════════════════════════════════════════════════════════════════
run_bootstrap() {
    local bootstrap="${DOTFILES_DIR}/bootstrap.sh"

    if [[ ! -x "${bootstrap}" ]]; then
        fatal "Bootstrap script not found or not executable: ${bootstrap}"
    fi

    info "Handing off to bootstrap.sh (default: minimal profile)..."
    # Always prepend --minimal; explicit --profile <name> overrides it
    exec "${bootstrap}" --minimal "$@"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Main entry point
# ═══════════════════════════════════════════════════════════════════════════════
main() {
    echo -e "${BLUE}"
    cat << 'BANNER'
    ╔══════════════════════════════════════════╗
    ║        DOTFILES INSTALLER v1.0.0         ║
    ║   Enterprise-grade, cross-platform       ║
    ╚══════════════════════════════════════════╝
BANNER
    echo -e "${RESET}"

    preflight_check
    clone_dotfiles
    run_bootstrap "$@"
}

main "$@"

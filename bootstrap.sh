#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file bootstrap.sh
# @description Full system provisioning orchestrator
# @since 1.0.0
# @version 1.0.0
# @see install.sh
# @see docs/ARCHITECTURE.md
#
# Usage:
#   ./bootstrap.sh              # Full install (interactive)
#   ./bootstrap.sh --minimal    # Core tools only
#   ./bootstrap.sh --no-gui     # Skip GUI apps
#   ./bootstrap.sh --dry-run    # Show what would be done
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────────────────────
# Resolve DOTFILES_DIR from script location
# Resolve DOTFILES_DIR from script location (always trust the script's own path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
# Only use env var if it points to an existing directory; otherwise use script location
if [[ -n "${DOTFILES_DIR:-}" ]] && [[ -d "${DOTFILES_DIR}/lib/core" ]]; then
    export DOTFILES_DIR="${DOTFILES_DIR}"
else
    export DOTFILES_DIR="${SCRIPT_DIR}"
fi

# ───────────────────────────────────────────────────────────────────────────────
# Source core libraries
# ───────────────────────────────────────────────────────────────────────────────
# shellcheck source=lib/core/logger.sh
source "${DOTFILES_DIR}/lib/core/logger.sh"
# shellcheck source=lib/core/platform.sh
source "${DOTFILES_DIR}/lib/core/platform.sh"
# shellcheck source=lib/core/shell.sh
source "${DOTFILES_DIR}/lib/core/shell.sh"
# shellcheck source=lib/core/validator.sh
source "${DOTFILES_DIR}/lib/core/validator.sh"
# shellcheck source=lib/core/fs.sh
source "${DOTFILES_DIR}/lib/core/fs.sh"
# shellcheck source=lib/core/net.sh
source "${DOTFILES_DIR}/lib/core/net.sh"

# ───────────────────────────────────────────────────────────────────────────────
# Bootstrap options
# ───────────────────────────────────────────────────────────────────────────────
# shellcheck disable=SC2034
declare OPT_MINIMAL=0
# shellcheck disable=SC2034
declare OPT_NO_GUI=0
declare OPT_DRY_RUN=0
# shellcheck disable=SC2034
declare OPT_VERBOSE=0
# shellcheck disable=SC2034
declare OPT_PROFILE="dev"
# shellcheck disable=SC2034
declare OPT_PROFILE_EXPLICIT=0
# shellcheck disable=SC2034
declare OPT_INTERACTIVE=0

# ═══════════════════════════════════════════════════════════════════════════════
# @description Parse command-line arguments
# @param $@ {string} Arguments from command line
# ═══════════════════════════════════════════════════════════════════════════════
# shellcheck disable=SC2034
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --minimal)   OPT_MINIMAL=1 ;;
            --no-gui)    OPT_NO_GUI=1 ;;
            --dry-run)   OPT_DRY_RUN=1 ;;
            --verbose)   OPT_VERBOSE=1; Logger::set_level "debug" ;;
            --profile)   OPT_PROFILE="${2:?Profile name required after --profile}"; OPT_PROFILE_EXPLICIT=1; shift ;;
            --interactive) OPT_INTERACTIVE=1 ;;
            --help|-h)   show_help; exit 0 ;;
            *)           Logger::warn "Unknown option: ${1}" ;;
        esac
        shift
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Display help message
# ═══════════════════════════════════════════════════════════════════════════════
show_help() {
    cat <<-EOF
	Usage: bootstrap.sh [OPTIONS]

	Options:
	    --minimal    Install core tools only (skip extras)
	    --no-gui     Skip GUI applications
	    --dry-run    Show what would be done without executing
	    --verbose    Enable debug logging
	    --profile    Tool profile to install: minimal, dev, server, devops, data, ai, full (default: dev)
	    --interactive  Interactive mode: choose shell, profile, and confirm
	    --help, -h   Show this help message

	Environment:
	  DOTFILES_DIR    Override dotfiles location (default: ~/.dotfiles)
	  LOG_LEVEL       Set log level: 0=debug, 1=info, 2=warn, 3=error
	EOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Ensure local vault directory structure exists
# ═══════════════════════════════════════════════════════════════════════════════
setup_local_vault() {
    Logger::step 1 7 "Setting up local vault..."

    FileSystem::mkdir "${DOTFILES_DIR}/local" "755"
    FileSystem::ensure_private_dir "${DOTFILES_DIR}/local/secrets"
    FileSystem::ensure_private_dir "${DOTFILES_DIR}/local/ssh"
    FileSystem::ensure_private_dir "${DOTFILES_DIR}/local/ssh/keys"
    FileSystem::mkdir "${DOTFILES_DIR}/local/shell" "755"
    FileSystem::mkdir "${DOTFILES_DIR}/local/config" "755"

    if [[ ! -f "${DOTFILES_DIR}/local/state.json" ]]; then
        echo '{"version":1,"tools":{},"nix_envs":{},"theme":"minimal"}' \
            > "${DOTFILES_DIR}/local/state.json"
    fi

    Logger::success "Local vault ready"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install hard dependencies required before anything else
# ═══════════════════════════════════════════════════════════════════════════════
install_hard_deps() {
    Logger::step 2 7 "Installing hard dependencies..."

    # jq
    if ! Validator::command_exists "jq"; then
        Logger::info "Installing jq..."
        if [[ "${OPT_DRY_RUN}" -eq 0 ]]; then
            install_package "jq"
        fi
    fi

    # mise
    if ! Validator::command_exists "mise"; then
        Logger::info "Installing mise..."
        if [[ "${OPT_DRY_RUN}" -eq 0 ]]; then
            curl -fsSL https://mise.run | sh
            export PATH="${HOME}/.local/bin:${PATH}"
        fi
    fi

    # uv
    if ! Validator::command_exists "uv"; then
        Logger::info "Installing uv..."
        if [[ "${OPT_DRY_RUN}" -eq 0 ]]; then
            curl -LsSf https://astral.sh/uv/install.sh | sh
            export PATH="${HOME}/.local/bin:${PATH}"
        fi
    fi

    # python3 (via mise if not present)
    if ! Validator::command_exists "python3"; then
        Logger::info "Installing Python via mise..."
        if [[ "${OPT_DRY_RUN}" -eq 0 ]]; then
            mise install python@latest
            mise use --global python@latest
        fi
    fi

    Logger::success "Hard dependencies satisfied"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install a package using the system package manager
# @param $1 {string} Package name
# ═══════════════════════════════════════════════════════════════════════════════
install_package() {
    local pkg="${1:?Package name required}"
    local pm

    pm="$(Platform::package_manager)" || {
        Logger::error "No known package manager for this platform"
        return 1
    }

    case "${pm}" in
        brew)    brew install "${pkg}" ;;
        apt)     sudo apt-get install -y "${pkg}" ;;
        dnf)     sudo dnf install -y "${pkg}" ;;
        pacman)  sudo pacman -S --noconfirm "${pkg}" ;;
        apk)     sudo apk add "${pkg}" ;;
        pkg)     sudo pkg install -y "${pkg}" ;;
        zypper)  sudo zypper install -y "${pkg}" ;;
        *)       Logger::error "Unsupported package manager: ${pm}"; return 1 ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Run the SSOT generators to produce shell-specific configs
# ═══════════════════════════════════════════════════════════════════════════════
run_generators() {
    Logger::step 3 7 "Running SSOT generators..."

    local gen_dir="${DOTFILES_DIR}/generators"

    if [[ ! -f "${gen_dir}/pyproject.toml" ]] || [[ ! -s "${gen_dir}/pyproject.toml" ]]; then
        Logger::warn "Generators not yet implemented, skipping..."
        return 0
    fi

    if [[ "${OPT_DRY_RUN}" -eq 0 ]]; then
        (cd "${gen_dir}" && uv run python -m src.cli generate --all)
    fi

    Logger::success "Shell configs generated"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Create symlinks for config files
# ═══════════════════════════════════════════════════════════════════════════════
setup_symlinks() {
    Logger::step 4 7 "Setting up symlinks..."

    local xdg_config="${XDG_CONFIG_HOME:-${HOME}/.config}"
    FileSystem::mkdir "${xdg_config}"

    local -a configs=(
        "starship"
        "git"
        "bat"
        "lazygit"
        "atuin"
        "yazi"
        "zellij"
        "tmux"
        "wezterm"
        "broot"
        "btop"
        "direnv"
        "mise"
    )

    for config in "${configs[@]}"; do
        local src="${DOTFILES_DIR}/config/${config}"
        local dst="${xdg_config}/${config}"

        if [[ -d "${src}" ]] && [[ "$(ls -A "${src}" 2>/dev/null)" ]]; then
            if [[ "${OPT_DRY_RUN}" -eq 1 ]]; then
                Logger::info "[dry-run] Would symlink: ${dst} -> ${src}"
            else
                FileSystem::symlink "${src}" "${dst}" 1
            fi
        fi
    done

    Logger::success "Symlinks configured"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Run platform-specific provisioning
# ═══════════════════════════════════════════════════════════════════════════════
setup_platform() {
    Logger::step 5 7 "Running platform-specific setup..."

    local -a scripts=()

    if Platform::is "darwin"; then
        scripts+=("${DOTFILES_DIR}/platform/darwin/brew.sh")
        scripts+=("${DOTFILES_DIR}/platform/darwin/defaults.sh")
    elif Platform::is "linux"; then
        scripts+=("${DOTFILES_DIR}/platform/linux/common.sh")

        if Platform::is "linux.debian"; then
            scripts+=("${DOTFILES_DIR}/platform/linux/debian.sh")
        elif Platform::is "linux.arch"; then
            scripts+=("${DOTFILES_DIR}/platform/linux/arch.sh")
        elif Platform::is "linux.fedora"; then
            scripts+=("${DOTFILES_DIR}/platform/linux/fedora.sh")
        fi

        if Platform::is "wsl"; then
            scripts+=("${DOTFILES_DIR}/platform/linux/wsl.sh")
        fi
    elif Platform::is "bsd"; then
        scripts+=("${DOTFILES_DIR}/platform/bsd/common.sh")
    fi

    local script
    for script in "${scripts[@]}"; do
        if [[ -f "${script}" ]] && [[ -s "${script}" ]]; then
            if [[ "${OPT_DRY_RUN}" -eq 0 ]]; then
                Logger::info "Running: ${script##*/}"
                # shellcheck source=/dev/null
                source "${script}"
            else
                Logger::info "[dry-run] Would run: ${script##*/}"
            fi
        fi
    done

    Logger::success "Platform setup complete"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install tools via the hot-loading engine
# ═══════════════════════════════════════════════════════════════════════════════
install_tools() {
    Logger::step 6 7 "Installing tools..."

    local engine="${DOTFILES_DIR}/lib/hotload/engine.sh"

    if [[ ! -s "${engine}" ]]; then
        Logger::warn "Hot-load engine not yet implemented, skipping tools installation"
        return 0
    fi

    # Determine profile: --profile <name> takes priority over --minimal,
    # then fall back to state.json or default "dev"
    local profile="${OPT_PROFILE}"
    if [[ "${OPT_MINIMAL}" -eq 1 ]] && [[ "${OPT_PROFILE_EXPLICIT}" -eq 0 ]]; then
        profile="minimal"
    elif [[ "${OPT_PROFILE_EXPLICIT}" -eq 0 ]] && [[ -f "${DOTFILES_DIR}/local/state.json" ]]; then
        profile="$(jq -r '.profile // "dev"' "${DOTFILES_DIR}/local/state.json" 2>/dev/null || echo "dev")"
    fi

    if [[ "${OPT_DRY_RUN}" -eq 0 ]]; then
        # shellcheck source=/dev/null
        source "${engine}"
        HotLoadEngine::install_profile "${profile}"
    else
        Logger::info "[dry-run] Would install profile: ${profile}"
    fi

    Logger::success "Tools installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Quick post-install verification
# @return 0 if all checks pass, non-zero otherwise
# ═══════════════════════════════════════════════════════════════════════════════
_verify_installation() {
    local issues=0

    # Check generated files
    local gen_dir="${DOTFILES_DIR}/shells/${SHELL_NAME}/generated"
    if [[ -f "${gen_dir}/aliases.gen.sh" ]] && [[ -f "${gen_dir}/init.gen.sh" ]]; then
        Logger::success "Shell configs generated for ${SHELL_NAME}"
    else
        Logger::warn "Shell configs missing — run: dotfiles-gen generate --all"
        ((issues++))
    fi

    # Check starship config symlink
    local starship_cfg="${XDG_CONFIG_HOME:-${HOME}/.config}/starship"
    if [[ -d "${starship_cfg}" ]] || [[ -L "${starship_cfg}" ]]; then
        Logger::success "Starship prompt configured"
    else
        Logger::info "Starship will activate after mise installs it + shell reload"
    fi

    # Determine final profile
    local final_profile="${OPT_PROFILE}"
    if [[ "${OPT_MINIMAL}" -eq 1 ]] && [[ "${OPT_PROFILE_EXPLICIT}" -eq 0 ]]; then
        final_profile="minimal"
    fi

    # Count profile tools
    local tools_count
    tools_count=$(python3 -c "
import sys
sys.path.insert(0, '${DOTFILES_DIR}/generators/src')
try:
    from dotfiles_gen.profiles import resolve_profile_tools
    tools = resolve_profile_tools('${final_profile}', '${DOTFILES_DIR}/definitions/profiles.toml')
    print(len(tools))
except Exception:
    print(0)
" 2>/dev/null || echo "?")

    Logger::info "Profile '${final_profile}': ${tools_count} tools available (installed via mise)"
    Logger::info "Run 'dotfiles status' to see what's installed"

    return "${issues}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Final setup and verification
# ═══════════════════════════════════════════════════════════════════════════════
finalize() {
    Logger::step 7 7 "Finalizing..."

    Platform::summary
    ShellDetector::summary

    echo ""

    if [[ "${OPT_DRY_RUN}" -eq 0 ]]; then
        _verify_installation
    else
        Logger::info "[dry-run] Would verify: shell configs, starship, profile tools"
    fi

    echo ""
    Logger::success "Bootstrap complete!"
    echo ""

    # For one-liner installs, auto-reload the shell so the user lands
    # in a fully configured environment immediately
    if [[ -n "${DOTFILES_ONE_LINER:-}" ]] && [[ "${OPT_DRY_RUN}" -eq 0 ]]; then
        Logger::info "⟳  Reloading shell with new configuration..."
        echo ""
        sleep 1
        # Unset to prevent recursive reloads
        exec env -u DOTFILES_ONE_LINER "${SHELL}" -l
    elif [[ "${OPT_DRY_RUN}" -eq 1 ]]; then
        if [[ -n "${DOTFILES_ONE_LINER:-}" ]]; then
            Logger::info "[dry-run] Would reload shell automatically (one-liner mode)"
        else
            Logger::info "[dry-run] Would prompt: run 'reload' to apply changes"
        fi
    else
        Logger::info "Run 'reload' or 'exec \$SHELL -l' to apply changes"
    fi

    Logger::info "Run 'dotfiles doctor' to verify installation"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Interactive mode — let user choose shell, profile, and options
# ═══════════════════════════════════════════════════════════════════════════════
run_interactive() {
    echo ""
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║     DOTFILES INTERACTIVE SETUP           ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo ""

    # ── Step 1: Choose profile ──
    echo "  Choose a profile:"
    echo ""
    PS3="  Profile [1-7]: "
    select _profile_choice in "minimal (24 tools — essential CLI)" \
                       "dev (109 tools — developer workstation)" \
                       "server (44 tools — headless machine)" \
                       "devops (143 tools — cloud & k8s)" \
                       "data (124 tools — data engineering)" \
                       "ai (120 tools — AI agents & LLM tools)" \
                       "full (193 tools — everything)"; do
        case "${REPLY}" in
            1) OPT_PROFILE="minimal"; break ;;
            2) OPT_PROFILE="dev"; break ;;
            3) OPT_PROFILE="server"; break ;;
            4) OPT_PROFILE="devops"; break ;;
            5) OPT_PROFILE="data"; break ;;
            6) OPT_PROFILE="ai"; break ;;
            7) OPT_PROFILE="full"; break ;;
            *) echo "  Please pick 1-7" ;;
        esac
    done
    OPT_PROFILE_EXPLICIT=1
    echo ""

    # ── Step 2: Choose default shell ──
    echo "  Which shell should be the default?"
    echo ""
    PS3="  Shell [1-4]: "
    select _shell_choice in "zsh (recommended)" "bash" "fish" "nushell"; do
        case "${REPLY}" in
            1) OPT_SHELL="zsh"; break ;;
            2) OPT_SHELL="bash"; break ;;
            3) OPT_SHELL="fish"; break ;;
            4) OPT_SHELL="nushell"; break ;;
            *) echo "  Please pick 1-4" ;;
        esac
    done
    echo ""

    # ── Step 3: Confirm ──
    echo "  ══════════════════════════════════════════"
    echo "  Summary:"
    echo "    Profile : ${OPT_PROFILE}"
    echo "    Shell   : ${OPT_SHELL}"
    echo "    Platform: ${PLATFORM_OS}/${PLATFORM_DISTRO} (${PLATFORM_ARCH})"
    echo "  ══════════════════════════════════════════"
    echo ""

    if [[ "${OPT_DRY_RUN}" -eq 0 ]]; then
        read -r -p "  Proceed with installation? [Y/n] " confirm
        if [[ "${confirm}" =~ ^[Nn] ]]; then
            echo ""
            Logger::info "Installation cancelled."
            exit 0
        fi
    fi

    echo ""
    Logger::info "Starting installation with profile: ${OPT_PROFILE}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Main bootstrap orchestrator
# ═══════════════════════════════════════════════════════════════════════════════
main() {
    parse_args "$@"

    if [[ "${OPT_INTERACTIVE}" -eq 1 ]]; then
        run_interactive
    fi

    echo ""
    Logger::info "Starting dotfiles bootstrap..."
    Logger::info "Platform: ${PLATFORM_OS}/${PLATFORM_DISTRO} (${PLATFORM_ARCH})"
    Logger::info "Shell: ${SHELL_NAME} ${SHELL_VERSION}"
    echo ""

    if [[ "${OPT_DRY_RUN}" -eq 1 ]]; then
        Logger::warn "DRY RUN MODE — no changes will be made"
        echo ""
    fi

    setup_local_vault
    install_hard_deps
    run_generators
    setup_symlinks
    setup_platform
    install_tools
    finalize
}

main "$@"

#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/modules/bootstrap.sh
# @description First-run orchestrator — sets up a fresh machine from scratch
# @class Bootstrap
# @since 1.0.0
# @version 1.0.0
# @see bin/dotfiles
# @see docs/ARCHITECTURE.md
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────────────────────
# @field BOOTSTRAP_DOTFILES_DIR
# @type string
# @description Root path to the dotfiles repository
# ───────────────────────────────────────────────────────────────────────────────
readonly BOOTSTRAP_DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/.dotfiles}"

# ───────────────────────────────────────────────────────────────────────────────
# @field BOOTSTRAP_LOCAL_DIR
# @type string
# @description Path to the machine-local vault directory
# ───────────────────────────────────────────────────────────────────────────────
readonly BOOTSTRAP_LOCAL_DIR="${BOOTSTRAP_DOTFILES_DIR}/local"

# ───────────────────────────────────────────────────────────────────────────────
# @field BOOTSTRAP_STATE_FILE
# @type string
# @description Path to the persistent state JSON file
# ───────────────────────────────────────────────────────────────────────────────
readonly BOOTSTRAP_STATE_FILE="${BOOTSTRAP_LOCAL_DIR}/state.json"

# ───────────────────────────────────────────────────────────────────────────────
# @field BOOTSTRAP_TOTAL_STEPS
# @type integer
# @description Total number of steps in the bootstrap process
# ───────────────────────────────────────────────────────────────────────────────
readonly BOOTSTRAP_TOTAL_STEPS=10

# ───────────────────────────────────────────────────────────────────────────────
# @field BOOTSTRAP_DRY_RUN
# @type boolean (0|1)
# @description When set to 1, print actions without executing them
# ───────────────────────────────────────────────────────────────────────────────
declare -g BOOTSTRAP_DRY_RUN=0

# ───────────────────────────────────────────────────────────────────────────────
# @field BOOTSTRAP_PROFILE
# @type string
# @description Tool installation profile (dev, minimal, server, full)
# ───────────────────────────────────────────────────────────────────────────────
declare -g BOOTSTRAP_PROFILE="dev"

# ═══════════════════════════════════════════════════════════════════════════════
# @description Main bootstrap entry point — runs full first-time setup
# @param --dry-run {flag} [optional] Print actions without executing
# @param --profile {string} [optional] Tool profile to install (default: dev)
# @return 0 on success, 1 on failure
# @example Bootstrap::run --dry-run --profile minimal
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::run() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --dry-run)
                BOOTSTRAP_DRY_RUN=1
                shift
                ;;
            --profile)
                BOOTSTRAP_PROFILE="${2:?Profile name required after --profile}"
                shift 2
                ;;
            *)
                Logger::error "Bootstrap: unknown option '${1}'"
                return 1
                ;;
        esac
    done

    echo ""
    Logger::info "Bootstrap: starting dotfiles setup (profile: ${BOOTSTRAP_PROFILE})"
    if [[ "${BOOTSTRAP_DRY_RUN}" -eq 1 ]]; then
        Logger::warn "Bootstrap: DRY RUN mode — no changes will be made"
    fi
    echo ""

    local start_time
    start_time="$(date +%s)"

    # Step 1: Detect platform
    Logger::step 1 "${BOOTSTRAP_TOTAL_STEPS}" "Detecting platform..."
    Bootstrap::_detect_platform

    # Step 2: Install hard dependencies
    Logger::step 2 "${BOOTSTRAP_TOTAL_STEPS}" "Installing hard dependencies..."
    Bootstrap::install_dependencies

    # Step 3: Create local/ directory structure
    Logger::step 3 "${BOOTSTRAP_TOTAL_STEPS}" "Creating local vault structure..."
    Bootstrap::setup_local_vault

    # Step 4: Set permissions
    Logger::step 4 "${BOOTSTRAP_TOTAL_STEPS}" "Setting vault permissions..."
    Bootstrap::_set_permissions

    # Step 5: Initialize state.json
    Logger::step 5 "${BOOTSTRAP_TOTAL_STEPS}" "Initializing state..."
    Bootstrap::_init_state

    # Step 6: Run generators
    Logger::step 6 "${BOOTSTRAP_TOTAL_STEPS}" "Running shell config generators..."
    Bootstrap::_run_generators

    # Step 7: Install profile tools
    Logger::step 7 "${BOOTSTRAP_TOTAL_STEPS}" "Installing profile tools (${BOOTSTRAP_PROFILE})..."
    Bootstrap::_install_profile_tools

    # Step 8: Setup symlinks
    Logger::step 8 "${BOOTSTRAP_TOTAL_STEPS}" "Setting up config symlinks..."
    Bootstrap::_setup_symlinks

    # Step 9: Set default theme
    Logger::step 9 "${BOOTSTRAP_TOTAL_STEPS}" "Setting default theme..."
    Bootstrap::_set_default_theme

    # Step 10: Run doctor
    Logger::step 10 "${BOOTSTRAP_TOTAL_STEPS}" "Running health check..."
    Bootstrap::_run_doctor

    local end_time duration
    end_time="$(date +%s)"
    duration="$(( end_time - start_time ))"

    echo ""
    Logger::success "Bootstrap: complete in ${duration}s (profile: ${BOOTSTRAP_PROFILE})"
    Logger::info "Bootstrap: restart your shell or run: exec \$SHELL"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check if this is a first-run scenario (no state.json exists)
# @return 0 if first run, 1 if already bootstrapped
# @example Bootstrap::is_first_run && Bootstrap::run
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::is_first_run() {
    [[ ! -f "${BOOTSTRAP_STATE_FILE}" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install hard dependencies (mise, uv) via curl
# @return 0 on success, 1 if critical dependencies cannot be satisfied
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::install_dependencies() {
    # Check pre-requisites that must already exist on the system
    local -a prereqs=("bash" "curl" "git")
    local dep

    for dep in "${prereqs[@]}"; do
        if ! command -v "${dep}" >/dev/null 2>&1; then
            Logger::error "Bootstrap: required system command not found: ${dep}"
            Logger::info "Bootstrap: install '${dep}' via your system package manager first"
            return 1
        fi
    done

    # Check bash version (must be >= 4.0)
    local bash_version
    bash_version="${BASH_VERSINFO[0]}"
    if [[ "${bash_version}" -lt 4 ]]; then
        Logger::error "Bootstrap: bash >= 4.0 required (found: ${BASH_VERSION})"
        Logger::info "Bootstrap: on macOS run: brew install bash"
        return 1
    fi

    # Install jq if missing
    if ! command -v jq >/dev/null 2>&1; then
        Logger::info "Bootstrap: installing jq..."
        Bootstrap::_install_jq
    fi

    # Install mise if missing
    if ! command -v mise >/dev/null 2>&1; then
        Logger::info "Bootstrap: installing mise..."
        Bootstrap::_install_mise
    fi

    # Install uv if missing
    if ! command -v uv >/dev/null 2>&1; then
        Logger::info "Bootstrap: installing uv..."
        Bootstrap::_install_uv
    fi

    # Install python3 if missing (via mise)
    if ! command -v python3 >/dev/null 2>&1; then
        Logger::info "Bootstrap: installing python3 via mise..."
        Bootstrap::_install_python3
    fi

    Logger::success "Bootstrap: all hard dependencies satisfied"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Create the local/ vault directory structure
# @return 0 on success
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::setup_local_vault() {
    local -a private_dirs=(
        "${BOOTSTRAP_LOCAL_DIR}/secrets"
        "${BOOTSTRAP_LOCAL_DIR}/ssh"
        "${BOOTSTRAP_LOCAL_DIR}/ssh/keys"
    )

    local -a standard_dirs=(
        "${BOOTSTRAP_LOCAL_DIR}"
        "${BOOTSTRAP_LOCAL_DIR}/shell"
        "${BOOTSTRAP_LOCAL_DIR}/config"
        "${BOOTSTRAP_LOCAL_DIR}/overrides"
    )

    if [[ "${BOOTSTRAP_DRY_RUN}" -eq 1 ]]; then
        Logger::info "Bootstrap: [dry-run] would create local/ vault structure"
        local dir
        for dir in "${standard_dirs[@]}" "${private_dirs[@]}"; do
            Logger::debug "Bootstrap: [dry-run] mkdir ${dir}"
        done
        return 0
    fi

    local dir
    for dir in "${standard_dirs[@]}"; do
        [[ -d "${dir}" ]] || mkdir -p "${dir}"
    done

    for dir in "${private_dirs[@]}"; do
        [[ -d "${dir}" ]] || mkdir -p "${dir}"
        chmod 700 "${dir}"
    done

    # Create .gitkeep to ensure local/ exists in repo (contents are gitignored)
    [[ -f "${BOOTSTRAP_LOCAL_DIR}/.gitkeep" ]] || touch "${BOOTSTRAP_LOCAL_DIR}/.gitkeep"

    Logger::success "Bootstrap: local vault structure created"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Detect platform information
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::_detect_platform() {
    source "${BOOTSTRAP_DOTFILES_DIR}/lib/core/platform.sh"
    Platform::detect
    Logger::success "Bootstrap: platform detected (${PLATFORM_OS}/${PLATFORM_ARCH})"

    if [[ "${PLATFORM_IS_WSL}" -eq 1 ]]; then
        Logger::info "Bootstrap: running inside WSL"
    fi
    if [[ "${PLATFORM_IS_CONTAINER}" -eq 1 ]]; then
        Logger::info "Bootstrap: running inside a container"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Set permissions on vault directories
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::_set_permissions() {
    if [[ "${BOOTSTRAP_DRY_RUN}" -eq 1 ]]; then
        Logger::info "Bootstrap: [dry-run] would set 700 on secrets/ssh directories"
        return 0
    fi

    local -a restricted_dirs=(
        "${BOOTSTRAP_LOCAL_DIR}/secrets"
        "${BOOTSTRAP_LOCAL_DIR}/ssh"
        "${BOOTSTRAP_LOCAL_DIR}/ssh/keys"
    )

    local dir
    for dir in "${restricted_dirs[@]}"; do
        if [[ -d "${dir}" ]]; then
            chmod 700 "${dir}"
        fi
    done

    Logger::success "Bootstrap: vault permissions set (700)"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Initialize state.json if it does not exist
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::_init_state() {
    if [[ "${BOOTSTRAP_DRY_RUN}" -eq 1 ]]; then
        Logger::info "Bootstrap: [dry-run] would initialize state.json"
        return 0
    fi

    source "${BOOTSTRAP_DOTFILES_DIR}/lib/hotload/state.sh"
    StateManager::init

    # Record bootstrap metadata
    local timestamp
    timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    StateManager::set ".bootstrap" "{\"completed_at\": \"${timestamp}\", \"profile\": \"${BOOTSTRAP_PROFILE}\"}"

    Logger::success "Bootstrap: state.json initialized"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Run the SSOT generators to produce shell configs
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::_run_generators() {
    if [[ "${BOOTSTRAP_DRY_RUN}" -eq 1 ]]; then
        Logger::info "Bootstrap: [dry-run] would run dotfiles-gen generate --all"
        return 0
    fi

    local gen_bin="${BOOTSTRAP_DOTFILES_DIR}/bin/dotfiles-gen"
    if [[ -x "${gen_bin}" ]]; then
        "${gen_bin}" generate --all
    else
        # Fallback: run directly with uv
        if command -v uv >/dev/null 2>&1; then
            (cd "${BOOTSTRAP_DOTFILES_DIR}/generators" && uv run python -m src.cli generate --all)
        else
            Logger::warn "Bootstrap: cannot run generators (uv not available)"
            return 0
        fi
    fi

    Logger::success "Bootstrap: shell configs generated"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install tools from the selected profile
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::_install_profile_tools() {
    if [[ "${BOOTSTRAP_DRY_RUN}" -eq 1 ]]; then
        Logger::info "Bootstrap: [dry-run] would install tools for profile '${BOOTSTRAP_PROFILE}'"
        return 0
    fi

    local profile_file="${BOOTSTRAP_DOTFILES_DIR}/tools/profiles/${BOOTSTRAP_PROFILE}.toml"

    if [[ ! -f "${profile_file}" ]]; then
        Logger::warn "Bootstrap: profile '${BOOTSTRAP_PROFILE}' not found at ${profile_file}"
        Logger::info "Bootstrap: skipping tool installation (install manually with 'dotfiles install <tool>')"
        return 0
    fi

    # Use the hotload engine to install profile tools
    source "${BOOTSTRAP_DOTFILES_DIR}/lib/hotload/engine.sh"

    local tool
    while IFS= read -r tool; do
        [[ -n "${tool}" ]] || continue
        Logger::info "Bootstrap: installing ${tool}..."
        HotLoadEngine::install "${tool}" || Logger::warn "Bootstrap: failed to install ${tool} (non-fatal)"
    done < <(grep -oP '^\s*"\K[^"]+' "${profile_file}" 2>/dev/null || \
             grep -o '"[^"]*"' "${profile_file}" 2>/dev/null | tr -d '"')

    Logger::success "Bootstrap: profile tools installed"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Setup XDG config symlinks
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::_setup_symlinks() {
    if [[ "${BOOTSTRAP_DRY_RUN}" -eq 1 ]]; then
        Logger::info "Bootstrap: [dry-run] would create config symlinks"
        return 0
    fi

    source "${BOOTSTRAP_DOTFILES_DIR}/lib/modules/symlink.sh"
    SymlinkManager::setup_configs
    SymlinkManager::setup_shell_links

    Logger::success "Bootstrap: symlinks configured"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Set the default starship theme (minimal)
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::_set_default_theme() {
    if [[ "${BOOTSTRAP_DRY_RUN}" -eq 1 ]]; then
        Logger::info "Bootstrap: [dry-run] would set default theme to 'minimal'"
        return 0
    fi

    source "${BOOTSTRAP_DOTFILES_DIR}/lib/modules/theme.sh"
    ThemeManager::switch "minimal"

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Run the dotfiles doctor health check
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::_run_doctor() {
    if [[ "${BOOTSTRAP_DRY_RUN}" -eq 1 ]]; then
        Logger::info "Bootstrap: [dry-run] would run dotfiles doctor"
        return 0
    fi

    source "${BOOTSTRAP_DOTFILES_DIR}/lib/modules/doctor.sh"
    Doctor::run || Logger::warn "Bootstrap: doctor found issues (see above)"

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install jq based on detected platform
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::_install_jq() {
    if [[ "${BOOTSTRAP_DRY_RUN}" -eq 1 ]]; then
        Logger::info "Bootstrap: [dry-run] would install jq"
        return 0
    fi

    case "${PLATFORM_OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}" in
        darwin)
            if command -v brew >/dev/null 2>&1; then
                brew install jq
            else
                Logger::error "Bootstrap: cannot install jq — install Homebrew first or install jq manually"
                return 1
            fi
            ;;
        linux)
            local distro="${PLATFORM_DISTRO:-unknown}"
            case "${distro}" in
                debian)  sudo apt-get update -qq && sudo apt-get install -y -qq jq ;;
                arch)    sudo pacman -S --noconfirm jq ;;
                fedora)  sudo dnf install -y jq ;;
                alpine)  sudo apk add jq ;;
                *)
                    # Attempt static binary download
                    local arch
                    arch="$(uname -m)"
                    local jq_url="https://github.com/jqlang/jq/releases/latest/download/jq-linux-${arch}"
                    curl -fsSL "${jq_url}" -o /tmp/jq && chmod +x /tmp/jq && sudo mv /tmp/jq /usr/local/bin/jq
                    ;;
            esac
            ;;
        *)
            Logger::error "Bootstrap: unsupported platform for jq auto-install"
            return 1
            ;;
    esac

    if command -v jq >/dev/null 2>&1; then
        Logger::success "Bootstrap: jq installed"
    else
        Logger::error "Bootstrap: jq installation failed"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install mise (polyglot runtime manager) via official installer
# @see https://mise.jdx.dev
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::_install_mise() {
    if [[ "${BOOTSTRAP_DRY_RUN}" -eq 1 ]]; then
        Logger::info "Bootstrap: [dry-run] would install mise"
        return 0
    fi

    curl -fsSL https://mise.run | sh

    # Add mise to PATH for current session
    if [[ -f "${HOME}/.local/bin/mise" ]]; then
        export PATH="${HOME}/.local/bin:${PATH}"
    fi

    if command -v mise >/dev/null 2>&1; then
        Logger::success "Bootstrap: mise installed ($(mise --version 2>/dev/null || echo 'unknown'))"
    else
        Logger::error "Bootstrap: mise installation failed"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install uv (Python package manager) via official installer
# @see https://docs.astral.sh/uv
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::_install_uv() {
    if [[ "${BOOTSTRAP_DRY_RUN}" -eq 1 ]]; then
        Logger::info "Bootstrap: [dry-run] would install uv"
        return 0
    fi

    curl -fsSL https://astral.sh/uv/install.sh | sh

    # Add uv to PATH for current session
    if [[ -f "${HOME}/.local/bin/uv" ]]; then
        export PATH="${HOME}/.local/bin:${PATH}"
    fi
    if [[ -f "${HOME}/.cargo/bin/uv" ]]; then
        export PATH="${HOME}/.cargo/bin:${PATH}"
    fi

    if command -v uv >/dev/null 2>&1; then
        Logger::success "Bootstrap: uv installed ($(uv --version 2>/dev/null || echo 'unknown'))"
    else
        Logger::error "Bootstrap: uv installation failed"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install Python 3 via mise
# ═══════════════════════════════════════════════════════════════════════════════
Bootstrap::_install_python3() {
    if [[ "${BOOTSTRAP_DRY_RUN}" -eq 1 ]]; then
        Logger::info "Bootstrap: [dry-run] would install python3 via mise"
        return 0
    fi

    if ! command -v mise >/dev/null 2>&1; then
        Logger::error "Bootstrap: cannot install python3 — mise not available"
        return 1
    fi

    mise install python@latest
    mise use --global python@latest

    if command -v python3 >/dev/null 2>&1; then
        Logger::success "Bootstrap: python3 installed ($(python3 --version 2>/dev/null))"
    else
        Logger::warn "Bootstrap: python3 installed via mise but may need shell restart"
    fi
}

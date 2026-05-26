#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/modules/onboarding.sh
# @description Interactive first-time setup wizard for new machines
# @class Onboarding
# @since 1.0.0
# @version 1.0.0
# @see lib/modules/bootstrap.sh
# @see definitions/profiles.toml
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────────────────────
# @field ONBOARDING_DOTFILES_DIR
# @type string
# @description Root path to the dotfiles repository
# ───────────────────────────────────────────────────────────────────────────────
readonly ONBOARDING_DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/.dotfiles}"

# ───────────────────────────────────────────────────────────────────────────────
# @field ONBOARDING_HAS_GUM
# @type boolean (0|1)
# @description Whether gum is available for rich terminal UI
# ───────────────────────────────────────────────────────────────────────────────
declare -g ONBOARDING_HAS_GUM=0

# ───────────────────────────────────────────────────────────────────────────────
# @field ONBOARDING_PROFILE
# @type string
# @description Selected machine profile
# ───────────────────────────────────────────────────────────────────────────────
declare -g ONBOARDING_PROFILE=""

# ───────────────────────────────────────────────────────────────────────────────
# @field ONBOARDING_SHELL
# @type string
# @description Selected default shell
# ───────────────────────────────────────────────────────────────────────────────
declare -g ONBOARDING_SHELL=""

# ───────────────────────────────────────────────────────────────────────────────
# @field ONBOARDING_THEME
# @type string
# @description Selected starship theme
# ───────────────────────────────────────────────────────────────────────────────
declare -g ONBOARDING_THEME=""

# ───────────────────────────────────────────────────────────────────────────────
# @field ONBOARDING_GIT_NAME
# @type string
# @description Git user name
# ───────────────────────────────────────────────────────────────────────────────
declare -g ONBOARDING_GIT_NAME=""

# ───────────────────────────────────────────────────────────────────────────────
# @field ONBOARDING_GIT_EMAIL
# @type string
# @description Git user email
# ───────────────────────────────────────────────────────────────────────────────
declare -g ONBOARDING_GIT_EMAIL=""

# ───────────────────────────────────────────────────────────────────────────────
# @field ONBOARDING_SSH_KEYGEN
# @type boolean (0|1)
# @description Whether to generate an SSH key
# ───────────────────────────────────────────────────────────────────────────────
declare -g ONBOARDING_SSH_KEYGEN=0

# ═══════════════════════════════════════════════════════════════════════════════
# @description Main entry point — runs the full interactive onboarding wizard
# @return 0 on success, 1 on user cancellation or failure
# @example Onboarding::run
# ═══════════════════════════════════════════════════════════════════════════════
Onboarding::run() {
    Onboarding::_has_gum

    # Step 1: Welcome
    Onboarding::_step_welcome

    # Step 2: Profile selection
    Onboarding::_step_profile || return 1

    # Step 3: Shell selection
    Onboarding::_step_shell || return 1

    # Step 4: Theme selection
    Onboarding::_step_theme || return 1

    # Step 5: Git configuration
    Onboarding::_step_git || return 1

    # Step 6: SSH key generation
    Onboarding::_step_ssh || return 1

    # Step 7: Summary and confirmation
    Onboarding::_step_summary || return 1

    # Step 8: Execute
    Onboarding::_step_execute

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check if gum is installed and set ONBOARDING_HAS_GUM flag
# @return 0 always (sets global flag)
# ═══════════════════════════════════════════════════════════════════════════════
Onboarding::_has_gum() {
    if command -v gum >/dev/null 2>&1; then
        ONBOARDING_HAS_GUM=1
    else
        ONBOARDING_HAS_GUM=0
        Logger::info "Onboarding: gum not found, using basic prompts"
        Logger::info "Onboarding: install gum for a richer experience (charm.sh/gum)"
        echo ""
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Display welcome banner with ASCII art
# ═══════════════════════════════════════════════════════════════════════════════
Onboarding::_step_welcome() {
    echo ""
    if [[ "${ONBOARDING_HAS_GUM}" -eq 1 ]]; then
        gum style \
            --border double \
            --border-foreground 39 \
            --padding "1 3" \
            --margin "0 2" \
            --align center \
            "╺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸" \
            "" \
            "    ┌┬┐┌─┐┌┬┐┌─┐┬┬  ┌─┐┌─┐" \
            "     │││ │ │ ├┤ ││  ├┤ └─┐" \
            "    ─┴┘└─┘ ┴ └  ┴┴─┘└─┘└─┘" \
            "" \
            "    First-Time Setup Wizard" \
            "" \
            "╺━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╸"
    else
        cat <<'EOF'
    ╔═══════════════════════════════════════════════╗
    ║                                               ║
    ║      ┌┬┐┌─┐┌┬┐┌─┐┬┬  ┌─┐┌─┐                ║
    ║       │││ │ │ ├┤ ││  ├┤ └─┐                ║
    ║      ─┴┘└─┘ ┴ └  ┴┴─┘└─┘└─┘                ║
    ║                                               ║
    ║        First-Time Setup Wizard                ║
    ║                                               ║
    ╚═══════════════════════════════════════════════╝
EOF
    fi

    echo ""
    Logger::info "Welcome! This wizard will configure your dotfiles environment."
    Logger::info "It will set up your profile, shell, theme, git, and SSH keys."
    echo ""

    if [[ "${ONBOARDING_HAS_GUM}" -eq 1 ]]; then
        gum style --faint "Press Enter to continue, or Ctrl+C to abort."
        read -r
    else
        echo "  Press Enter to continue, or Ctrl+C to abort."
        read -r
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Ask user to select a machine profile
# @return 0 on selection, 1 on cancellation
# ═══════════════════════════════════════════════════════════════════════════════
Onboarding::_step_profile() {
    echo ""
    Logger::info "Step 1/6: Machine Profile"
    Logger::info "Choose a profile that matches how you will use this machine."
    echo ""

    if [[ "${ONBOARDING_HAS_GUM}" -eq 1 ]]; then
        local selection
        selection=$(gum choose \
            --header "Select a profile:" \
            --cursor.foreground 39 \
            --item.foreground 252 \
            "minimal  - Essential CLI tools for any machine" \
            "dev      - Developer workstation" \
            "devops   - DevOps and cloud engineering" \
            "data     - Data engineering and analysis" \
            "server   - Headless server / remote machine" \
            "full     - Everything (all tools installed)") || return 1

        ONBOARDING_PROFILE="${selection%% *}"
        ONBOARDING_PROFILE="${ONBOARDING_PROFILE// /}"
    else
        echo "  Available profiles:"
        echo ""
        echo "    1) minimal  - Essential CLI tools for any machine"
        echo "    2) dev      - Developer workstation"
        echo "    3) devops   - DevOps and cloud engineering"
        echo "    4) data     - Data engineering and analysis"
        echo "    5) server   - Headless server / remote machine"
        echo "    6) full     - Everything (all tools installed)"
        echo ""

        local choice
        while true; do
            read -r -p "  Select profile [1-6] (default: 2): " choice
            choice="${choice:-2}"
            case "${choice}" in
                1) ONBOARDING_PROFILE="minimal"; break ;;
                2) ONBOARDING_PROFILE="dev"; break ;;
                3) ONBOARDING_PROFILE="devops"; break ;;
                4) ONBOARDING_PROFILE="data"; break ;;
                5) ONBOARDING_PROFILE="server"; break ;;
                6) ONBOARDING_PROFILE="full"; break ;;
                *) echo "  Invalid choice. Please enter 1-6." ;;
            esac
        done
    fi

    Logger::success "Profile: ${ONBOARDING_PROFILE}"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Ask user to select their preferred default shell
# @return 0 on selection, 1 on cancellation
# ═══════════════════════════════════════════════════════════════════════════════
Onboarding::_step_shell() {
    echo ""
    Logger::info "Step 2/6: Default Shell"
    Logger::info "Choose your preferred interactive shell."
    echo ""

    # Detect available shells
    local -a available_shells=()
    local -a shell_descriptions=()

    if command -v zsh >/dev/null 2>&1; then
        available_shells+=("zsh")
        shell_descriptions+=("zsh  - Recommended (fast, feature-rich, default on macOS)")
    fi
    if command -v bash >/dev/null 2>&1; then
        available_shells+=("bash")
        shell_descriptions+=("bash - Universal (available everywhere)")
    fi
    if command -v fish >/dev/null 2>&1; then
        available_shells+=("fish")
        shell_descriptions+=("fish - Modern (auto-suggestions, syntax highlighting)")
    fi

    if [[ ${#available_shells[@]} -eq 0 ]]; then
        Logger::warn "No supported shells detected. Defaulting to bash."
        ONBOARDING_SHELL="bash"
        return 0
    fi

    if [[ "${ONBOARDING_HAS_GUM}" -eq 1 ]]; then
        local selection
        selection=$(gum choose \
            --header "Select your default shell:" \
            --cursor.foreground 39 \
            --item.foreground 252 \
            "${shell_descriptions[@]}") || return 1

        ONBOARDING_SHELL="${selection%% *}"
        ONBOARDING_SHELL="${ONBOARDING_SHELL// /}"
    else
        echo "  Available shells:"
        echo ""
        local i
        for i in "${!shell_descriptions[@]}"; do
            echo "    $((i + 1))) ${shell_descriptions[${i}]}"
        done
        echo ""

        local choice
        while true; do
            read -r -p "  Select shell [1-${#available_shells[@]}] (default: 1): " choice
            choice="${choice:-1}"
            if [[ "${choice}" -ge 1 && "${choice}" -le ${#available_shells[@]} ]] 2>/dev/null; then
                ONBOARDING_SHELL="${available_shells[$((choice - 1))]}"
                break
            else
                echo "  Invalid choice. Please enter 1-${#available_shells[@]}."
            fi
        done
    fi

    Logger::success "Shell: ${ONBOARDING_SHELL}"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Ask user to select a starship prompt theme
# @return 0 on selection, 1 on cancellation
# ═══════════════════════════════════════════════════════════════════════════════
Onboarding::_step_theme() {
    echo ""
    Logger::info "Step 3/6: Starship Theme"
    Logger::info "Choose a prompt theme for your terminal."
    echo ""

    if [[ "${ONBOARDING_HAS_GUM}" -eq 1 ]]; then
        local selection
        selection=$(gum choose \
            --header "Select a starship theme:" \
            --cursor.foreground 39 \
            --item.foreground 252 \
            "minimal    - Clean, fast, no Nerd Fonts required" \
            "full       - All segments, Nerd Font icons, Catppuccin colors" \
            "powerline  - Colored segments with arrow separators") || return 1

        ONBOARDING_THEME="${selection%% *}"
        ONBOARDING_THEME="${ONBOARDING_THEME// /}"
    else
        echo "  Available themes:"
        echo ""
        echo "    1) minimal    - Clean, fast, no Nerd Fonts required"
        echo "    2) full       - All segments, Nerd Font icons, Catppuccin colors"
        echo "    3) powerline  - Colored segments with arrow separators"
        echo ""

        local choice
        while true; do
            read -r -p "  Select theme [1-3] (default: 1): " choice
            choice="${choice:-1}"
            case "${choice}" in
                1) ONBOARDING_THEME="minimal"; break ;;
                2) ONBOARDING_THEME="full"; break ;;
                3) ONBOARDING_THEME="powerline"; break ;;
                *) echo "  Invalid choice. Please enter 1-3." ;;
            esac
        done
    fi

    Logger::success "Theme: ${ONBOARDING_THEME}"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Ask user for git name and email configuration
# @return 0 on input provided, 1 on cancellation
# ═══════════════════════════════════════════════════════════════════════════════
Onboarding::_step_git() {
    echo ""
    Logger::info "Step 4/6: Git Configuration"
    Logger::info "Configure your git identity for commits."
    echo ""

    # Pre-fill from existing git config if available
    local existing_name=""
    local existing_email=""
    existing_name="$(git config --global user.name 2>/dev/null || true)"
    existing_email="$(git config --global user.email 2>/dev/null || true)"

    if [[ "${ONBOARDING_HAS_GUM}" -eq 1 ]]; then
        ONBOARDING_GIT_NAME=$(gum input \
            --header "Your full name:" \
            --placeholder "John Doe" \
            --value "${existing_name}" \
            --width 50) || return 1

        ONBOARDING_GIT_EMAIL=$(gum input \
            --header "Your email:" \
            --placeholder "john@example.com" \
            --value "${existing_email}" \
            --width 50) || return 1
    else
        local input_name
        if [[ -n "${existing_name}" ]]; then
            read -r -p "  Full name [${existing_name}]: " input_name
            ONBOARDING_GIT_NAME="${input_name:-${existing_name}}"
        else
            while [[ -z "${ONBOARDING_GIT_NAME}" ]]; do
                read -r -p "  Full name: " ONBOARDING_GIT_NAME
                [[ -z "${ONBOARDING_GIT_NAME}" ]] && echo "  Name cannot be empty."
            done
        fi

        local input_email
        if [[ -n "${existing_email}" ]]; then
            read -r -p "  Email [${existing_email}]: " input_email
            ONBOARDING_GIT_EMAIL="${input_email:-${existing_email}}"
        else
            while [[ -z "${ONBOARDING_GIT_EMAIL}" ]]; do
                read -r -p "  Email: " ONBOARDING_GIT_EMAIL
                [[ -z "${ONBOARDING_GIT_EMAIL}" ]] && echo "  Email cannot be empty."
            done
        fi
    fi

    Logger::success "Git: ${ONBOARDING_GIT_NAME} <${ONBOARDING_GIT_EMAIL}>"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Ask user if they want to generate an ed25519 SSH key
# @return 0 always
# ═══════════════════════════════════════════════════════════════════════════════
Onboarding::_step_ssh() {
    echo ""
    Logger::info "Step 5/6: SSH Key"

    # Check if an SSH key already exists
    if [[ -f "${HOME}/.ssh/id_ed25519" ]]; then
        Logger::info "An ed25519 SSH key already exists at ~/.ssh/id_ed25519"
        ONBOARDING_SSH_KEYGEN=0
        return 0
    fi

    Logger::info "No ed25519 SSH key found. Would you like to generate one?"
    echo ""

    if [[ "${ONBOARDING_HAS_GUM}" -eq 1 ]]; then
        if gum confirm "Generate an ed25519 SSH key?"; then
            ONBOARDING_SSH_KEYGEN=1
        else
            ONBOARDING_SSH_KEYGEN=0
        fi
    else
        local choice
        read -r -p "  Generate SSH key? [Y/n]: " choice
        case "${choice}" in
            [nN]|[nN][oO]) ONBOARDING_SSH_KEYGEN=0 ;;
            *)             ONBOARDING_SSH_KEYGEN=1 ;;
        esac
    fi

    if [[ "${ONBOARDING_SSH_KEYGEN}" -eq 1 ]]; then
        Logger::success "SSH: will generate ed25519 key"
    else
        Logger::info "SSH: skipping key generation"
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Display summary of selections and ask for confirmation
# @return 0 on confirmation, 1 on cancellation
# ═══════════════════════════════════════════════════════════════════════════════
Onboarding::_step_summary() {
    echo ""
    Logger::info "Step 6/6: Confirm Setup"
    echo ""

    local ssh_status="no"
    [[ "${ONBOARDING_SSH_KEYGEN}" -eq 1 ]] && ssh_status="yes (ed25519)"

    if [[ "${ONBOARDING_HAS_GUM}" -eq 1 ]]; then
        gum style \
            --border rounded \
            --border-foreground 39 \
            --padding "1 2" \
            --margin "0 2" \
            "  Configuration Summary" \
            "  ─────────────────────────────────────" \
            "" \
            "  Profile:    ${ONBOARDING_PROFILE}" \
            "  Shell:      ${ONBOARDING_SHELL}" \
            "  Theme:      ${ONBOARDING_THEME}" \
            "  Git name:   ${ONBOARDING_GIT_NAME}" \
            "  Git email:  ${ONBOARDING_GIT_EMAIL}" \
            "  SSH key:    ${ssh_status}" \
            "" \
            "  ─────────────────────────────────────"
        echo ""

        if ! gum confirm "Proceed with this configuration?"; then
            Logger::warn "Onboarding: cancelled by user"
            return 1
        fi
    else
        echo "  ┌─────────────────────────────────────────┐"
        echo "  │       Configuration Summary              │"
        echo "  ├─────────────────────────────────────────┤"
        echo "  │  Profile:    ${ONBOARDING_PROFILE}"
        echo "  │  Shell:      ${ONBOARDING_SHELL}"
        echo "  │  Theme:      ${ONBOARDING_THEME}"
        echo "  │  Git name:   ${ONBOARDING_GIT_NAME}"
        echo "  │  Git email:  ${ONBOARDING_GIT_EMAIL}"
        echo "  │  SSH key:    ${ssh_status}"
        echo "  └─────────────────────────────────────────┘"
        echo ""

        local confirm
        read -r -p "  Proceed with this configuration? [Y/n]: " confirm
        case "${confirm}" in
            [nN]|[nN][oO])
                Logger::warn "Onboarding: cancelled by user"
                return 1
                ;;
        esac
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Execute all selected configuration steps
# @return 0 on success, 1 on critical failure
# ═══════════════════════════════════════════════════════════════════════════════
Onboarding::_step_execute() {
    echo ""
    Logger::info "Applying configuration..."
    echo ""

    # 1. Run bootstrap with selected profile
    Logger::step 1 5 "Running bootstrap (profile: ${ONBOARDING_PROFILE})..."
    source "${ONBOARDING_DOTFILES_DIR}/lib/modules/bootstrap.sh"
    Bootstrap::run --profile "${ONBOARDING_PROFILE}"

    # 2. Set starship theme
    Logger::step 2 5 "Setting starship theme to '${ONBOARDING_THEME}'..."
    source "${ONBOARDING_DOTFILES_DIR}/lib/modules/theme.sh"
    ThemeManager::switch "${ONBOARDING_THEME}"

    # 3. Configure git identity
    Logger::step 3 5 "Configuring git identity..."
    Onboarding::_configure_git

    # 4. Generate SSH key if requested
    if [[ "${ONBOARDING_SSH_KEYGEN}" -eq 1 ]]; then
        Logger::step 4 5 "Generating SSH key..."
        Onboarding::_generate_ssh_key
    else
        Logger::step 4 5 "Skipping SSH key generation"
    fi

    # 5. Set default shell
    Logger::step 5 5 "Setting default shell to '${ONBOARDING_SHELL}'..."
    Onboarding::_set_default_shell

    # Final success message
    echo ""
    Onboarding::_show_completion
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Configure git global user.name and user.email
# ═══════════════════════════════════════════════════════════════════════════════
Onboarding::_configure_git() {
    if [[ -n "${ONBOARDING_GIT_NAME}" ]]; then
        git config --global user.name "${ONBOARDING_GIT_NAME}"
    fi
    if [[ -n "${ONBOARDING_GIT_EMAIL}" ]]; then
        git config --global user.email "${ONBOARDING_GIT_EMAIL}"
    fi

    # Set sensible git defaults
    git config --global init.defaultBranch "main"
    git config --global pull.rebase true
    git config --global push.autoSetupRemote true

    Logger::success "Git identity configured"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Generate an ed25519 SSH key pair
# ═══════════════════════════════════════════════════════════════════════════════
Onboarding::_generate_ssh_key() {
    local ssh_dir="${HOME}/.ssh"
    local key_path="${ssh_dir}/id_ed25519"

    # Ensure .ssh directory exists with correct permissions
    if [[ ! -d "${ssh_dir}" ]]; then
        mkdir -p "${ssh_dir}"
        chmod 700 "${ssh_dir}"
    fi

    # Generate the key
    local comment="${ONBOARDING_GIT_EMAIL}"
    ssh-keygen -t ed25519 -C "${comment}" -f "${key_path}" -N ""

    # Set correct permissions
    chmod 600 "${key_path}"
    chmod 644 "${key_path}.pub"

    # Start ssh-agent and add key
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    ssh-add "${key_path}" 2>/dev/null || true

    Logger::success "SSH key generated: ${key_path}"
    echo ""
    Logger::info "Public key (add this to GitHub/GitLab):"
    echo ""
    echo "  $(cat "${key_path}.pub")"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Set the user's default shell (if different from current)
# ═══════════════════════════════════════════════════════════════════════════════
Onboarding::_set_default_shell() {
    local target_shell
    target_shell="$(command -v "${ONBOARDING_SHELL}" 2>/dev/null || true)"

    if [[ -z "${target_shell}" ]]; then
        Logger::warn "Shell '${ONBOARDING_SHELL}' not found in PATH, skipping"
        return 0
    fi

    local current_shell
    current_shell="$(basename "${SHELL}")"

    if [[ "${current_shell}" == "${ONBOARDING_SHELL}" ]]; then
        Logger::info "Already using ${ONBOARDING_SHELL} as default shell"
        return 0
    fi

    # Verify the shell is in /etc/shells
    if ! grep -q "^${target_shell}$" /etc/shells 2>/dev/null; then
        Logger::warn "'${target_shell}' is not in /etc/shells"
        Logger::info "Add it manually: echo '${target_shell}' | sudo tee -a /etc/shells"
        Logger::info "Then run: chsh -s '${target_shell}'"
        return 0
    fi

    Logger::info "Changing default shell to ${ONBOARDING_SHELL}..."
    Logger::info "You may be prompted for your password."
    chsh -s "${target_shell}" || {
        Logger::warn "Could not change shell automatically"
        Logger::info "Run manually: chsh -s '${target_shell}'"
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Display the final completion message
# ═══════════════════════════════════════════════════════════════════════════════
Onboarding::_show_completion() {
    if [[ "${ONBOARDING_HAS_GUM}" -eq 1 ]]; then
        gum style \
            --border double \
            --border-foreground 82 \
            --padding "1 3" \
            --margin "0 2" \
            --align center \
            "Setup Complete!" \
            "" \
            "Your dotfiles environment is ready." \
            "" \
            "Next steps:" \
            "  - Restart your shell:  exec \$SHELL" \
            "  - Check health:        dotfiles doctor" \
            "  - Install a tool:      dotfiles install <tool>" \
            "  - Change theme:        dotfiles-theme <name>"
    else
        echo ""
        echo "  ╔═══════════════════════════════════════════════╗"
        echo "  ║          Setup Complete!                      ║"
        echo "  ╠═══════════════════════════════════════════════╣"
        echo "  ║                                               ║"
        echo "  ║  Your dotfiles environment is ready.          ║"
        echo "  ║                                               ║"
        echo "  ║  Next steps:                                  ║"
        echo "  ║    - Restart your shell:  exec \$SHELL         ║"
        echo "  ║    - Check health:        dotfiles doctor     ║"
        echo "  ║    - Install a tool:      dotfiles install    ║"
        echo "  ║    - Change theme:        dotfiles-theme      ║"
        echo "  ║                                               ║"
        echo "  ╚═══════════════════════════════════════════════╝"
    fi

    echo ""
    Logger::success "Onboarding: complete! Restart your shell to apply all changes."
}

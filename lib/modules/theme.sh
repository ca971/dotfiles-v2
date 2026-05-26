#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/modules/theme.sh
# @description Starship theme management (switch, list, preview themes)
# @class ThemeManager
# @since 1.0.0
# @version 1.0.0
# @see config/starship/themes/
# @see bin/dotfiles-theme
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────────────────────
# @field THEME_PRESETS_DIR
# @type string
# @description Path to starship theme preset files
# ───────────────────────────────────────────────────────────────────────────────
readonly THEME_PRESETS_DIR="${DOTFILES_DIR:-${HOME}/.dotfiles}/config/starship/themes"

# ───────────────────────────────────────────────────────────────────────────────
# @field THEME_STARSHIP_TARGET
# @type string
# @description Path to the active starship.toml configuration file
# ───────────────────────────────────────────────────────────────────────────────
readonly THEME_STARSHIP_TARGET="${XDG_CONFIG_HOME:-${HOME}/.config}/starship.toml"

# ───────────────────────────────────────────────────────────────────────────────
# @field THEME_VALID_NAMES
# @type array
# @description List of supported theme names
# ───────────────────────────────────────────────────────────────────────────────
readonly THEME_VALID_NAMES=("minimal" "full" "powerline")

# ═══════════════════════════════════════════════════════════════════════════════
# @description Switch the active starship theme
# @param $1 {string} Theme name (minimal, full, powerline)
# @return 0 on success, 1 on invalid theme or missing file
# @example ThemeManager::switch "powerline"
# ═══════════════════════════════════════════════════════════════════════════════
ThemeManager::switch() {
    local theme="${1:?Theme name required}"

    # Validate theme name
    if ! ThemeManager::_is_valid "${theme}"; then
        Logger::error "ThemeManager: invalid theme '${theme}'"
        Logger::info "ThemeManager: valid themes: ${THEME_VALID_NAMES[*]}"
        return 1
    fi

    # Verify theme preset file exists
    local theme_file="${THEME_PRESETS_DIR}/${theme}.toml"
    if [[ ! -f "${theme_file}" ]]; then
        Logger::error "ThemeManager: theme file not found: ${theme_file}"
        return 1
    fi

    # Check if already active
    local current
    current="$(ThemeManager::current)"
    if [[ "${current}" == "${theme}" ]]; then
        Logger::info "ThemeManager: '${theme}' is already the active theme"
        return 0
    fi

    # Ensure target directory exists
    local target_dir
    target_dir="$(dirname "${THEME_STARSHIP_TARGET}")"
    [[ -d "${target_dir}" ]] || mkdir -p "${target_dir}"

    # Remove existing config and create symlink to theme preset
    rm -f "${THEME_STARSHIP_TARGET}"
    ln -s "${theme_file}" "${THEME_STARSHIP_TARGET}"

    # Update state
    StateManager::set_theme "${theme}"

    Logger::success "ThemeManager: switched to '${theme}' theme"
    Logger::info "ThemeManager: restart your shell or run: exec \$SHELL"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Get the currently active theme name from state
# @return Prints the current theme name (defaults to "minimal")
# ═══════════════════════════════════════════════════════════════════════════════
ThemeManager::current() {
    StateManager::get_theme
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description List all available themes with active indicator
# @return Prints formatted list of themes to stdout
# ═══════════════════════════════════════════════════════════════════════════════
ThemeManager::list() {
    local current
    current="$(ThemeManager::current)"

    echo "Available starship themes:"
    echo ""

    local theme
    for theme in "${THEME_VALID_NAMES[@]}"; do
        local description
        description="$(ThemeManager::_description "${theme}")"

        if [[ "${theme}" == "${current}" ]]; then
            echo "  * ${theme} (active) — ${description}"
        else
            echo "    ${theme} — ${description}"
        fi
    done

    echo ""
    echo "Switch: dotfiles-theme <theme>"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Show a preview of what a theme's prompt looks like
# @param $1 {string} Theme name (minimal, full, powerline)
# @return Prints a visual preview snippet to stdout
# @example ThemeManager::preview "full"
# ═══════════════════════════════════════════════════════════════════════════════
ThemeManager::preview() {
    local theme="${1:?Theme name required}"

    if ! ThemeManager::_is_valid "${theme}"; then
        Logger::error "ThemeManager: invalid theme '${theme}'"
        Logger::info "ThemeManager: valid themes: ${THEME_VALID_NAMES[*]}"
        return 1
    fi

    local theme_file="${THEME_PRESETS_DIR}/${theme}.toml"
    if [[ ! -f "${theme_file}" ]]; then
        Logger::error "ThemeManager: theme file not found: ${theme_file}"
        return 1
    fi

    echo ""
    echo "  Theme: ${theme}"
    echo "  Description: $(ThemeManager::_description "${theme}")"
    echo "  ──────────────────────────────────────────────────────────────────"
    echo ""

    case "${theme}" in
        minimal)
            echo "  Prompt preview (no nerd fonts needed):"
            echo ""
            echo "    ~/projects/myapp main *+2 3.2s"
            echo "    >"
            echo ""
            echo "  Features: directory, git branch/status, cmd duration"
            echo "  Fonts:    any monospace font"
            echo "  Speed:    fastest (all language modules disabled)"
            ;;
        full)
            echo "  Prompt preview (requires Nerd Font):"
            echo ""
            echo "     user@host  ~/projects/myapp   main *+2  +5 -2"
            echo "         v3.11(venv)  v20.1   v1.75   v1.21"
            echo "     12:45"
            echo "    >"
            echo ""
            echo "  Features: OS icon, user/host, git metrics, all languages,"
            echo "            docker, k8s, terraform, nix, time, status"
            echo "  Fonts:    Nerd Font required"
            echo "  Colors:   Catppuccin Mocha palette"
            ;;
        powerline)
            echo "  Prompt preview (requires Nerd Font with Powerline):"
            echo ""
            echo "     user  ~/projects/myapp   main *   v3.11   12:45 "
            echo "    >"
            echo ""
            echo "  Features: colored segments with arrow separators,"
            echo "            OS, user, dir, git, languages, docker, k8s, time"
            echo "  Fonts:    Nerd Font with Powerline symbols"
            echo "  Colors:   Catppuccin Mocha palette"
            ;;
    esac

    echo ""
    echo "  ──────────────────────────────────────────────────────────────────"
    echo "  Format (from ${theme}.toml):"
    echo ""

    # Extract and display the format string from the theme file
    local in_format=0
    local line
    while IFS= read -r line; do
        if [[ "${in_format}" -eq 0 ]] && [[ "${line}" =~ ^format ]]; then
            in_format=1
            echo "    ${line}"
        elif [[ "${in_format}" -eq 1 ]]; then
            echo "    ${line}"
            # End of multi-line format block: closing triple quotes
            if [[ "${line}" == *'"""' ]]; then
                break
            fi
        fi
    done < "${theme_file}"

    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Validate that a theme name is in the supported list
# @param $1 {string} Theme name to validate
# @return 0 if valid, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
ThemeManager::_is_valid() {
    local theme="${1}"
    local valid

    for valid in "${THEME_VALID_NAMES[@]}"; do
        if [[ "${valid}" == "${theme}" ]]; then
            return 0
        fi
    done

    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Get a short description for a theme
# @param $1 {string} Theme name
# @return Prints description string
# ═══════════════════════════════════════════════════════════════════════════════
ThemeManager::_description() {
    local theme="${1}"

    case "${theme}" in
        minimal)   echo "Clean, fast, no nerd fonts required" ;;
        full)      echo "All segments, Nerd Font icons, Catppuccin colors" ;;
        powerline) echo "Colored segments with arrow separators" ;;
        *)         echo "Unknown theme" ;;
    esac
}

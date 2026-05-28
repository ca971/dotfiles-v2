#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/hotload/engine.sh
# @description Hot-loading engine — orchestrates tool install/uninstall lifecycle
# @class HotLoadEngine
# @since 1.0.0
# @version 1.0.0
# @see docs/HOTLOAD.md
#
# Usage:
#   source lib/hotload/engine.sh
#   HotLoadEngine::install "bat"
#   HotLoadEngine::uninstall "bat"
#   HotLoadEngine::install_all
#   HotLoadEngine::install_profile "dev"
#   HotLoadEngine::list_profiles
#   HotLoadEngine::status
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────────────────────
# Source dependencies
# ───────────────────────────────────────────────────────────────────────────────
readonly _HOTLOAD_DIR="${DOTFILES_DIR:-${HOME}/.dotfiles}/lib/hotload"

# shellcheck source=lib/core/logger.sh
source "${DOTFILES_DIR}/lib/core/logger.sh"
# shellcheck source=lib/core/platform.sh
source "${DOTFILES_DIR}/lib/core/platform.sh"
# shellcheck source=lib/core/validator.sh
source "${DOTFILES_DIR}/lib/core/validator.sh"
# shellcheck source=lib/hotload/state.sh
source "${_HOTLOAD_DIR}/state.sh"
# shellcheck source=lib/hotload/install.sh
source "${_HOTLOAD_DIR}/install.sh"
# shellcheck source=lib/hotload/uninstall.sh
source "${_HOTLOAD_DIR}/uninstall.sh"

# Source all adapters
# shellcheck source=lib/hotload/adapters/_base.sh
source "${_HOTLOAD_DIR}/adapters/_base.sh"
# shellcheck source=lib/hotload/adapters/mise.sh
source "${_HOTLOAD_DIR}/adapters/mise.sh"
# shellcheck source=lib/hotload/adapters/uv.sh
source "${_HOTLOAD_DIR}/adapters/uv.sh"
# shellcheck source=lib/hotload/adapters/curl.sh
source "${_HOTLOAD_DIR}/adapters/curl.sh"
# shellcheck source=lib/hotload/adapters/cargo.sh
source "${_HOTLOAD_DIR}/adapters/cargo.sh"
# shellcheck source=lib/hotload/adapters/brew.sh
source "${_HOTLOAD_DIR}/adapters/brew.sh"
# shellcheck source=lib/hotload/adapters/git.sh
source "${_HOTLOAD_DIR}/adapters/git.sh"
# shellcheck source=lib/hotload/adapters/system.sh
source "${_HOTLOAD_DIR}/adapters/system.sh"

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install a single tool by name
# @param $1 {string} Tool name (must have a descriptor in tools/available/)
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
HotLoadEngine::install() {
    local tool="${1:?Tool name required}"

    local toml_file="${DOTFILES_DIR}/tools/available/${tool}.toml"
    if [[ ! -f "${toml_file}" ]]; then
        Logger::error "HotLoadEngine: unknown tool '${tool}' (no descriptor found)"
        return 1
    fi

    ToolInstaller::install "${tool}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Uninstall a single tool by name
# @param $1 {string} Tool name
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
HotLoadEngine::uninstall() {
    local tool="${1:?Tool name required}"
    ToolUninstaller::uninstall "${tool}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install all tools from tools/available/ that are not yet installed
# @return Number of failures (0 = all succeeded)
# ═══════════════════════════════════════════════════════════════════════════════
HotLoadEngine::install_all() {
    local tools_dir="${DOTFILES_DIR}/tools/available"
    local failures=0
    local total=0
    local installed=0

    Logger::info "HotLoadEngine: scanning tools/available/..."

    local toml_file tool
    for toml_file in "${tools_dir}"/*.toml; do
        [[ -f "${toml_file}" ]] || continue
        [[ -s "${toml_file}" ]] || continue

        tool="$(basename "${toml_file}" .toml)"
        (( total++ ))

        if StateManager::is_installed "${tool}"; then
            Logger::debug "HotLoadEngine: ${tool} already installed, skipping"
            (( installed++ ))
            continue
        fi

        if ToolInstaller::install "${tool}"; then
            (( installed++ ))
        else
            (( failures++ ))
            Logger::warn "HotLoadEngine: failed to install ${tool}, continuing..."
        fi
    done

    Logger::info "HotLoadEngine: ${installed}/${total} tools installed (${failures} failures)"
    return "${failures}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Verify all installed tools are still functional
# @return Number of broken tools
# ═══════════════════════════════════════════════════════════════════════════════
HotLoadEngine::verify() {
    local tools_dir="${DOTFILES_DIR}/tools/available"
    local broken=0

    Logger::info "HotLoadEngine: verifying installed tools..."

    local tool
    while IFS= read -r tool; do
        [[ -n "${tool}" ]] || continue

        local toml_file="${tools_dir}/${tool}.toml"
        if [[ ! -f "${toml_file}" ]] || [[ ! -s "${toml_file}" ]]; then
            continue
        fi

        if ! command -v taplo >/dev/null 2>&1; then
            continue
        fi

        local verify_cmd
        verify_cmd="$(taplo get -f "${toml_file}" -o json 2>/dev/null | jq -r '.meta.verify // empty')"

        if [[ -n "${verify_cmd}" ]]; then
            if ! eval "${verify_cmd}" >/dev/null 2>&1; then
                Logger::warn "HotLoadEngine: ${tool} verification failed (${verify_cmd})"
                (( broken++ ))
            fi
        fi
    done < <(StateManager::list_installed)

    if [[ "${broken}" -eq 0 ]]; then
        Logger::success "HotLoadEngine: all installed tools verified"
    else
        Logger::warn "HotLoadEngine: ${broken} tools failed verification"
    fi

    return "${broken}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Show status of all tools (installed vs available)
# @return Prints formatted status table
# ═══════════════════════════════════════════════════════════════════════════════
HotLoadEngine::status() {
    local tools_dir="${DOTFILES_DIR}/tools/available"
    local total=0
    local installed=0

    printf "%-25s %-12s %-10s %s\n" "TOOL" "STATUS" "METHOD" "VERSION"
    printf "%-25s %-12s %-10s %s\n" "────" "──────" "──────" "───────"

    local toml_file tool
    for toml_file in "${tools_dir}"/*.toml; do
        [[ -f "${toml_file}" ]] || continue
        [[ -s "${toml_file}" ]] || continue

        tool="$(basename "${toml_file}" .toml)"
        (( total++ ))

        if StateManager::is_installed "${tool}"; then
            local method version
            method="$(StateManager::get_method "${tool}")"
            version="$(StateManager::get ".tools.\"${tool}\".version")"
            printf "%-25s %-12s %-10s %s\n" "${tool}" "installed" "${method}" "${version:-unknown}"
            (( installed++ ))
        else
            printf "%-25s %-12s %-10s %s\n" "${tool}" "available" "-" "-"
        fi
    done

    echo ""
    echo "Total: ${total} available, ${installed} installed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description List all available tools (from descriptors)
# @return Prints tool names, one per line
# ═══════════════════════════════════════════════════════════════════════════════
HotLoadEngine::list_available() {
    find "${DOTFILES_DIR}/tools/available" -name '*.toml' -exec basename {} .toml \; 2>/dev/null | sort
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description List all available profiles with their descriptions
# @return Prints formatted profile list
# ═══════════════════════════════════════════════════════════════════════════════
HotLoadEngine::list_profiles() {
    local profiles_file="${DOTFILES_DIR}/definitions/profiles.toml"

    if [[ ! -f "${profiles_file}" ]]; then
        Logger::error "HotLoadEngine: profiles file not found: ${profiles_file}"
        return 1
    fi

    if ! command -v taplo >/dev/null 2>&1; then
        Logger::error "HotLoadEngine: taplo required for TOML parsing"
        return 1
    fi

    local json
    json="$(taplo get -f "${profiles_file}" -o json 2>/dev/null)" || {
        Logger::error "HotLoadEngine: failed to parse profiles.toml"
        return 1
    }

    printf "%-12s %-40s %s\n" "PROFILE" "DESCRIPTION" "EXTENDS"
    printf "%-12s %-40s %s\n" "───────" "───────────" "───────"

    local profile description extends_profile tool_count
    while IFS= read -r profile; do
        [[ -n "${profile}" ]] || continue
        description="$(echo "${json}" | jq -r ".profiles.\"${profile}\".description // \"-\"")"
        extends_profile="$(echo "${json}" | jq -r ".profiles.\"${profile}\".extends // \"-\"")"
        tool_count="$(echo "${json}" | jq -r ".profiles.\"${profile}\".tools | length")"
        printf "%-12s %-40s %-10s (%d tools)\n" "${profile}" "${description}" "${extends_profile}" "${tool_count}"
    done < <(echo "${json}" | jq -r '.profiles | keys[]')
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Resolve a profile's complete tool list (including extended profiles)
# @param $1 {string} Profile name
# @param $2 {string} JSON blob from profiles.toml (internal)
# @return Prints deduplicated tool list (one per line)
# ═══════════════════════════════════════════════════════════════════════════════
HotLoadEngine::_resolve_profile_tools() {
    local profile="${1:?Profile name required}"
    local json="${2:?JSON data required}"
    local -a visited=()

    # Guard against circular extends
    if [[ "${#}" -ge 3 ]]; then
        IFS=',' read -ra visited <<< "${3}"
    fi

    # Check for circular reference
    local v
    for v in "${visited[@]+"${visited[@]}"}"; do
        if [[ "${v}" == "${profile}" ]]; then
            Logger::error "HotLoadEngine: circular extends detected: ${profile}"
            return 1
        fi
    done
    visited+=("${profile}")

    # Verify profile exists
    local exists
    exists="$(echo "${json}" | jq -r ".profiles.\"${profile}\" // empty")"
    if [[ -z "${exists}" ]]; then
        Logger::error "HotLoadEngine: profile '${profile}' not found in definitions/profiles.toml"
        return 1
    fi

    # Get this profile's direct tools
    echo "${json}" | jq -r ".profiles.\"${profile}\".tools[]"

    # Recursively resolve extends chain
    local extends_profile
    extends_profile="$(echo "${json}" | jq -r ".profiles.\"${profile}\".extends // empty")"
    if [[ -n "${extends_profile}" ]]; then
        local visited_str
        visited_str="$(IFS=','; echo "${visited[*]}")"
        HotLoadEngine::_resolve_profile_tools "${extends_profile}" "${json}" "${visited_str}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install all tools defined in a profile (resolving extends chain)
# @param $1 {string} Profile name (minimal, dev, devops, data, server, full)
# @return 0 on success, number of failures otherwise
# @example HotLoadEngine::install_profile "dev"
# ═══════════════════════════════════════════════════════════════════════════════
HotLoadEngine::install_profile() {
    local profile="${1:?Profile name required}"
    local profiles_file="${DOTFILES_DIR}/definitions/profiles.toml"

    if [[ ! -f "${profiles_file}" ]]; then
        Logger::error "HotLoadEngine: profiles file not found: ${profiles_file}"
        return 1
    fi

    if ! command -v taplo >/dev/null 2>&1; then
        Logger::error "HotLoadEngine: taplo required for TOML parsing"
        return 1
    fi

    local json
    json="$(taplo get -f "${profiles_file}" -o json 2>/dev/null)" || {
        Logger::error "HotLoadEngine: failed to parse profiles.toml"
        return 1
    }

    # Resolve profile description for display
    local description
    description="$(echo "${json}" | jq -r ".profiles.\"${profile}\".description // empty")"
    if [[ -z "${description}" ]]; then
        Logger::error "HotLoadEngine: unknown profile '${profile}'"
        Logger::info "Available profiles: $(echo "${json}" | jq -r '.profiles | keys | join(", ")')"
        return 1
    fi

    Logger::info "HotLoadEngine: installing profile '${profile}' (${description})"

    # Resolve full tool list (deduplicated, sorted)
    local -a tools=()
    local tool
    while IFS= read -r tool; do
        [[ -n "${tool}" ]] || continue
        tools+=("${tool}")
    done < <(HotLoadEngine::_resolve_profile_tools "${profile}" "${json}" | sort -u)

    if [[ "${#tools[@]}" -eq 0 ]]; then
        Logger::warn "HotLoadEngine: profile '${profile}' has no tools to install"
        return 0
    fi

    Logger::info "HotLoadEngine: ${#tools[@]} unique tools to install for profile '${profile}'"

    local failures=0
    local installed=0
    local skipped=0
    local total="${#tools[@]}"

    for tool in "${tools[@]}"; do
        local toml_file="${DOTFILES_DIR}/tools/available/${tool}.toml"

        # Skip tools without descriptors (warning only)
        if [[ ! -f "${toml_file}" ]]; then
            Logger::warn "HotLoadEngine: no descriptor for '${tool}', skipping"
            (( skipped++ ))
            continue
        fi

        # Skip already installed tools
        if StateManager::is_installed "${tool}"; then
            Logger::debug "HotLoadEngine: ${tool} already installed, skipping"
            (( installed++ ))
            continue
        fi

        # Install via the standard pipeline
        if ToolInstaller::install "${tool}"; then
            (( installed++ ))
        else
            (( failures++ ))
            Logger::warn "HotLoadEngine: failed to install '${tool}', continuing..."
        fi
    done

    # Summary report
    echo ""
    Logger::info "═══ Profile Install Summary: ${profile} ═══"
    Logger::info "  Total tools in profile: ${total}"
    Logger::info "  Successfully installed:  ${installed}"
    if [[ "${skipped}" -gt 0 ]]; then
        Logger::warn "  Skipped (no descriptor): ${skipped}"
    fi
    if [[ "${failures}" -gt 0 ]]; then
        Logger::error "  Failed:                  ${failures}"
    else
        Logger::success "HotLoadEngine: profile '${profile}' installed successfully"
    fi

    return "${failures}"
}

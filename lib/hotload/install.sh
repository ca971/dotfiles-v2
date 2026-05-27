#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/hotload/install.sh
# @description Tool installation dispatcher — resolves best adapter per platform
# @class ToolInstaller
# @since 1.0.0
# @version 1.0.0
# @see lib/hotload/engine.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# @description Parse a tool TOML descriptor and extract install strategies
# @param $1 {string} Path to tool TOML file
# @return Prints JSON array of install strategies via jq
# ═══════════════════════════════════════════════════════════════════════════════
ToolInstaller::parse_descriptor() {
    local toml_file="${1:?TOML file path required}"

    if ! command -v taplo >/dev/null 2>&1; then
        Logger::error "ToolInstaller: taplo required for TOML parsing"
        return 1
    fi

    taplo get -f "${toml_file}" -o json 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Resolve the best install method for the current platform
# @param $1 {string} Tool name
# @return Prints "method|package|version|command" or returns 1
# ═══════════════════════════════════════════════════════════════════════════════
ToolInstaller::resolve_method() {
    local tool="${1:?Tool name required}"
    local toml_file="${DOTFILES_DIR}/tools/available/${tool}.toml"

    if [[ ! -f "${toml_file}" ]]; then
        Logger::error "ToolInstaller: descriptor not found: ${toml_file}"
        return 1
    fi

    local json
    json="$(ToolInstaller::parse_descriptor "${toml_file}")" || return 1

    local current_platform="${PLATFORM_OS}"
    if [[ "${PLATFORM_IS_WSL}" -eq 1 ]]; then
        current_platform="wsl"
    fi

    local count
    count="$(echo "${json}" | jq '.install | length')"

    local i method platforms_match
    for (( i=0; i<count; i++ )); do
        method="$(echo "${json}" | jq -r ".install[${i}].method")"

        # Check platform compatibility using jq directly
        local has_platforms
        has_platforms="$(echo "${json}" | jq ".install[${i}].platforms | length" 2>/dev/null || echo "0")"

        platforms_match=0
        if [[ "${has_platforms}" -eq 0 ]]; then
            platforms_match=1
        else
            local distro_platform="${PLATFORM_OS}.${PLATFORM_DISTRO}"
            local match_result
            match_result="$(echo "${json}" | jq -r --arg cp "${current_platform}" --arg os "${PLATFORM_OS}" --arg dp "${distro_platform}" \
                ".install[${i}].platforms | any(. == \$cp or . == \$os or . == \$dp or (. == \"bsd\" and (\$os | test(\"bsd\"))))" 2>/dev/null || echo "false")"
            if [[ "${match_result}" == "true" ]]; then
                platforms_match=1
            fi
        fi

        if [[ "${platforms_match}" -eq 0 ]]; then
            continue
        fi

        # Check if the adapter is available
        local adapter_available=0
        case "${method}" in
            mise)   MiseAdapter::is_available && adapter_available=1 ;;
            uv)     UvAdapter::is_available && adapter_available=1 ;;
            curl)   CurlAdapter::is_available && adapter_available=1 ;;
            cargo)  CargoAdapter::is_available && adapter_available=1 ;;
            brew)   BrewAdapter::is_available && adapter_available=1 ;;
            system) SystemAdapter::is_available && adapter_available=1 ;;
        esac

        if [[ "${adapter_available}" -eq 1 ]]; then
            local pkg version cmd
            pkg="$(echo "${json}" | jq -r ".install[${i}].package // .install[${i}].plugin // .install[${i}].crate // \"${tool}\"")"
            version="$(echo "${json}" | jq -r ".install[${i}].version // \"latest\"")"
            cmd="$(echo "${json}" | jq -r ".install[${i}].command // empty")"
            echo "${method}|${pkg}|${version}|${cmd}"
            return 0
        fi
    done

    Logger::error "ToolInstaller: no compatible install method for ${tool} on ${current_platform}"
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Install a tool using the resolved method
# @param $1 {string} Tool name
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
ToolInstaller::install() {
    local tool="${1:?Tool name required}"

    if StateManager::is_installed "${tool}"; then
        Logger::debug "ToolInstaller: ${tool} already installed"
        return 0
    fi

    local resolution
    resolution="$(ToolInstaller::resolve_method "${tool}")" || return 1

    IFS='|' read -r method pkg version cmd <<< "${resolution}"

    Logger::info "Installing ${tool} via ${method}..."

    local rc=0
    case "${method}" in
        mise)   MiseAdapter::install "${pkg}" "${version}" || rc=1 ;;
        uv)     UvAdapter::install "${pkg}" "${version}" || rc=1 ;;
        curl)   CurlAdapter::install "${tool}" "${version}" "${cmd}" || rc=1 ;;
        cargo)  CargoAdapter::install "${pkg}" "${version}" || rc=1 ;;
        brew)   BrewAdapter::install "${pkg}" "${version}" || rc=1 ;;
        system) SystemAdapter::install "${pkg}" "${version}" || rc=1 ;;
        *)      Logger::error "ToolInstaller: unknown method: ${method}"; return 1 ;;
    esac

    if [[ "${rc}" -eq 0 ]]; then
        StateManager::mark_installed "${tool}" "${method}" "${version}"
        ToolInstaller::setup_config "${tool}"
        Logger::success "Installed ${tool} via ${method}"
    else
        Logger::error "Failed to install ${tool} via ${method}"
    fi

    return "${rc}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Create config symlinks for an installed tool
# @param $1 {string} Tool name
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
ToolInstaller::setup_config() {
    local tool="${1:?Tool name required}"
    local toml_file="${DOTFILES_DIR}/tools/available/${tool}.toml"

    if [[ ! -f "${toml_file}" ]]; then
        return 0  # no descriptor, nothing to configure
    fi

    local json
    json="$(ToolInstaller::parse_descriptor "${toml_file}" 2>/dev/null)" || return 0

    # Count symlinks
    local symlink_count
    symlink_count="$(echo "${json}" | jq '.config.symlinks | length' 2>/dev/null || echo 0)"

    if [[ "${symlink_count}" -eq 0 ]]; then
        return 0  # no symlinks to create
    fi

    Logger::debug "ToolInstaller: setting up ${symlink_count} config symlinks for ${tool}"

    local i src dst expanded_dst
    for (( i=0; i<symlink_count; i++ )); do
        src="$(echo "${json}" | jq -r ".config.symlinks[${i}].src")"
        dst="$(echo "${json}" | jq -r ".config.symlinks[${i}].dst")"

        [[ -z "${src}" || -z "${dst}" || "${src}" == "null" || "${dst}" == "null" ]] && continue

        # Expand ~ to HOME
        expanded_dst="${dst/\~/${HOME}}"

        # Resolve src relative to DOTFILES_DIR
        local full_src="${DOTFILES_DIR}/${src}"

        if [[ ! -e "${full_src}" ]]; then
            Logger::warn "ToolInstaller: config source not found: ${full_src}"
            continue
        fi

        # Create parent directory
        local dst_dir
        dst_dir="$(dirname "${expanded_dst}")"
        if [[ ! -d "${dst_dir}" ]]; then
            mkdir -p "${dst_dir}"
        fi

        # Remove existing symlink or directory
        if [[ -L "${expanded_dst}" ]] || [[ -d "${expanded_dst}" ]]; then
            rm -rf "${expanded_dst}"
        fi

        # Create symlink
        ln -sf "${full_src}" "${expanded_dst}"
        Logger::debug "ToolInstaller: ${expanded_dst} → ${full_src}"
    done

    return 0
}

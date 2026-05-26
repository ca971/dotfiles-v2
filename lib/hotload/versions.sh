#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/hotload/versions.sh
# @description Version lock file management and tool upgrade orchestration
# @class VersionManager
# @since 1.0.0
# @version 1.0.0
# @see lib/hotload/engine.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

readonly _VERSIONS_LOCK="${DOTFILES_DIR}/local/versions.lock"
readonly _TOOLS_DIR="${DOTFILES_DIR}/tools/available"

# ═══════════════════════════════════════════════════════════════════════════════
# @description Get the current version of an installed tool
# @param $1 {string} Tool name
# @return Prints version string or "unknown"
# ═══════════════════════════════════════════════════════════════════════════════
VersionManager::get_version() {
    local tool="${1:?Tool name required}"
    local toml_file="${_TOOLS_DIR}/${tool}.toml"

    if [[ ! -f "${toml_file}" ]] || [[ ! -s "${toml_file}" ]]; then
        echo "unknown"
        return
    fi

    local verify_cmd
    verify_cmd="$(taplo get -f "${toml_file}" -o json 2>/dev/null | jq -r '.meta.verify // empty')"

    if [[ -z "${verify_cmd}" ]]; then
        echo "unknown"
        return
    fi

    local version_output
    version_output="$(eval "${verify_cmd}" 2>&1 | head -1)" || true

    local version
    version="$(echo "${version_output}" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)"

    if [[ -n "${version}" ]]; then
        echo "${version}"
    else
        echo "unknown"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Generate lock file with current versions of all installed tools
# @return Creates/updates local/versions.lock
# ═══════════════════════════════════════════════════════════════════════════════
VersionManager::lock() {
    Logger::info "VersionManager: generating lock file..."

    local lock_content
    lock_content="# Auto-generated lock file — do not edit manually\n"
    lock_content+="# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)\n"
    lock_content+="# Use 'dotfiles lock' to regenerate\n\n"

    local count=0
    local tool

    while IFS= read -r tool; do
        [[ -n "${tool}" ]] || continue

        local version
        version="$(VersionManager::get_version "${tool}")"

        if [[ "${version}" != "unknown" ]]; then
            lock_content+="${tool}=${version}\n"
            (( count++ ))
        fi
    done < <(StateManager::list_installed)

    printf "%b" "${lock_content}" > "${_VERSIONS_LOCK}"
    Logger::success "VersionManager: locked ${count} tool versions → local/versions.lock"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Compare current versions against lock file, report drift
# @return Prints drift report
# ═══════════════════════════════════════════════════════════════════════════════
VersionManager::check() {
    if [[ ! -f "${_VERSIONS_LOCK}" ]]; then
        Logger::error "VersionManager: no lock file found. Run 'dotfiles lock' first."
        return 1
    fi

    Logger::info "VersionManager: checking version drift..."

    local drifted=0
    local tool locked_version current_version

    while IFS='=' read -r tool locked_version; do
        [[ "${tool}" =~ ^#.*$ ]] && continue
        [[ -z "${tool}" ]] && continue

        current_version="$(VersionManager::get_version "${tool}")"

        if [[ "${current_version}" == "unknown" ]]; then
            printf "  %-20s %s → %s\n" "${tool}" "${locked_version}" "MISSING"
            (( drifted++ ))
        elif [[ "${current_version}" != "${locked_version}" ]]; then
            printf "  %-20s %s → %s\n" "${tool}" "${locked_version}" "${current_version}"
            (( drifted++ ))
        fi
    done < "${_VERSIONS_LOCK}"

    if [[ "${drifted}" -eq 0 ]]; then
        Logger::success "VersionManager: all tools match lock file"
    else
        Logger::warn "VersionManager: ${drifted} tools have drifted from lock file"
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Upgrade a single tool or all installed tools
# @param $1 {string} Tool name or "--all"
# @return 0 on success
# ═══════════════════════════════════════════════════════════════════════════════
VersionManager::upgrade() {
    local target="${1:---all}"

    if [[ "${target}" == "--all" ]]; then
        VersionManager::_upgrade_all
    else
        VersionManager::_upgrade_one "${target}"
    fi
}

VersionManager::_upgrade_one() {
    local tool="${1:?Tool name required}"

    if ! StateManager::is_installed "${tool}"; then
        Logger::error "VersionManager: ${tool} is not installed"
        return 1
    fi

    local method
    method="$(StateManager::get_method "${tool}")"
    local old_version
    old_version="$(VersionManager::get_version "${tool}")"

    Logger::info "Upgrading ${tool} (${method})..."

    local rc=0
    case "${method}" in
        mise)
            mise upgrade "${tool}@latest" 2>&1 || rc=1
            ;;
        uv)
            local pkg
            pkg="$(taplo get -f "${_TOOLS_DIR}/${tool}.toml" -o json 2>/dev/null | jq -r '.install[0].package // "'${tool}'"')"
            uv tool upgrade "${pkg}" 2>&1 || rc=1
            ;;
        cargo)
            local crate
            crate="$(taplo get -f "${_TOOLS_DIR}/${tool}.toml" -o json 2>/dev/null | jq -r '.install[0].crate // "'${tool}'"')"
            cargo install "${crate}" --force 2>&1 || rc=1
            ;;
        system)
            Logger::warn "VersionManager: system packages should be upgraded via system package manager"
            return 0
            ;;
        *)
            Logger::warn "VersionManager: no upgrade strategy for method '${method}'"
            return 0
            ;;
    esac

    if [[ "${rc}" -eq 0 ]]; then
        local new_version
        new_version="$(VersionManager::get_version "${tool}")"
        if [[ "${old_version}" != "${new_version}" ]]; then
            Logger::success "Upgraded ${tool}: ${old_version} → ${new_version}"
        else
            Logger::info "${tool} already at latest (${new_version})"
        fi
        VersionManager::_update_lock_entry "${tool}" "${new_version}"
    else
        Logger::error "Failed to upgrade ${tool}"
    fi

    return "${rc}"
}

VersionManager::_upgrade_all() {
    Logger::info "VersionManager: upgrading all installed tools..."

    local upgraded=0
    local failed=0
    local tool

    while IFS= read -r tool; do
        [[ -n "${tool}" ]] || continue

        local method
        method="$(StateManager::get_method "${tool}")"

        if [[ "${method}" == "system" ]]; then
            continue
        fi

        if VersionManager::_upgrade_one "${tool}"; then
            (( upgraded++ ))
        else
            (( failed++ ))
        fi
    done < <(StateManager::list_installed)

    Logger::info "VersionManager: ${upgraded} upgraded, ${failed} failed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Show tools that have newer versions available
# @return Prints outdated tools table
# ═══════════════════════════════════════════════════════════════════════════════
VersionManager::outdated() {
    Logger::info "VersionManager: checking for outdated tools..."

    if command -v mise >/dev/null 2>&1; then
        Logger::info "Mise-managed tools:"
        mise outdated 2>/dev/null || true
    fi

    if command -v uv >/dev/null 2>&1; then
        Logger::info "UV-managed tools:"
        uv tool list --outdated 2>/dev/null || uv tool list 2>/dev/null || true
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Pin a specific tool to an exact version
# @param $1 {string} Tool name
# @param $2 {string} Version to pin
# @return 0 on success
# ═══════════════════════════════════════════════════════════════════════════════
VersionManager::pin() {
    local tool="${1:?Tool name required}"
    local version="${2:?Version required}"

    local method
    method="$(StateManager::get_method "${tool}" 2>/dev/null || echo "")"

    if [[ -z "${method}" ]]; then
        Logger::error "VersionManager: ${tool} is not installed. Install it first."
        return 1
    fi

    Logger::info "Pinning ${tool} to version ${version}..."

    local rc=0
    case "${method}" in
        mise)
            mise install "${tool}@${version}" 2>&1 && mise use --global "${tool}@${version}" 2>&1 || rc=1
            ;;
        uv)
            local pkg
            pkg="$(taplo get -f "${_TOOLS_DIR}/${tool}.toml" -o json 2>/dev/null | jq -r '.install[0].package // "'${tool}'"')"
            uv tool install "${pkg}==${version}" --force 2>&1 || rc=1
            ;;
        cargo)
            local crate
            crate="$(taplo get -f "${_TOOLS_DIR}/${tool}.toml" -o json 2>/dev/null | jq -r '.install[0].crate // "'${tool}'"')"
            cargo install "${crate}" --version "${version}" --force 2>&1 || rc=1
            ;;
        *)
            Logger::error "VersionManager: cannot pin ${method}-managed tools"
            return 1
            ;;
    esac

    if [[ "${rc}" -eq 0 ]]; then
        VersionManager::_update_lock_entry "${tool}" "${version}"
        Logger::success "Pinned ${tool} to ${version}"
    else
        Logger::error "Failed to pin ${tool} to ${version}"
    fi

    return "${rc}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Update a single entry in the lock file
# @param $1 {string} Tool name
# @param $2 {string} Version
# ═══════════════════════════════════════════════════════════════════════════════
VersionManager::_update_lock_entry() {
    local tool="${1}"
    local version="${2}"

    if [[ ! -f "${_VERSIONS_LOCK}" ]]; then
        return
    fi

    if grep -q "^${tool}=" "${_VERSIONS_LOCK}" 2>/dev/null; then
        sed -i.bak "s/^${tool}=.*/${tool}=${version}/" "${_VERSIONS_LOCK}"
        rm -f "${_VERSIONS_LOCK}.bak"
    else
        echo "${tool}=${version}" >> "${_VERSIONS_LOCK}"
    fi
}

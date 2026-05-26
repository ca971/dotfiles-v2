#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/hotload/state.sh
# @description Persistent state manager for hot-loaded tools (JSON via jq)
# @class StateManager
# @since 1.0.0
# @version 1.0.0
# @see local/state.json
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────────────────────
# @field STATE_FILE
# @type string
# @description Path to the persistent state JSON file
# ───────────────────────────────────────────────────────────────────────────────
declare -g STATE_FILE="${STATE_FILE:-${DOTFILES_DIR:-${HOME}/.dotfiles}/local/state.json}"

# ═══════════════════════════════════════════════════════════════════════════════
# @description Initialize state file if it doesn't exist
# ═══════════════════════════════════════════════════════════════════════════════
StateManager::init() {
    if [[ ! -f "${STATE_FILE}" ]]; then
        local state_dir
        state_dir="$(dirname "${STATE_FILE}")"
        [[ -d "${state_dir}" ]] || mkdir -p "${state_dir}"
        echo '{"version":1,"tools":{},"nix_envs":{},"theme":"minimal"}' > "${STATE_FILE}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Read a value from the state file
# @param $1 {string} jq filter path (e.g., ".tools.bat.installed")
# @return Prints the value (raw output)
# ═══════════════════════════════════════════════════════════════════════════════
StateManager::get() {
    local path="${1:?jq path required}"
    jq -r "${path} // empty" "${STATE_FILE}" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Set a value in the state file (atomic write)
# @param $1 {string} jq filter path (e.g., ".tools.bat.installed")
# @param $2 {string} Value to set (JSON-compatible)
# ═══════════════════════════════════════════════════════════════════════════════
StateManager::set() {
    local path="${1:?jq path required}"
    local value="${2:?Value required}"

    local tmp_file
    tmp_file="$(mktemp)"

    if jq "${path} = ${value}" "${STATE_FILE}" > "${tmp_file}" 2>/dev/null; then
        mv "${tmp_file}" "${STATE_FILE}"
    else
        rm -f "${tmp_file}"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Record a tool as installed in state
# @param $1 {string} Tool name
# @param $2 {string} Install method used (mise, uv, curl, cargo, brew, system)
# @param $3 {string} Version installed
# ═══════════════════════════════════════════════════════════════════════════════
StateManager::mark_installed() {
    local tool="${1:?Tool name required}"
    local method="${2:?Method required}"
    local version="${3:-unknown}"

    local timestamp
    timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    local tmp_file
    tmp_file="$(mktemp)"

    jq --arg tool "${tool}" \
       --arg method "${method}" \
       --arg version "${version}" \
       --arg ts "${timestamp}" \
       '.tools[$tool] = {"installed": true, "method": $method, "version": $version, "installed_at": $ts}' \
       "${STATE_FILE}" > "${tmp_file}" && mv "${tmp_file}" "${STATE_FILE}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Record a tool as uninstalled in state
# @param $1 {string} Tool name
# ═══════════════════════════════════════════════════════════════════════════════
StateManager::mark_uninstalled() {
    local tool="${1:?Tool name required}"

    local tmp_file
    tmp_file="$(mktemp)"

    jq --arg tool "${tool}" \
       'del(.tools[$tool])' \
       "${STATE_FILE}" > "${tmp_file}" && mv "${tmp_file}" "${STATE_FILE}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check if a tool is recorded as installed
# @param $1 {string} Tool name
# @return 0 if installed, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
StateManager::is_installed() {
    local tool="${1:?Tool name required}"
    local result
    result="$(jq -r --arg tool "${tool}" '.tools[$tool].installed // false' "${STATE_FILE}" 2>/dev/null)"
    [[ "${result}" == "true" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Get the install method for a tool
# @param $1 {string} Tool name
# @return Prints the method name or empty
# ═══════════════════════════════════════════════════════════════════════════════
StateManager::get_method() {
    local tool="${1:?Tool name required}"
    jq -r --arg tool "${tool}" '.tools[$tool].method // empty' "${STATE_FILE}" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description List all installed tools
# @return Prints tool names, one per line
# ═══════════════════════════════════════════════════════════════════════════════
StateManager::list_installed() {
    jq -r '.tools | to_entries[] | select(.value.installed == true) | .key' "${STATE_FILE}" 2>/dev/null | sort
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Get current theme from state
# @return Prints theme name (minimal, full, powerline)
# ═══════════════════════════════════════════════════════════════════════════════
StateManager::get_theme() {
    jq -r '.theme // "minimal"' "${STATE_FILE}" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Set current theme in state
# @param $1 {string} Theme name
# ═══════════════════════════════════════════════════════════════════════════════
StateManager::set_theme() {
    local theme="${1:?Theme name required}"
    StateManager::set ".theme" "\"${theme}\""
}

# Initialize on source
StateManager::init

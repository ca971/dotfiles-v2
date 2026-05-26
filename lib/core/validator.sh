#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/core/validator.sh
# @description Input validation and sanitization utilities
# @class Validator
# @since 1.0.0
# @version 1.0.0
# @see docs/ARCHITECTURE.md
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# @description Validate that a string is not empty
# @param $1 {string} Value to check
# @param $2 {string} [optional] Variable name for error message
# @return 0 if non-empty, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
Validator::not_empty() {
    local value="${1:-}"
    local name="${2:-value}"

    if [[ -z "${value}" ]]; then
        Logger::error "Validator: '${name}' must not be empty"
        return 1
    fi
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Validate that a path is safe (no traversal, no null bytes)
# @param $1 {string} Path to validate
# @return 0 if safe, 1 if potentially dangerous
# ═══════════════════════════════════════════════════════════════════════════════
Validator::safe_path() {
    local path="${1:?Path required}"

    if [[ "${#path}" -ne "$(printf '%s' "${path}" | wc -c)" ]]; then
        Logger::error "Validator: path contains null bytes"
        return 1
    fi

    if [[ "${path}" == *".."* ]]; then
        Logger::error "Validator: path contains traversal sequence '..'"
        return 1
    fi

    if [[ "${path}" =~ ^[[:space:]] ]] || [[ "${path}" =~ [[:space:]]$ ]]; then
        Logger::error "Validator: path has leading/trailing whitespace"
        return 1
    fi

    if [[ "${path}" == *"|"* ]] || [[ "${path}" == *";"* ]] || [[ "${path}" == *"&"* ]] || [[ "${path}" == *'$('* ]] || [[ "${path}" == *'`'* ]]; then
        Logger::error "Validator: path contains shell metacharacters"
        return 1
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Validate that a command/binary exists in PATH
# @param $1 {string} Command name
# @return 0 if found, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
Validator::command_exists() {
    local cmd="${1:?Command name required}"
    command -v "${cmd}" >/dev/null 2>&1
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Validate that a file exists and is readable
# @param $1 {string} File path
# @return 0 if exists and readable, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
Validator::file_readable() {
    local path="${1:?File path required}"

    if [[ ! -f "${path}" ]]; then
        Logger::error "Validator: file does not exist: ${path}"
        return 1
    fi

    if [[ ! -r "${path}" ]]; then
        Logger::error "Validator: file is not readable: ${path}"
        return 1
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Validate that a directory exists and is writable
# @param $1 {string} Directory path
# @return 0 if exists and writable, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
Validator::dir_writable() {
    local path="${1:?Directory path required}"

    if [[ ! -d "${path}" ]]; then
        Logger::error "Validator: directory does not exist: ${path}"
        return 1
    fi

    if [[ ! -w "${path}" ]]; then
        Logger::error "Validator: directory is not writable: ${path}"
        return 1
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Validate a version string format (semver-like: X.Y.Z or X.Y)
# @param $1 {string} Version string
# @return 0 if valid format, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
Validator::version_format() {
    local version="${1:-}"

    if [[ -z "${version}" ]]; then
        Logger::error "Validator: version string is empty"
        return 1
    fi

    if [[ "${version}" == "latest" ]] || [[ "${version}" == "nightly" ]] || [[ "${version}" == "stable" ]]; then
        return 0
    fi

    if [[ "${version}" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?(-[a-zA-Z0-9._-]+)?$ ]]; then
        return 0
    fi

    Logger::error "Validator: invalid version format: ${version}"
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Validate a TOML file exists and has valid syntax (requires taplo)
# @param $1 {string} Path to TOML file
# @return 0 if valid, 1 otherwise (skips syntax check if taplo unavailable)
# ═══════════════════════════════════════════════════════════════════════════════
Validator::toml_file() {
    local path="${1:?TOML file path required}"

    Validator::file_readable "${path}" || return 1

    if Validator::command_exists "taplo"; then
        if ! taplo check "${path}" 2>/dev/null; then
            Logger::error "Validator: invalid TOML syntax: ${path}"
            return 1
        fi
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Validate URL format (basic check, no DNS resolution)
# @param $1 {string} URL to validate
# @return 0 if valid format, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
Validator::url_format() {
    local url="${1:?URL required}"

    if [[ "${url}" =~ ^https?://[a-zA-Z0-9]([a-zA-Z0-9._-]*[a-zA-Z0-9])?(/.*)?$ ]]; then
        return 0
    fi

    Logger::error "Validator: invalid URL format: ${url}"
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Validate that a value is in an allowed list
# @param $1 {string} Value to check
# @param $@ {string} Allowed values (remaining arguments)
# @return 0 if value is in list, 1 otherwise
# @example Validator::one_of "bash" "bash" "zsh" "fish" "nushell"
# ═══════════════════════════════════════════════════════════════════════════════
Validator::one_of() {
    local value="${1:?Value required}"
    shift

    local allowed
    for allowed in "$@"; do
        if [[ "${value}" == "${allowed}" ]]; then
            return 0
        fi
    done

    Logger::error "Validator: '${value}' not in allowed values: $*"
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Sanitize a string for safe use in filenames
# @param $1 {string} Input string
# @return Prints sanitized string (alphanumeric, dash, underscore, dot only)
# ═══════════════════════════════════════════════════════════════════════════════
Validator::sanitize_filename() {
    local input="${1:?Input required}"
    echo "${input}" | tr -cd '[:alnum:]._-'
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Validate file permissions match expected mode
# @param $1 {string} File path
# @param $2 {string} Expected permission (e.g., "700", "600")
# @return 0 if permissions match, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
Validator::permissions() {
    local path="${1:?Path required}"
    local expected="${2:?Expected permissions required}"

    if [[ ! -e "${path}" ]]; then
        Logger::error "Validator: path does not exist: ${path}"
        return 1
    fi

    local actual
    if [[ "$(uname -s)" == "Darwin" ]]; then
        actual="$(stat -f '%A' "${path}")"
    else
        actual="$(stat -c '%a' "${path}")"
    fi

    if [[ "${actual}" != "${expected}" ]]; then
        Logger::error "Validator: ${path} has permissions ${actual}, expected ${expected}"
        return 1
    fi

    return 0
}

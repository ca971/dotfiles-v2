#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/core/fs.sh
# @description Safe filesystem operations (mkdir, symlink, atomic write, chmod)
# @class FileSystem
# @since 1.0.0
# @version 1.0.0
# @see docs/ARCHITECTURE.md
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════════
# @description Create a directory with parents, only if it does not exist
# @param $1 {string} Directory path
# @param $2 {string} [optional] Permissions mode (default: 755)
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
FileSystem::mkdir() {
    local path="${1:?Directory path required}"
    local mode="${2:-755}"

    Validator::safe_path "${path}" || return 1

    if [[ -d "${path}" ]]; then
        return 0
    fi

    if ! mkdir -p "${path}"; then
        Logger::error "FileSystem: failed to create directory: ${path}"
        return 1
    fi

    chmod "${mode}" "${path}"
    Logger::debug "FileSystem: created directory ${path} (mode: ${mode})"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Create a symlink with safety checks and backup
# @param $1 {string} Source (target of the link)
# @param $2 {string} Destination (where the link is created)
# @param $3 {boolean} [optional] Force overwrite (default: 0)
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
FileSystem::symlink() {
    local source="${1:?Source path required}"
    local dest="${2:?Destination path required}"
    local force="${3:-0}"

    Validator::safe_path "${source}" || return 1
    Validator::safe_path "${dest}" || return 1

    if [[ ! -e "${source}" ]]; then
        Logger::error "FileSystem: symlink source does not exist: ${source}"
        return 1
    fi

    if [[ -L "${dest}" ]]; then
        local current_target
        current_target="$(readlink "${dest}")"
        if [[ "${current_target}" == "${source}" ]]; then
            Logger::debug "FileSystem: symlink already correct: ${dest} -> ${source}"
            return 0
        fi

        if [[ "${force}" -eq 1 ]]; then
            rm -f "${dest}"
        else
            Logger::warn "FileSystem: symlink exists with different target: ${dest} -> ${current_target}"
            return 1
        fi
    elif [[ -e "${dest}" ]]; then
        if [[ "${force}" -eq 1 ]]; then
            local backup
            backup="${dest}.backup.$(date +%s)"
            mv "${dest}" "${backup}"
            Logger::warn "FileSystem: backed up existing file: ${dest} -> ${backup}"
        else
            Logger::error "FileSystem: destination exists and is not a symlink: ${dest}"
            return 1
        fi
    fi

    local dest_dir
    dest_dir="$(dirname "${dest}")"
    FileSystem::mkdir "${dest_dir}" || return 1

    ln -s "${source}" "${dest}"
    Logger::debug "FileSystem: created symlink ${dest} -> ${source}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Write content to a file atomically (write to temp, then move)
# @param $1 {string} Destination file path
# @param $2 {string} Content to write (passed via stdin if empty)
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
FileSystem::atomic_write() {
    local dest="${1:?Destination path required}"
    local content="${2:-}"

    Validator::safe_path "${dest}" || return 1

    local dest_dir
    dest_dir="$(dirname "${dest}")"
    FileSystem::mkdir "${dest_dir}" || return 1

    local tmp_file
    tmp_file="$(mktemp "${dest_dir}/.tmp.XXXXXX")"

    if [[ -n "${content}" ]]; then
        echo "${content}" > "${tmp_file}"
    else
        cat > "${tmp_file}"
    fi

    if ! mv "${tmp_file}" "${dest}"; then
        rm -f "${tmp_file}"
        Logger::error "FileSystem: atomic write failed for: ${dest}"
        return 1
    fi

    Logger::debug "FileSystem: wrote ${dest}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Set file permissions safely
# @param $1 {string} File or directory path
# @param $2 {string} Permissions mode (e.g., "600", "755")
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
FileSystem::chmod() {
    local path="${1:?Path required}"
    local mode="${2:?Mode required}"

    if [[ ! -e "${path}" ]]; then
        Logger::error "FileSystem: cannot chmod non-existent path: ${path}"
        return 1
    fi

    chmod "${mode}" "${path}"
    Logger::debug "FileSystem: set permissions ${mode} on ${path}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Remove a file or symlink safely (refuses to remove directories)
# @param $1 {string} Path to remove
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
FileSystem::remove() {
    local path="${1:?Path required}"

    if [[ -d "${path}" ]] && [[ ! -L "${path}" ]]; then
        Logger::error "FileSystem: refusing to remove directory (use rm -rf manually): ${path}"
        return 1
    fi

    if [[ -e "${path}" ]] || [[ -L "${path}" ]]; then
        rm -f "${path}"
        Logger::debug "FileSystem: removed ${path}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check if a path is a valid symlink pointing to expected target
# @param $1 {string} Symlink path
# @param $2 {string} Expected target
# @return 0 if valid and correct, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
FileSystem::symlink_valid() {
    local link="${1:?Symlink path required}"
    local expected="${2:?Expected target required}"

    if [[ ! -L "${link}" ]]; then
        return 1
    fi

    local actual
    actual="$(readlink "${link}")"
    [[ "${actual}" == "${expected}" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Get the real/resolved path (follows symlinks)
# @param $1 {string} Path to resolve
# @return Prints the resolved absolute path
# ═══════════════════════════════════════════════════════════════════════════════
FileSystem::realpath() {
    local path="${1:?Path required}"

    if command -v realpath >/dev/null 2>&1; then
        realpath "${path}"
    elif command -v readlink >/dev/null 2>&1; then
        if [[ "$(uname -s)" == "Darwin" ]]; then
            perl -MCwd -e 'print Cwd::abs_path shift' "${path}"
        else
            readlink -f "${path}"
        fi
    else
        echo "${path}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Ensure a directory exists with restricted permissions (for secrets)
# @param $1 {string} Directory path
# @return 0 on success
# ═══════════════════════════════════════════════════════════════════════════════
FileSystem::ensure_private_dir() {
    local path="${1:?Path required}"
    FileSystem::mkdir "${path}" "700"
}

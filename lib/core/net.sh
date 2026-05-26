#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/core/net.sh
# @description Network utilities (download, retry, checksum verification)
# @class Network
# @since 1.0.0
# @version 1.0.0
# @see docs/ARCHITECTURE.md
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────────────────────
# @field NETWORK_MAX_RETRIES
# @type integer
# @description Maximum number of download retry attempts
# ───────────────────────────────────────────────────────────────────────────────
readonly NETWORK_MAX_RETRIES="${NETWORK_MAX_RETRIES:-3}"

# ───────────────────────────────────────────────────────────────────────────────
# @field NETWORK_RETRY_DELAY
# @type integer
# @description Delay in seconds between retry attempts
# ───────────────────────────────────────────────────────────────────────────────
readonly NETWORK_RETRY_DELAY="${NETWORK_RETRY_DELAY:-2}"

# ───────────────────────────────────────────────────────────────────────────────
# @field NETWORK_TIMEOUT
# @type integer
# @description Connection timeout in seconds
# ───────────────────────────────────────────────────────────────────────────────
readonly NETWORK_TIMEOUT="${NETWORK_TIMEOUT:-30}"

# ═══════════════════════════════════════════════════════════════════════════════
# @description Download a file with retry logic
# @param $1 {string} URL to download
# @param $2 {string} Destination file path
# @param $3 {integer} [optional] Max retries (default: NETWORK_MAX_RETRIES)
# @return 0 on success, 1 on failure after all retries
# ═══════════════════════════════════════════════════════════════════════════════
Network::download() {
    local url="${1:?URL required}"
    local dest="${2:?Destination path required}"
    local max_retries="${3:-${NETWORK_MAX_RETRIES}}"

    Validator::safe_path "${dest}" || return 1

    local dest_dir
    dest_dir="$(dirname "${dest}")"
    FileSystem::mkdir "${dest_dir}" || return 1

    local attempt=1
    while (( attempt <= max_retries )); do
        Logger::debug "Network: downloading ${url} (attempt ${attempt}/${max_retries})"

        if curl -fsSL \
            --connect-timeout "${NETWORK_TIMEOUT}" \
            --max-time "$(( NETWORK_TIMEOUT * 4 ))" \
            --retry 0 \
            -o "${dest}" \
            "${url}" 2>/dev/null; then
            Logger::debug "Network: download complete: ${dest}"
            return 0
        fi

        Logger::warn "Network: download failed (attempt ${attempt}/${max_retries}): ${url}"
        (( attempt++ ))

        if (( attempt <= max_retries )); then
            sleep "${NETWORK_RETRY_DELAY}"
        fi
    done

    Logger::error "Network: download failed after ${max_retries} attempts: ${url}"
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Download and execute a script (with safety prompt in interactive mode)
# @param $1 {string} URL of the script
# @param $2 {string} [optional] Arguments to pass to the script
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
Network::download_and_exec() {
    local url="${1:?URL required}"
    shift
    local args=("$@")

    local tmp_script
    tmp_script="$(mktemp)"

    if ! Network::download "${url}" "${tmp_script}"; then
        rm -f "${tmp_script}"
        return 1
    fi

    chmod +x "${tmp_script}"

    if ! bash "${tmp_script}" "${args[@]+"${args[@]}"}"; then
        Logger::error "Network: script execution failed: ${url}"
        rm -f "${tmp_script}"
        return 1
    fi

    rm -f "${tmp_script}"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Verify file checksum (SHA-256)
# @param $1 {string} File path
# @param $2 {string} Expected SHA-256 hash
# @return 0 if checksum matches, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
Network::verify_checksum() {
    local file="${1:?File path required}"
    local expected="${2:?Expected checksum required}"

    if [[ ! -f "${file}" ]]; then
        Logger::error "Network: file not found for checksum: ${file}"
        return 1
    fi

    local actual
    if command -v sha256sum >/dev/null 2>&1; then
        actual="$(sha256sum "${file}" | cut -d' ' -f1)"
    elif command -v shasum >/dev/null 2>&1; then
        actual="$(shasum -a 256 "${file}" | cut -d' ' -f1)"
    else
        Logger::warn "Network: no sha256 tool available, skipping checksum verification"
        return 0
    fi

    if [[ "${actual}" != "${expected}" ]]; then
        Logger::error "Network: checksum mismatch for ${file}"
        Logger::error "  Expected: ${expected}"
        Logger::error "  Actual:   ${actual}"
        return 1
    fi

    Logger::debug "Network: checksum verified: ${file}"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check if a URL is reachable (HEAD request)
# @param $1 {string} URL to check
# @return 0 if reachable, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
Network::is_reachable() {
    local url="${1:?URL required}"

    curl -fsSL \
        --head \
        --connect-timeout 5 \
        --max-time 10 \
        -o /dev/null \
        "${url}" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Check if the system has internet connectivity
# @return 0 if connected, 1 otherwise
# ═══════════════════════════════════════════════════════════════════════════════
Network::is_online() {
    Network::is_reachable "https://github.com" || \
    Network::is_reachable "https://cloudflare.com" || \
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Get the latest release tag from a GitHub repository
# @param $1 {string} Repository in "owner/repo" format
# @return Prints the latest release tag (e.g., "v1.2.3")
# @throws Returns 1 if request fails
# ═══════════════════════════════════════════════════════════════════════════════
Network::github_latest_release() {
    local repo="${1:?Repository required (owner/repo)}"

    local tag
    tag="$(curl -fsSL \
        --connect-timeout "${NETWORK_TIMEOUT}" \
        "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
        | grep '"tag_name"' \
        | head -1 \
        | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"

    if [[ -z "${tag}" ]]; then
        Logger::error "Network: failed to get latest release for: ${repo}"
        return 1
    fi

    echo "${tag}"
}

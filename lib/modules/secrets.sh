#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/modules/secrets.sh
# @description Secret vault management (age/sops encryption, SSH keys, overrides)
# @class SecretVault
# @since 1.0.0
# @version 1.0.0
# @see docs/ARCHITECTURE.md
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────────────────────
# @field VAULT_DIR
# @type string
# @description Path to the local vault directory
# ───────────────────────────────────────────────────────────────────────────────
readonly VAULT_DIR="${DOTFILES_DIR:-${HOME}/.dotfiles}/local"
readonly SECRETS_DIR="${VAULT_DIR}/secrets"
readonly SSH_DIR="${VAULT_DIR}/ssh"

# ═══════════════════════════════════════════════════════════════════════════════
# @description Initialize the vault directory structure with proper permissions
# ═══════════════════════════════════════════════════════════════════════════════
SecretVault::init() {
    Logger::debug "SecretVault: initializing vault structure..."

    local -a private_dirs=(
        "${SECRETS_DIR}"
        "${SSH_DIR}"
        "${SSH_DIR}/keys"
    )

    local -a standard_dirs=(
        "${VAULT_DIR}/shell"
        "${VAULT_DIR}/config"
    )

    local dir
    for dir in "${private_dirs[@]}"; do
        [[ -d "${dir}" ]] || mkdir -p "${dir}"
        chmod 700 "${dir}"
    done

    for dir in "${standard_dirs[@]}"; do
        [[ -d "${dir}" ]] || mkdir -p "${dir}"
    done

    # Ensure .gitkeep exists
    [[ -f "${VAULT_DIR}/.gitkeep" ]] || touch "${VAULT_DIR}/.gitkeep"

    Logger::debug "SecretVault: vault initialized"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Verify all vault permissions are correct
# @return 0 if all correct, 1 if any permission is wrong
# ═══════════════════════════════════════════════════════════════════════════════
SecretVault::verify_permissions() {
    local errors=0

    local -a restricted_dirs=(
        "${SECRETS_DIR}"
        "${SSH_DIR}"
        "${SSH_DIR}/keys"
    )

    local dir
    for dir in "${restricted_dirs[@]}"; do
        if [[ ! -d "${dir}" ]]; then
            continue
        fi

        local actual
        if [[ "$(uname -s)" == "Darwin" ]]; then
            actual="$(stat -f '%A' "${dir}")"
        else
            actual="$(stat -c '%a' "${dir}")"
        fi

        if [[ "${actual}" != "700" ]]; then
            Logger::error "SecretVault: ${dir} has permissions ${actual}, expected 700"
            (( errors++ ))
        fi
    done

    # Check SSH key files
    if [[ -d "${SSH_DIR}/keys" ]]; then
        local key_file
        for key_file in "${SSH_DIR}/keys"/*; do
            [[ -f "${key_file}" ]] || continue
            local key_perms
            if [[ "$(uname -s)" == "Darwin" ]]; then
                key_perms="$(stat -f '%A' "${key_file}")"
            else
                key_perms="$(stat -c '%a' "${key_file}")"
            fi
            if [[ "${key_perms}" != "600" ]] && [[ "${key_perms}" != "644" ]]; then
                if [[ "${key_file}" != *.pub ]]; then
                    Logger::warn "SecretVault: ${key_file} has permissions ${key_perms}, expected 600"
                    (( errors++ ))
                fi
            fi
        done
    fi

    if [[ "${errors}" -eq 0 ]]; then
        Logger::debug "SecretVault: all permissions correct"
    fi

    return "${errors}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Fix vault permissions to secure state
# ═══════════════════════════════════════════════════════════════════════════════
SecretVault::fix_permissions() {
    Logger::info "SecretVault: fixing permissions..."

    chmod 700 "${SECRETS_DIR}" "${SSH_DIR}" "${SSH_DIR}/keys" 2>/dev/null || true

    # Fix private key permissions
    if [[ -d "${SSH_DIR}/keys" ]]; then
        local key_file
        for key_file in "${SSH_DIR}/keys"/*; do
            [[ -f "${key_file}" ]] || continue
            if [[ "${key_file}" == *.pub ]]; then
                chmod 644 "${key_file}"
            else
                chmod 600 "${key_file}"
            fi
        done
    fi

    # Fix age recipients
    if [[ -f "${SECRETS_DIR}/.age-recipients" ]]; then
        chmod 644 "${SECRETS_DIR}/.age-recipients"
    fi

    Logger::success "SecretVault: permissions fixed"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Encrypt a file using age
# @param $1 {string} Path to plaintext file
# @param $2 {string} [optional] Output path (default: input + .age)
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
SecretVault::encrypt() {
    local input="${1:?Input file required}"
    local output="${2:-${input}.age}"

    if ! command -v age >/dev/null 2>&1; then
        Logger::error "SecretVault: 'age' not installed"
        return 1
    fi

    local recipients_file="${SECRETS_DIR}/.age-recipients"
    if [[ ! -f "${recipients_file}" ]]; then
        Logger::error "SecretVault: no recipients file at ${recipients_file}"
        Logger::info "Generate a key: age-keygen -o ${SECRETS_DIR}/key.txt"
        return 1
    fi

    age --encrypt --recipients-file "${recipients_file}" -o "${output}" "${input}"
    Logger::success "SecretVault: encrypted -> ${output}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Decrypt a file using age
# @param $1 {string} Path to encrypted file (.age)
# @param $2 {string} [optional] Output path (default: input without .age)
# @return 0 on success, 1 on failure
# ═══════════════════════════════════════════════════════════════════════════════
SecretVault::decrypt() {
    local input="${1:?Encrypted file required}"
    local output="${2:-${input%.age}}"

    if ! command -v age >/dev/null 2>&1; then
        Logger::error "SecretVault: 'age' not installed"
        return 1
    fi

    local identity="${SECRETS_DIR}/key.txt"
    if [[ ! -f "${identity}" ]]; then
        Logger::error "SecretVault: no identity key at ${identity}"
        return 1
    fi

    age --decrypt --identity "${identity}" -o "${output}" "${input}"
    Logger::success "SecretVault: decrypted -> ${output}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Edit an encrypted file (decrypt, edit, re-encrypt)
# @param $1 {string} Path to encrypted file (.age)
# ═══════════════════════════════════════════════════════════════════════════════
SecretVault::edit() {
    local encrypted="${1:?Encrypted file required}"
    local editor="${EDITOR:-nvim}"

    local tmp_file
    tmp_file="$(mktemp)"
    chmod 600 "${tmp_file}"

    if ! SecretVault::decrypt "${encrypted}" "${tmp_file}"; then
        rm -f "${tmp_file}"
        return 1
    fi

    local checksum_before
    checksum_before="$(shasum -a 256 "${tmp_file}" | cut -d' ' -f1)"

    "${editor}" "${tmp_file}"

    local checksum_after
    checksum_after="$(shasum -a 256 "${tmp_file}" | cut -d' ' -f1)"

    if [[ "${checksum_before}" != "${checksum_after}" ]]; then
        SecretVault::encrypt "${tmp_file}" "${encrypted}"
        Logger::success "SecretVault: changes saved"
    else
        Logger::info "SecretVault: no changes made"
    fi

    rm -f "${tmp_file}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Generate a new age key pair
# @return Creates key.txt in secrets/ and prints public key
# ═══════════════════════════════════════════════════════════════════════════════
SecretVault::generate_key() {
    if ! command -v age-keygen >/dev/null 2>&1; then
        Logger::error "SecretVault: 'age-keygen' not installed"
        return 1
    fi

    local key_file="${SECRETS_DIR}/key.txt"
    if [[ -f "${key_file}" ]]; then
        Logger::warn "SecretVault: key already exists at ${key_file}"
        return 0
    fi

    age-keygen -o "${key_file}" 2>&1
    chmod 600 "${key_file}"

    # Extract public key and write to recipients
    local pub_key
    pub_key="$(grep "public key:" "${key_file}" | sed 's/.*: //')"
    echo "${pub_key}" > "${SECRETS_DIR}/.age-recipients"

    Logger::success "SecretVault: key generated"
    Logger::info "Public key: ${pub_key}"
}

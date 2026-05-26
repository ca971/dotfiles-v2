#!/usr/bin/env bats
# ═══════════════════════════════════════════════════════════════════════════════
# @file tests/unit/test_validator.bats
# @description Unit tests for lib/core/validator.sh
# @since 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

setup() {
    export DOTFILES_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_COLOR=0
    export LOG_LEVEL=4
    source "${DOTFILES_DIR}/lib/core/logger.sh"
    source "${DOTFILES_DIR}/lib/core/validator.sh"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Validator::not_empty
# ═══════════════════════════════════════════════════════════════════════════════

@test "Validator::not_empty passes for non-empty string" {
    Validator::not_empty "hello" "test"
}

@test "Validator::not_empty fails for empty string" {
    ! Validator::not_empty "" "test"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Validator::safe_path
# ═══════════════════════════════════════════════════════════════════════════════

@test "Validator::safe_path accepts normal path" {
    Validator::safe_path "/home/user/.config/tool"
}

@test "Validator::safe_path accepts relative path without traversal" {
    Validator::safe_path "config/tool/settings.toml"
}

@test "Validator::safe_path rejects path with .." {
    ! Validator::safe_path "/home/user/../etc/passwd"
}

@test "Validator::safe_path rejects path with pipe" {
    ! Validator::safe_path "/tmp/file|rm -rf /"
}

@test "Validator::safe_path rejects path with semicolon" {
    ! Validator::safe_path "/tmp/file;rm -rf /"
}

@test "Validator::safe_path rejects path with ampersand" {
    ! Validator::safe_path "/tmp/file&cmd"
}

@test "Validator::safe_path rejects path with command substitution" {
    ! Validator::safe_path '/tmp/$(whoami)'
}

@test "Validator::safe_path rejects path with backticks" {
    ! Validator::safe_path '/tmp/`whoami`'
}

@test "Validator::safe_path rejects leading whitespace" {
    ! Validator::safe_path " /tmp/file"
}

@test "Validator::safe_path rejects trailing whitespace" {
    ! Validator::safe_path "/tmp/file "
}

# ═══════════════════════════════════════════════════════════════════════════════
# Validator::command_exists
# ═══════════════════════════════════════════════════════════════════════════════

@test "Validator::command_exists finds bash" {
    Validator::command_exists "bash"
}

@test "Validator::command_exists fails for nonexistent command" {
    ! Validator::command_exists "definitely_not_a_real_command_xyz"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Validator::file_readable
# ═══════════════════════════════════════════════════════════════════════════════

@test "Validator::file_readable passes for existing file" {
    local tmp
    tmp="$(mktemp)"
    Validator::file_readable "${tmp}"
    rm -f "${tmp}"
}

@test "Validator::file_readable fails for nonexistent file" {
    ! Validator::file_readable "/nonexistent/file/path"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Validator::dir_writable
# ═══════════════════════════════════════════════════════════════════════════════

@test "Validator::dir_writable passes for writable directory" {
    Validator::dir_writable "/tmp"
}

@test "Validator::dir_writable fails for nonexistent directory" {
    ! Validator::dir_writable "/nonexistent/directory"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Validator::version_format
# ═══════════════════════════════════════════════════════════════════════════════

@test "Validator::version_format accepts semver" {
    Validator::version_format "1.2.3"
}

@test "Validator::version_format accepts major.minor" {
    Validator::version_format "1.2"
}

@test "Validator::version_format accepts semver with prerelease" {
    Validator::version_format "1.2.3-beta.1"
}

@test "Validator::version_format accepts 'latest'" {
    Validator::version_format "latest"
}

@test "Validator::version_format accepts 'nightly'" {
    Validator::version_format "nightly"
}

@test "Validator::version_format accepts 'stable'" {
    Validator::version_format "stable"
}

@test "Validator::version_format rejects garbage" {
    ! Validator::version_format "not-a-version"
}

@test "Validator::version_format rejects empty" {
    ! Validator::version_format ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# Validator::url_format
# ═══════════════════════════════════════════════════════════════════════════════

@test "Validator::url_format accepts https URL" {
    Validator::url_format "https://github.com/user/repo"
}

@test "Validator::url_format accepts http URL" {
    Validator::url_format "http://example.com/path"
}

@test "Validator::url_format rejects non-http" {
    ! Validator::url_format "ftp://example.com"
}

@test "Validator::url_format rejects garbage" {
    ! Validator::url_format "not a url"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Validator::one_of
# ═══════════════════════════════════════════════════════════════════════════════

@test "Validator::one_of matches a value in list" {
    Validator::one_of "bash" "bash" "zsh" "fish" "nushell"
}

@test "Validator::one_of fails for value not in list" {
    ! Validator::one_of "tcsh" "bash" "zsh" "fish" "nushell"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Validator::sanitize_filename
# ═══════════════════════════════════════════════════════════════════════════════

@test "Validator::sanitize_filename removes special characters" {
    local result
    result="$(Validator::sanitize_filename 'hello world!@#$%')"
    [[ "${result}" == "helloworld" ]]
}

@test "Validator::sanitize_filename keeps dots and dashes" {
    local result
    result="$(Validator::sanitize_filename "my-file_v1.2.toml")"
    [[ "${result}" == "my-file_v1.2.toml" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Validator::permissions
# ═══════════════════════════════════════════════════════════════════════════════

@test "Validator::permissions detects correct mode" {
    local tmp
    tmp="$(mktemp)"
    chmod 644 "${tmp}"
    Validator::permissions "${tmp}" "644"
    rm -f "${tmp}"
}

@test "Validator::permissions detects wrong mode" {
    local tmp
    tmp="$(mktemp)"
    chmod 644 "${tmp}"
    ! Validator::permissions "${tmp}" "600"
    rm -f "${tmp}"
}

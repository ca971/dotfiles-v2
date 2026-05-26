#!/usr/bin/env bats
# ═══════════════════════════════════════════════════════════════════════════════
# @file tests/unit/test_logger.bats
# @description Unit tests for lib/core/logger.sh
# @since 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

setup() {
    export DOTFILES_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_COLOR=0
    source "${DOTFILES_DIR}/lib/core/logger.sh"
}

teardown() {
    if [[ -n "${_test_log_file:-}" ]] && [[ -f "${_test_log_file}" ]]; then
        rm -f "${_test_log_file}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Logger::set_level
# ═══════════════════════════════════════════════════════════════════════════════

@test "Logger::set_level sets debug level" {
    Logger::set_level "debug"
    [[ "${LOG_LEVEL}" -eq 0 ]]
}

@test "Logger::set_level sets info level" {
    Logger::set_level "info"
    [[ "${LOG_LEVEL}" -eq 1 ]]
}

@test "Logger::set_level sets warn level" {
    Logger::set_level "warn"
    [[ "${LOG_LEVEL}" -eq 2 ]]
}

@test "Logger::set_level sets error level" {
    Logger::set_level "error"
    [[ "${LOG_LEVEL}" -eq 3 ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Log output at various levels
# ═══════════════════════════════════════════════════════════════════════════════

@test "Logger::info outputs INFO label" {
    LOG_LEVEL=1
    local output
    output="$(Logger::info "test message" 2>&1)"
    [[ "${output}" == *"[INFO]"* ]]
    [[ "${output}" == *"test message"* ]]
}

@test "Logger::warn outputs WARN label" {
    LOG_LEVEL=2
    local output
    output="$(Logger::warn "warning here" 2>&1)"
    [[ "${output}" == *"[WARN]"* ]]
    [[ "${output}" == *"warning here"* ]]
}

@test "Logger::error outputs ERROR label" {
    LOG_LEVEL=3
    local output
    output="$(Logger::error "bad thing" 2>&1)"
    [[ "${output}" == *"[ERROR]"* ]]
    [[ "${output}" == *"bad thing"* ]]
}

@test "Logger::success outputs OK label" {
    LOG_LEVEL=1
    local output
    output="$(Logger::success "all good" 2>&1)"
    [[ "${output}" == *"[OK]"* ]]
    [[ "${output}" == *"all good"* ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Log level filtering
# ═══════════════════════════════════════════════════════════════════════════════

@test "Logger::debug is suppressed when level is INFO" {
    LOG_LEVEL=1
    local output
    output="$(Logger::debug "should not appear" 2>&1)"
    [[ -z "${output}" ]]
}

@test "Logger::debug outputs when level is DEBUG" {
    LOG_LEVEL=0
    local output
    output="$(Logger::debug "debug message" 2>&1)"
    [[ "${output}" == *"[DEBUG]"* ]]
}

@test "Logger::info is suppressed when level is WARN" {
    LOG_LEVEL=2
    local output
    output="$(Logger::info "should not appear" 2>&1)"
    [[ -z "${output}" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Logger::step
# ═══════════════════════════════════════════════════════════════════════════════

@test "Logger::step shows step numbers" {
    LOG_LEVEL=1
    local output
    output="$(Logger::step 3 7 "doing stuff" 2>&1)"
    [[ "${output}" == *"[3/7]"* ]]
    [[ "${output}" == *"doing stuff"* ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# File logging
# ═══════════════════════════════════════════════════════════════════════════════

@test "Logger writes to file when LOG_FILE is set" {
    _test_log_file="$(mktemp)"
    LOG_FILE="${_test_log_file}"
    LOG_LEVEL=1

    Logger::info "file log test" 2>/dev/null

    [[ -f "${_test_log_file}" ]]
    grep -q "file log test" "${_test_log_file}"
}

@test "Logger file output has no ANSI codes" {
    _test_log_file="$(mktemp)"
    LOG_FILE="${_test_log_file}"
    LOG_LEVEL=1
    LOG_COLOR=1

    Logger::info "clean output" 2>/dev/null

    ! grep -q $'\033' "${_test_log_file}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Logger::fatal
# ═══════════════════════════════════════════════════════════════════════════════

@test "Logger::fatal exits with code 1" {
    LOG_LEVEL=4
    run bash -c "source '${DOTFILES_DIR}/lib/core/logger.sh' && LOG_COLOR=0 && Logger::fatal 'bye'"
    [[ "${status}" -eq 1 ]]
}

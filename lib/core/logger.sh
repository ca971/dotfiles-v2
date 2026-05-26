#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/core/logger.sh
# @description Structured logging system with levels, colors, and file output
# @class Logger
# @since 1.0.0
# @version 1.0.0
# @see docs/ARCHITECTURE.md
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ───────────────────────────────────────────────────────────────────────────────
# @field LOG_LEVEL
# @type integer
# @description Current log level threshold (0=debug, 1=info, 2=warn, 3=error, 4=fatal)
# ───────────────────────────────────────────────────────────────────────────────
declare -g LOG_LEVEL="${LOG_LEVEL:-1}"

# ───────────────────────────────────────────────────────────────────────────────
# @field LOG_FILE
# @type string
# @description Path to log file (empty = no file logging)
# ───────────────────────────────────────────────────────────────────────────────
declare -g LOG_FILE="${LOG_FILE:-}"

# ───────────────────────────────────────────────────────────────────────────────
# @field LOG_COLOR
# @type boolean (0|1)
# @description Whether to use colored output (auto-detected from terminal)
# ───────────────────────────────────────────────────────────────────────────────
declare -g LOG_COLOR="${LOG_COLOR:-1}"

# ───────────────────────────────────────────────────────────────────────────────
# Log level constants
# ───────────────────────────────────────────────────────────────────────────────
if [[ -z "${LOG_LEVEL_DEBUG:-}" ]]; then
    readonly LOG_LEVEL_DEBUG=0
    readonly LOG_LEVEL_INFO=1
    readonly LOG_LEVEL_WARN=2
    readonly LOG_LEVEL_ERROR=3
    readonly LOG_LEVEL_FATAL=4
fi

# ───────────────────────────────────────────────────────────────────────────────
# ANSI color codes
# ───────────────────────────────────────────────────────────────────────────────
if [[ -z "${_LOG_RESET:-}" ]]; then
    readonly _LOG_RESET="\033[0m"
    readonly _LOG_GRAY="\033[90m"
    readonly _LOG_BLUE="\033[34m"
    readonly _LOG_YELLOW="\033[33m"
    readonly _LOG_RED="\033[31m"
    readonly _LOG_RED_BOLD="\033[1;31m"
    readonly _LOG_GREEN="\033[32m"
    readonly _LOG_CYAN="\033[36m"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# @description Initialize the logger (auto-detect color support)
# @param $1 {integer} [optional] Log level override
# @param $2 {string} [optional] Log file path
# ═══════════════════════════════════════════════════════════════════════════════
Logger::init() {
    if [[ -n "${1:-}" ]]; then
        LOG_LEVEL="${1}"
    fi

    if [[ -n "${2:-}" ]]; then
        LOG_FILE="${2}"
        local log_dir
        log_dir="$(dirname "${LOG_FILE}")"
        [[ -d "${log_dir}" ]] || mkdir -p "${log_dir}"
    fi

    if [[ ! -t 1 ]] || [[ "${NO_COLOR:-}" == "1" ]] || [[ "${TERM:-}" == "dumb" ]]; then
        LOG_COLOR=0
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Internal log formatter and dispatcher
# @param $1 {integer} Level numeric value
# @param $2 {string} Level label
# @param $3 {string} Color code
# @param $4 {string} Message
# ═══════════════════════════════════════════════════════════════════════════════
Logger::_log() {
    local level_num="${1}"
    local level_label="${2}"
    local color="${3}"
    local message="${4}"

    if (( level_num < LOG_LEVEL )); then
        return 0
    fi

    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    local formatted
    if [[ "${LOG_COLOR}" -eq 1 ]]; then
        formatted="${_LOG_GRAY}${timestamp}${_LOG_RESET} ${color}${level_label}${_LOG_RESET} ${message}"
    else
        formatted="${timestamp} ${level_label} ${message}"
    fi

    echo -e "${formatted}" >&2

    if [[ -n "${LOG_FILE}" ]]; then
        echo "${timestamp} ${level_label} ${message}" >> "${LOG_FILE}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Log a debug message
# @param $@ {string} Message parts (concatenated with spaces)
# ═══════════════════════════════════════════════════════════════════════════════
Logger::debug() {
    Logger::_log ${LOG_LEVEL_DEBUG} "[DEBUG]" "${_LOG_GRAY}" "$*"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Log an informational message
# @param $@ {string} Message parts
# ═══════════════════════════════════════════════════════════════════════════════
Logger::info() {
    Logger::_log ${LOG_LEVEL_INFO} "[INFO] " "${_LOG_BLUE}" "$*"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Log a success message (always green, info level)
# @param $@ {string} Message parts
# ═══════════════════════════════════════════════════════════════════════════════
Logger::success() {
    Logger::_log ${LOG_LEVEL_INFO} "[OK]   " "${_LOG_GREEN}" "$*"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Log a warning message
# @param $@ {string} Message parts
# ═══════════════════════════════════════════════════════════════════════════════
Logger::warn() {
    Logger::_log ${LOG_LEVEL_WARN} "[WARN] " "${_LOG_YELLOW}" "$*"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Log an error message
# @param $@ {string} Message parts
# ═══════════════════════════════════════════════════════════════════════════════
Logger::error() {
    Logger::_log ${LOG_LEVEL_ERROR} "[ERROR]" "${_LOG_RED}" "$*"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Log a fatal message and exit with code 1
# @param $@ {string} Message parts
# @throws Exits the process with code 1
# ═══════════════════════════════════════════════════════════════════════════════
Logger::fatal() {
    Logger::_log ${LOG_LEVEL_FATAL} "[FATAL]" "${_LOG_RED_BOLD}" "$*"
    exit 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Log a step in a multi-step process
# @param $1 {integer} Current step number
# @param $2 {integer} Total steps
# @param $3 {string} Step description
# ═══════════════════════════════════════════════════════════════════════════════
Logger::step() {
    local current="${1:?Step number required}"
    local total="${2:?Total steps required}"
    local message="${3:?Step description required}"

    Logger::_log ${LOG_LEVEL_INFO} "[${current}/${total}]" "${_LOG_CYAN}" "${message}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @description Set the log level by name
# @param $1 {string} Level name (debug, info, warn, error, fatal)
# ═══════════════════════════════════════════════════════════════════════════════
Logger::set_level() {
    local level="${1:?Log level required}"

    case "${level}" in
        debug) LOG_LEVEL=${LOG_LEVEL_DEBUG} ;;
        info)  LOG_LEVEL=${LOG_LEVEL_INFO} ;;
        warn)  LOG_LEVEL=${LOG_LEVEL_WARN} ;;
        error) LOG_LEVEL=${LOG_LEVEL_ERROR} ;;
        fatal) LOG_LEVEL=${LOG_LEVEL_FATAL} ;;
        *)     Logger::warn "Unknown log level: ${level}" ;;
    esac
}

# Initialize with defaults on source
Logger::init ""

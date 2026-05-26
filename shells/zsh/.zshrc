#!/usr/bin/env zsh
# ═══════════════════════════════════════════════════════════════════════════════
# @file shells/zsh/.zshrc
# @description Zsh interactive shell configuration
# @since 1.0.0
# @version 1.1.0
# @see docs/ARCHITECTURE.md
#
# Loading order:
#   1. Environment (PATH, exports)
#   2. Zsh options & history
#   3. Generated configs (from SSOT definitions)
#   4. Plugins (zinit turbo mode)
#   5. Completions
#   6. Tool integrations — eager (mise, direnv, starship, keychain)
#   7. Tool integrations — lazy (deferred until first use)
#   8. Local overrides
#
# Performance target: <50ms interactive startup
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
# Startup timing (set DOTFILES_BENCH=1 to measure)
# ───────────────────────────────────────────────────────────────────────────────
if [[ "${DOTFILES_BENCH:-0}" == "1" ]]; then
    zmodload zsh/datetime
    _zsh_start_time=${EPOCHREALTIME}
fi

# ───────────────────────────────────────────────────────────────────────────────
# Core variables
# ───────────────────────────────────────────────────────────────────────────────
export DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/.dotfiles}"
readonly ZSH_GEN_DIR="${DOTFILES_DIR}/shells/zsh/generated"
readonly ZSH_PLUGIN_DIR="${DOTFILES_DIR}/shells/zsh/plugins"

# ───────────────────────────────────────────────────────────────────────────────
# Zsh options
# ───────────────────────────────────────────────────────────────────────────────

# Navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt CDABLE_VARS

# Globbing
setopt EXTENDED_GLOB
setopt GLOB_DOTS
setopt NO_CASE_GLOB
setopt NUMERIC_GLOB_SORT

# Correction
setopt CORRECT
setopt CORRECT_ALL

# History
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# Completion
setopt ALWAYS_TO_END
setopt AUTO_LIST
setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt MENU_COMPLETE

# Misc
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt NO_FLOW_CONTROL

# ───────────────────────────────────────────────────────────────────────────────
# History
# ───────────────────────────────────────────────────────────────────────────────
export HISTFILE="${XDG_STATE_HOME:-${HOME}/.local/state}/zsh/history"
export HISTSIZE=50000
export SAVEHIST=100000
[[ -d "${HISTFILE:h}" ]] || command mkdir -p "${HISTFILE:h}" >/dev/null 2>&1

# ───────────────────────────────────────────────────────────────────────────────
# Source generated configs (SSOT → zsh)
# ORDER MATTERS: env/path first, then plugins (zinit), then init (tool hooks)
# ───────────────────────────────────────────────────────────────────────────────
_zsh_source_if_exists() { [[ -f "$1" ]] && source "$1"; }
# Note: zsh natively loads .zwc if present and newer — no extra logic needed

_zsh_source_if_exists "${ZSH_GEN_DIR}/env.gen.sh"
_zsh_source_if_exists "${ZSH_GEN_DIR}/path.gen.sh"
_zsh_source_if_exists "${ZSH_GEN_DIR}/aliases.gen.sh"
_zsh_source_if_exists "${ZSH_GEN_DIR}/functions.gen.sh"
_zsh_source_if_exists "${ZSH_GEN_DIR}/keybindings.gen.sh"
_zsh_source_if_exists "${ZSH_GEN_DIR}/plugins.gen.sh"
_zsh_source_if_exists "${ZSH_GEN_DIR}/init.gen.sh"

# ───────────────────────────────────────────────────────────────────────────────
# Completion system
# ───────────────────────────────────────────────────────────────────────────────
autoload -Uz compinit

# Ensure cache dir exists
[[ -d "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh" ]] || command mkdir -p "${XDG_CACHE_HOME:-${HOME}/.cache}/zsh" >/dev/null 2>&1

# Only regenerate .zcompdump once per day
local _zcompdump="${XDG_CACHE_HOME:-${HOME}/.cache}/zsh/zcompdump"
if [[ -n "${_zcompdump}"(#qN.mh+24) ]]; then
    compinit -d "${_zcompdump}"
else
    compinit -C -d "${_zcompdump}"
fi

# Completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME}/zsh/zcompcache"
zstyle ':completion:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' squeeze-slashes true

# Custom completions directory
if [[ -d "${DOTFILES_DIR}/shells/zsh/completions" ]]; then
    fpath=("${DOTFILES_DIR}/shells/zsh/completions" $fpath)
fi

# ───────────────────────────────────────────────────────────────────────────────
# Vi mode (emacs keybindings by default, toggle with ESC)
# ───────────────────────────────────────────────────────────────────────────────
bindkey -e

# ───────────────────────────────────────────────────────────────────────────────
# Zcompile — compile generated files for faster loading (runs async)
# ───────────────────────────────────────────────────────────────────────────────
{
    local f
    for f in "${ZSH_GEN_DIR}"/*.gen.sh(N); do
        if [[ ! -f "${f}.zwc" ]] || [[ "${f}" -nt "${f}.zwc" ]]; then
            zcompile "${f}" 2>/dev/null
        fi
    done
    [[ -f "${_zcompdump}" ]] && [[ ! -f "${_zcompdump}.zwc" || "${_zcompdump}" -nt "${_zcompdump}.zwc" ]] && zcompile "${_zcompdump}" 2>/dev/null
} &!

# ───────────────────────────────────────────────────────────────────────────────
# Local overrides (machine-specific, gitignored)
# ───────────────────────────────────────────────────────────────────────────────
if [[ -f "${DOTFILES_DIR}/local/shell/zsh.local" ]]; then
    source "${DOTFILES_DIR}/local/shell/zsh.local"
fi

# ───────────────────────────────────────────────────────────────────────────────
# Startup timing report
# ───────────────────────────────────────────────────────────────────────────────
if [[ "${DOTFILES_BENCH:-0}" == "1" ]]; then
    local _zsh_end_time=${EPOCHREALTIME}
    local _zsh_elapsed=$(( (_zsh_end_time - _zsh_start_time) * 1000 ))
    printf "\033[90m[zsh startup: %.1fms]\033[0m\n" "${_zsh_elapsed}"
    unset _zsh_start_time _zsh_end_time _zsh_elapsed
fi

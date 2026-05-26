#!/usr/bin/env zsh
# ═══════════════════════════════════════════════════════════════════════════════
# @file shells/zsh/.zshenv
# @description Zsh environment (sourced for ALL zsh instances, login or not)
# @since 1.0.0
# @version 1.0.0
# @see shells/zsh/.zshrc
#
# Keep this minimal — only environment variables that must be set universally.
# Interactive configuration belongs in .zshrc.
# ═══════════════════════════════════════════════════════════════════════════════

export DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/.dotfiles}"

# XDG Base Directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-${HOME}/.local/bin}"

# Zsh config directory (keep ~ clean)
export ZDOTDIR="${ZDOTDIR:-${DOTFILES_DIR}/shells/zsh}"

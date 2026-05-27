# ═══════════════════════════════════════════════════════════════════════════════
# @file shells/bash/completions/dotfiles.bash
# @description Bash completion for dotfiles, dotfiles-gen, dotfiles-theme
# @since 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

# ── dotfiles ──
_dotfiles_completion() {
    local cur prev words cword
    _init_completion || return

    if [[ "${cword}" -eq 1 ]]; then
# shellcheck disable=SC2207
# shellcheck disable=SC2207
        COMPREPLY=($(compgen -W "install uninstall status verify setup sync update upgrade generate doctor bench vault-init vault-keygen vault-encrypt vault-decrypt snapshot" -- "${cur}"))
        return
    fi

    case "${words[1]}" in
        install|uninstall)
            local tools_dir="${DOTFILES_DIR:-${HOME}/.dotfiles}/tools/available"
            if [[ -d "${tools_dir}" ]]; then
                local tools
                tools=$(cd "${tools_dir}" && ls *.toml 2>/dev/null | sed 's/\.toml//')
                # shellcheck disable=SC2207
# shellcheck disable=SC2207
                COMPREPLY=($(compgen -W "${tools}" -- "${cur}"))
            fi
            ;;
        snapshot)
            # shellcheck disable=SC2207
# shellcheck disable=SC2207
            COMPREPLY=($(compgen -W "create list rollback" -- "${cur}"))
            ;;
        sync)
            # shellcheck disable=SC2207
# shellcheck disable=SC2207
            COMPREPLY=($(compgen -W "--dry-run --force" -- "${cur}"))
            ;;
    esac
}
complete -F _dotfiles_completion dotfiles

# ── dotfiles-theme ──
_dotfiles_theme_completion() {
    local cur
    _init_completion || return
# shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "minimal full powerline --list --help" -- "${cur}"))
}
complete -F _dotfiles_theme_completion dotfiles-theme

# ── dotfiles-gen ──
_dotfiles_gen_completion() {
    local cur prev
    _init_completion || return

    if [[ "${cword}" -eq 1 ]]; then
# shellcheck disable=SC2207
        COMPREPLY=($(compgen -W "generate validate" -- "${cur}"))
        return
    fi

    case "${prev}" in
        --shell)
# shellcheck disable=SC2207
            COMPREPLY=($(compgen -W "bash zsh fish nushell" -- "${cur}"))
            ;;
        generate)
# shellcheck disable=SC2207
            COMPREPLY=($(compgen -W "--all --shell" -- "${cur}"))
            ;;
    esac
}
complete -F _dotfiles_gen_completion dotfiles-gen

# ═══════════════════════════════════════════════════════════════════════════════
# @file shells/bash/completions/dotfiles.bash
# @description Bash completion for dotfiles, dotfiles-gen, dotfiles-theme,
#              dotfiles-ai, dotfiles-nix
# @since 1.0.0
# @version 1.1.0
# ═══════════════════════════════════════════════════════════════════════════════

# ── dotfiles ──
_dotfiles_completion() {
    local cur words cword
    _init_completion || return

    if [[ "${cword}" -eq 1 ]]; then
        # shellcheck disable=SC2207
        COMPREPLY=($(compgen -W "install uninstall status verify setup sync update upgrade generate doctor bench snapshot vault-init vault-keygen vault-encrypt vault-decrypt" -- "${cur}"))
        return
    fi

    case "${words[1]}" in
        install|uninstall)
            local tools_dir="${DOTFILES_DIR:-${HOME}/.dotfiles}/tools/available"
            if [[ -d "${tools_dir}" ]]; then
                # shellcheck disable=SC2207
                COMPREPLY=($(compgen -W "$(cd "${tools_dir}" && ls *.toml 2>/dev/null | sed 's/\.toml//')" -- "${cur}"))
            fi
            ;;
        snapshot)
            # shellcheck disable=SC2207
            COMPREPLY=($(compgen -W "create list rollback" -- "${cur}"))
            ;;
        sync)
            # shellcheck disable=SC2207
            COMPREPLY=($(compgen -W "--dry-run --force" -- "${cur}"))
            ;;
    esac
}
complete -F _dotfiles_completion dotfiles

# ── dotfiles-theme ──
complete -W "minimal full powerline --list --help" dotfiles-theme

# ── dotfiles-gen ──
_dotfiles_gen_completion() {
    local cur prev
    _init_completion || return

    if [[ "${cword}" -eq 1 ]]; then
        # shellcheck disable=SC2207
        COMPREPLY=($(compgen -W "generate validate skills" -- "${cur}"))
        return
    fi

    case "${words[1]}" in
        generate)
            case "${prev}" in
                --shell)
                    # shellcheck disable=SC2207
                    COMPREPLY=($(compgen -W "bash zsh fish nushell" -- "${cur}"))
                    ;;
                *)
                    # shellcheck disable=SC2207
                    COMPREPLY=($(compgen -W "--all --shell" -- "${cur}"))
                    ;;
            esac
            ;;
        skills)
            case "${prev}" in
                --agent)
                    # shellcheck disable=SC2207
                    COMPREPLY=($(compgen -W "hermes claude codex opencode" -- "${cur}"))
                    ;;
                *)
                    # shellcheck disable=SC2207
                    COMPREPLY=($(compgen -W "--all --agent" -- "${cur}"))
                    ;;
            esac
            ;;
    esac
}
complete -F _dotfiles_gen_completion dotfiles-gen

# ── dotfiles-ai ──
_dotfiles_ai_completion() {
    local cur words cword
    _init_completion || return

    if [[ "${cword}" -eq 1 ]]; then
        # shellcheck disable=SC2207
        COMPREPLY=($(compgen -W "link unlink status" -- "${cur}"))
        return
    fi

    case "${words[1]}" in
        link|unlink)
            # shellcheck disable=SC2207
            COMPREPLY=($(compgen -W "hermes claude codex opencode" -- "${cur}"))
            ;;
    esac
}
complete -F _dotfiles_ai_completion dotfiles-ai

# ── dotfiles-nix ──
_dotfiles_nix_completion() {
    local cur words cword
    _init_completion || return

    if [[ "${cword}" -eq 1 ]]; then
        # shellcheck disable=SC2207
        COMPREPLY=($(compgen -W "list enter enable disable create update" -- "${cur}"))
        return
    fi

    case "${words[1]}" in
        enter|enable|disable|update)
            local envs_dir="${DOTFILES_DIR:-${HOME}/.dotfiles}/tools/nix/envs"
            if [[ -d "${envs_dir}" ]]; then
                # shellcheck disable=SC2207
                COMPREPLY=($(compgen -W "$(for d in "${envs_dir}"/*; do [[ -d "$d" ]] && [[ "$(basename "$d")" != "_template" ]] && basename "$d"; done)" -- "${cur}"))
            else
                # shellcheck disable=SC2207
                COMPREPLY=($(compgen -W "default devops go node python rust data security elixir zig ruby" -- "${cur}"))
            fi
            ;;
    esac
}
complete -F _dotfiles_nix_completion dotfiles-nix

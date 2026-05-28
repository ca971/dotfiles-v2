"""
@file generators/src/emitters/zsh.py
@description Zsh-specific code emitter
@class ZshEmitter
@extends ShellEmitter
@since 1.0.0
@version 1.0.0
"""

from __future__ import annotations

from ..models import (
    AliasDefinitions,
    EnvDefinitions,
    FunctionDefinitions,
    KeybindingDefinitions,
    PathDefinitions,
)
from .base import ShellEmitter


class ZshEmitter(ShellEmitter):
    """
    @class ZshEmitter
    @extends ShellEmitter
    @description Generates Zsh-compatible shell code from SSOT definitions
    @since 1.0.0
    """

    @property
    def shell_name(self) -> str:
        return "zsh"

    def emit_aliases(self, definitions: AliasDefinitions) -> str:
        lines: list[str] = []
        for group_name, aliases in definitions.aliases.items():
            lines.append(f"\n# --- {group_name} ---")
            for name, alias in aliases.items():
                escaped_cmd = alias.command.replace("'", "'\\''")
                prefix = "alias -- " if name.startswith("-") else "alias "
                lines.append(f"{prefix}{name}='{escaped_cmd}'")
        return "\n".join(lines) + "\n"

    def emit_functions(self, definitions: FunctionDefinitions) -> str:
        lines: list[str] = []
        for name, func in definitions.functions.items():
            lines.append(f"\n# {func.description}")
            lines.append(f"{name}() {{")
            for body_line in func.body.strip().splitlines():
                lines.append(f"    {body_line}")
            lines.append("}")
        return "\n".join(lines) + "\n"

    def emit_env(self, definitions: EnvDefinitions) -> str:
        lines: list[str] = []
        for group_name, env_vars in definitions.env.items():
            lines.append(f"\n# --- {group_name} ---")
            for name, var in env_vars.items():
                if var.condition:
                    lines.append(f"if {var.condition} >/dev/null 2>&1; then")
                    lines.append(f'    export {name}="{var.value}"')
                    lines.append("fi")
                else:
                    lines.append(f'export {name}="{var.value}"')
        return "\n".join(lines) + "\n"

    def emit_path(self, definitions: PathDefinitions) -> str:
        lines: list[str] = ["\n# --- PATH construction ---"]
        lines.append("typeset -U path")
        for entry in definitions.path:
            path_val = entry.path
            if entry.condition:
                lines.append(f'[[ -d "{entry.condition}" ]] && path=("{path_val}" $path)')
            else:
                if entry.prepend:
                    lines.append(f'path=("{path_val}" $path)')
                else:
                    lines.append(f'path+=("{path_val}")')
        lines.append("export PATH")
        return "\n".join(lines) + "\n"

    def emit_keybindings(self, definitions: KeybindingDefinitions) -> str:
        key_map = {
            "ctrl-a": "^A",
            "ctrl-b": "^B",
            "ctrl-e": "^E",
            "ctrl-f": "^F",
            "ctrl-g": "^G",
            "ctrl-k": "^K",
            "ctrl-n": "^N",
            "ctrl-r": "^R",
            "ctrl-t": "^T",
            "ctrl-u": "^U",
            "ctrl-w": "^W",
            "ctrl-space": "^ ",
            "alt-b": "^[b",
            "alt-c": "^[c",
            "alt-d": "^[d",
            "alt-f": "^[f",
        }

        zle_widgets = {
            "beginning-of-line",
            "end-of-line",
            "backward-kill-word",
            "kill-word",
            "kill-whole-line",
            "kill-line",
            "backward-word",
            "forward-word",
            "expand-or-complete",
            "history-incremental-search-backward",
            "autosuggest-accept",
        }

        widget_map = {
            "beginning-of-line": "beginning-of-line",
            "end-of-line": "end-of-line",
            "backward-kill-word": "backward-kill-word",
            "kill-word": "kill-word",
            "kill-whole-line": "kill-whole-line",
            "kill-line": "kill-line",
            "backward-word": "backward-word",
            "forward-word": "forward-word",
            "accept-autosuggestion": "autosuggest-accept",
            "expand-or-complete": "expand-or-complete",
            "history-search": "history-incremental-search-backward",
        }

        lines: list[str] = ["\n# --- Keybindings (ZLE) ---"]
        custom_widgets: list[str] = []

        for _group_name, bindings in definitions.keybindings.items():
            for _name, kb in bindings.items():
                zsh_key = key_map.get(kb.key, kb.key)
                widget = widget_map.get(kb.action, kb.action)

                if widget in zle_widgets:
                    lines.append(f"bindkey '{zsh_key}' {widget}")
                else:
                    widget_name = f"_dotfiles-{kb.action.replace(' ', '-')}"
                    custom_widgets.append(
                        f"{widget_name}() {{ BUFFER='{kb.action}'; zle accept-line; }}"
                    )
                    custom_widgets.append(f"zle -N {widget_name}")
                    lines.append(f"bindkey '{zsh_key}' {widget_name}")

        if custom_widgets:
            header = lines[0]
            bindings = lines[1:]
            lines = [header, "", "# Custom ZLE widgets for command execution"]
            lines.extend(custom_widgets)
            lines.append("")
            lines.extend(bindings)

        return "\n".join(lines) + "\n"

    def emit_plugins(self, definitions: object) -> str:
        """
        @description Generate zinit plugin loading code for Zsh
        @param definitions Parsed plugin definitions (PluginDefinitions)
        @return Generated zinit load commands, grouped by loading strategy
        """
        load_order = [
            "immediate",
            "turbo_0a",
            "turbo_0b",
            "turbo_0c",
            "turbo_1a",
            "turbo_1b",
            "turbo_2a",
        ]
        wait_map = {
            "immediate": None,
            "turbo_0a": "0a",
            "turbo_0b": "0b",
            "turbo_0c": "0c",
            "turbo_1a": "1",
            "turbo_1b": "1b",
            "turbo_2a": "2",
        }

        grouped: dict[str, list[tuple[str, object]]] = {k: [] for k in load_order}
        for name, plugin in definitions.plugins.items():
            if plugin.load in grouped:
                grouped[plugin.load].append((name, plugin))

        lines: list[str] = []
        lines.append("\n# Zinit initialization")
        lines.append("declare -A ZINIT")
        lines.append('ZINIT[HOME_DIR]="${XDG_DATA_HOME}/zinit"')
        lines.append('ZINIT[BIN_DIR]="${ZINIT[HOME_DIR]}/zinit.git"')
        lines.append('ZINIT[PLUGINS_DIR]="${ZINIT[HOME_DIR]}/plugins"')
        lines.append('ZINIT[SNIPPETS_DIR]="${ZINIT[HOME_DIR]}/snippets"')
        lines.append('ZINIT[COMPLETIONS_DIR]="${ZINIT[HOME_DIR]}/completions"')
        lines.append("")
        lines.append("# Auto-install zinit if missing")
        lines.append('if [[ ! -f "${ZINIT[BIN_DIR]}/zinit.zsh" ]]; then')
        lines.append('    command mkdir -p "${ZINIT[HOME_DIR]}"')
        lines.append(
            "    command git clone https://github.com/zdharma-continuum/zinit.git"
            ' "${ZINIT[BIN_DIR]}"'
        )
        lines.append("fi")
        lines.append("")
        lines.append("ZINIT[MUTE_WARNINGS]=1")
        lines.append('source "${ZINIT[BIN_DIR]}/zinit.zsh"')
        lines.append("autoload -Uz _zinit")
        lines.append("(( ${+_comps} )) && _comps[zinit]=_zinit")
        lines.append("")
        lines.append("# Patch scheduler to suppress subscript range error on first run")
        lines.append("if (( ${+functions[@zinit-scheduler]} )); then")
        lines.append('    functions[-zinit-scheduler-orig]="${functions[@zinit-scheduler]}"')
        lines.append('    @zinit-scheduler() { @zinit-scheduler-orig "$@" 2>/dev/null; }')
        lines.append("fi")

        for load_strategy in load_order:
            plugins_in_group = grouped[load_strategy]
            if not plugins_in_group:
                continue

            wait = wait_map[load_strategy]
            lines.append(f"\n# --- {load_strategy} ---")

            for _name, plugin in plugins_in_group:
                lines.append(f"\n# {plugin.description}")
                ice_parts = self._build_ice(plugin, wait)

                if plugin.from_source == "snippet":
                    lines.append(f"zinit ice {ice_parts}")
                    lines.append(f"zinit snippet {plugin.repo}")
                else:
                    lines.append(f"zinit ice {ice_parts}")
                    lines.append(f"zinit light {plugin.repo}")

        return "\n".join(lines) + "\n"

    @staticmethod
    def _build_ice(plugin: object, wait: str | None) -> str:
        """
        @description Build zinit ice modifier string from plugin definition
        @param plugin Plugin object with ice dict
        @param wait Turbo wait value (None = immediate)
        @return Formatted ice string
        """
        parts: list[str] = []

        if wait is not None:
            parts.append(f'wait"{wait}"')

        for key, value in plugin.ice.items():
            if isinstance(value, bool) and value:
                parts.append(key)
            elif isinstance(value, str) and value:
                parts.append(f'{key}"{value}"')

        if plugin.pick:
            parts.append(f'pick"{plugin.pick}"')

        if plugin.depends_on:
            parts.append(f'wait"{wait}" depends-on"{plugin.depends_on}"')

        return " ".join(parts)

    def _wrap_init_check(self, verify_cmd: str, init_cmd: str) -> str:
        """@description Zsh-specific availability check using $+commands hash."""
        return f"if (( $+commands[{verify_cmd}] )); then\n    {init_cmd}\nfi"

    def _wrap_lazy_init(
        self, verify_cmd: str, init_cmd: str, name: str, triggers: list[str]
    ) -> str:
        """@description Zsh lazy-loading using function wrappers with $+commands check."""
        func_name = f"_dotfiles_lazy_{name}"
        unset_list = " ".join(triggers)
        trigger_list_quoted = " ".join(f"'{t}'" for t in triggers)
        lines = [
            f"if (( $+commands[{verify_cmd}] )); then",
            f"    {func_name}() {{ unfunction {unset_list} {func_name} 2>/dev/null; {init_cmd}; }}",
            f"    for _t in {trigger_list_quoted}; do",
            '        (( $+aliases[$_t] )) && unalias "$_t"',
            f'        eval "$_t() {{ {func_name}; $_t \\"\\$@\\"; }}"',
            "    done",
            "    unset _t",
        ]
        lines.append("fi")
        return "\n".join(lines)

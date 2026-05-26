"""
@file generators/src/emitters/bash.py
@description Bash-specific code emitter
@class BashEmitter
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


class BashEmitter(ShellEmitter):
    """
    @class BashEmitter
    @extends ShellEmitter
    @description Generates Bash-compatible shell code from SSOT definitions
    @since 1.0.0
    """

    @property
    def shell_name(self) -> str:
        return "bash"

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
                    lines.append(f'if {var.condition} >/dev/null 2>&1; then')
                    lines.append(f'    export {name}="{var.value}"')
                    lines.append("fi")
                else:
                    lines.append(f'export {name}="{var.value}"')
        return "\n".join(lines) + "\n"

    def emit_path(self, definitions: PathDefinitions) -> str:
        lines: list[str] = ["\n# --- PATH construction ---"]
        for entry in definitions.path:
            path_val = entry.path
            if entry.condition:
                lines.append(f'if [[ -d "{entry.condition}" ]]; then')
                if entry.prepend:
                    lines.append(f'    export PATH="{path_val}:$PATH"')
                else:
                    lines.append(f'    export PATH="$PATH:{path_val}"')
                lines.append("fi")
            else:
                if entry.prepend:
                    lines.append(f'export PATH="{path_val}:$PATH"')
                else:
                    lines.append(f'export PATH="$PATH:{path_val}"')
        return "\n".join(lines) + "\n"

    def emit_keybindings(self, definitions: KeybindingDefinitions) -> str:
        key_map = {
            "ctrl-a": r"\C-a",
            "ctrl-b": r"\C-b",
            "ctrl-c": r"\C-c",
            "ctrl-d": r"\C-d",
            "ctrl-e": r"\C-e",
            "ctrl-f": r"\C-f",
            "ctrl-g": r"\C-g",
            "ctrl-k": r"\C-k",
            "ctrl-n": r"\C-n",
            "ctrl-r": r"\C-r",
            "ctrl-t": r"\C-t",
            "ctrl-u": r"\C-u",
            "ctrl-w": r"\C-w",
            "ctrl-space": r"\C-@",
            "alt-b": r"\eb",
            "alt-c": r"\ec",
            "alt-d": r"\ed",
            "alt-f": r"\ef",
        }

        lines: list[str] = ["\n# --- Keybindings (readline) ---"]
        for _group_name, bindings in definitions.keybindings.items():
            for _name, kb in bindings.items():
                readline_key = key_map.get(kb.key, kb.key)
                lines.append(f'bind \'"\\{readline_key}": "{kb.action}"\'')
        return "\n".join(lines) + "\n"

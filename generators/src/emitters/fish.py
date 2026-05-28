""" "
@file generators/src/emitters/fish.py
@description Fish-specific code emitter
@class FishEmitter
@extends ShellEmitter
@since 1.0.0
@version 1.1.0
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


class FishEmitter(ShellEmitter):
    """
    @class FishEmitter
    @extends ShellEmitter
    @description Generates Fish-compatible shell code from SSOT definitions
    @since 1.0.0
    """

    @property
    def shell_name(self) -> str:
        return "fish"

    def emit_aliases(self, definitions: AliasDefinitions) -> str:
        lines: list[str] = []
        for group_name, aliases in definitions.aliases.items():
            lines.append(f"\n# --- {group_name} ---")
            for name, alias in aliases.items():
                if alias.requires:
                    lines.append(f"if command -q {alias.requires}")
                    indent = "    "
                else:
                    indent = ""
                lines.append(f"{indent}abbr -a {name} '{alias.command}'")
                if alias.requires:
                    lines.append("end")
        return "\n".join(lines) + "\n"

    def emit_functions(self, definitions: FunctionDefinitions) -> str:
        lines: list[str] = []
        for name, func in definitions.functions.items():
            lines.append(f"\n# {func.description}")
            lines.append(f"function {name}")
            body = func.body.strip()
            fish_body = self._posix_to_fish(body)
            for body_line in fish_body.splitlines():
                lines.append(f"    {body_line}")
            lines.append("end")
        return "\n".join(lines) + "\n"

    def emit_env(self, definitions: EnvDefinitions) -> str:
        lines: list[str] = []
        for group_name, env_vars in definitions.env.items():
            lines.append(f"\n# --- {group_name} ---")
            for name, var in env_vars.items():
                value = var.value.replace("$HOME", "$HOME").replace("$", "$")
                if var.condition:
                    lines.append(f"if command -sq {var.condition.split()[-1]}")
                    lines.append(f'    set -gx {name} "{value}"')
                    lines.append("end")
                else:
                    lines.append(f'set -gx {name} "{value}"')
        return "\n".join(lines) + "\n"

    def emit_path(self, definitions: PathDefinitions) -> str:
        lines: list[str] = ["\n# --- PATH construction ---"]
        for entry in definitions.path:
            path_val = entry.path
            if entry.condition:
                lines.append(f'if test -d "{entry.condition}"')
                if entry.prepend:
                    lines.append(f'    fish_add_path --prepend "{path_val}"')
                else:
                    lines.append(f'    fish_add_path --append "{path_val}"')
                lines.append("end")
            else:
                if entry.prepend:
                    lines.append(f'fish_add_path --prepend "{path_val}"')
                else:
                    lines.append(f'fish_add_path --append "{path_val}"')
        return "\n".join(lines) + "\n"

    def emit_keybindings(self, definitions: KeybindingDefinitions) -> str:
        key_map = {
            "ctrl-a": "ctrl-a",
            "ctrl-e": "ctrl-e",
            "ctrl-f": "ctrl-f",
            "ctrl-g": "ctrl-g",
            "ctrl-k": "ctrl-k",
            "ctrl-n": "ctrl-n",
            "ctrl-r": "ctrl-r",
            "ctrl-t": "ctrl-t",
            "ctrl-u": "ctrl-u",
            "ctrl-w": "ctrl-w",
            "ctrl-space": "ctrl-space",
            "alt-b": "alt-b",
            "alt-c": "alt-c",
            "alt-d": "alt-d",
            "alt-f": "alt-f",
        }

        lines: list[str] = ["\n# --- Keybindings ---"]
        for _group_name, bindings in definitions.keybindings.items():
            for _name, kb in bindings.items():
                fish_key = key_map.get(kb.key, kb.key)
                lines.append(f"bind {fish_key} '{kb.action}'")
        return "\n".join(lines) + "\n"

    def _wrap_init_check(self, verify_cmd: str, init_cmd: str) -> str:
        """@description Fish-specific availability check wrapper."""
        return f"if command -sq {verify_cmd}\n    {init_cmd}\nend"

    def _wrap_lazy_init(
        self, verify_cmd: str, init_cmd: str, name: str, triggers: list[str]
    ) -> str:
        """@description Fish-specific lazy-loading wrapper."""
        func_name = f"_dotfiles_lazy_{name}"
        trigger_list = " ".join(triggers)
        lines = [
            f"if command -sq {verify_cmd}",
            f"    function {func_name}",
            f"        functions -e {trigger_list} {func_name} 2>/dev/null",
            f"        {init_cmd}",
            "    end",
        ]
        for trigger in triggers:
            lines.append(f"    function {trigger} --wraps {trigger}")
            lines.append(f"        {func_name}; {trigger} $argv")
            lines.append("    end")
        lines.append("end")
        return "\n".join(lines)

    @staticmethod
    def _posix_to_fish(body: str) -> str:
        """
        @description POSIX → Fish syntax conversion
        @param body POSIX shell function body
        @return Fish-compatible function body
        """
        import re

        result = body

        # Variable substitutions: ${N:-default} → fish default
        result = re.sub(
            r"\$\{(\d+):-([^}]*)\}",
            r"(set -q argv[\1]; and echo $argv[\1]; or echo \2)",
            result,
        )
        result = result.replace("$@", "$argv")
        result = result.replace("$2", "$argv[2]")
        result = result.replace("$1", "$argv[1]")
        # Bash-style ${var} → fish $var (but not ${N:-...} already handled)
        result = re.sub(r"\$\{(\w+)\}", r"$\1", result)
        result = re.sub(r"\bexport\s+", "set -gx ", result)
        result = re.sub(r"\blocal\b", "set -l", result)

        # Conditionals: [[ ... ]]; then → if test ...
        # Handle both standalone [[ and if [[ patterns
        result = re.sub(r"\[\[\s*(.+?)\s*\]\]\s*;\s*then", r"if test \1", result)
        result = re.sub(r"\[\[\s*(.+?)\s*\]\]\s*&&\s*then", r"if test \1", result)
        result = re.sub(
            r"\[\[\s*!\s+-\s*(.+?)\s+(\S+)\s*\]\]",
            r"not test -\1 \2",
            result,
        )
        result = re.sub(
            r"\[\[\s*-\s*(.+?)\s+(\S+)\s*\]\]",
            r"test -\1 \2",
            result,
        )
        # Fix double if: 'if if test' → 'if test'
        result = result.replace("if if test", "if test")

        # Keywords (order matters)
        result = re.sub(r"\belif\b", "__ELIF_PROTECT__", result)
        result = re.sub(r"\bfi\b", "end", result)
        result = re.sub(r"__ELIF_PROTECT__", "else if", result)
        result = re.sub(r"\bdone\b", "end", result)
        result = re.sub(r"\besac\b", "end", result)

        # case → switch (handles lines like "  pattern) command ;;")
        result = re.sub(r"\bcase\s+(\S+)\s+in\b", r"switch \1", result)
        result = re.sub(
            r"^(\s+)(\S+)\)\s+(.+);;$",
            r"\1case \2\n\1    \3",
            result,
            flags=re.MULTILINE,
        )
        result = re.sub(
            r"^(\s+)\*\)\s+(.+);;$",
            r"\1case '*'\n\1    \2",
            result,
            flags=re.MULTILINE,
        )
        # Remove stray ;; if any remain
        result = re.sub(r";;$", "", result, flags=re.MULTILINE)

        # for loops
        result = re.sub(
            r"for\s+\(\(\s*(\w+)\s*=\s*(\d+)\s*;\s*\1\s*<\s*(\w+)\s*;\s*\1\+\+\s*\)\)",
            r"for \1 in (seq \2 (math \3 - 1))",
            result,
        )
        result = re.sub(r"\bfor\s+(\S+)\s+in\b", r"for \1 in", result)
        result = re.sub(r"\bdo\b", "", result)

        # Final cleanup: bare variable assignments → set var value
        # Runs AFTER do removal so we catch assignments after ; or newline
        result = re.sub(
            r"(;|\n)\s*(\w+)=(\"[^\"]*\"|'[^']*'|\S+)",
            r"\1set \2 \3",
            result,
        )

        return result

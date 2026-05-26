"""
@file generators/src/parser.py
@description TOML parser and validator for SSOT definitions
@since 1.0.0
@version 1.0.0
@see docs/SSOT.md
"""

from __future__ import annotations

import tomllib
from pathlib import Path
from typing import Any

from .models import (
    Alias,
    AliasDefinitions,
    EnvDefinitions,
    EnvVar,
    Function,
    FunctionDefinitions,
    HighlightDefinitions,
    HighlightStyle,
    InitDefinitions,
    InitEntry,
    Keybinding,
    KeybindingDefinitions,
    PathDefinitions,
    PathEntry,
    Plugin,
    PluginDefinitions,
)


class DefinitionParser:
    """
    @class DefinitionParser
    @description Parses TOML definition files into validated Pydantic models
    @since 1.0.0
    """

    def __init__(self, definitions_dir: Path) -> None:
        """
        @param definitions_dir Path to the definitions/ directory
        """
        self.definitions_dir = definitions_dir

    def _read_toml(self, filename: str) -> dict[str, Any]:
        """
        @description Read and parse a TOML file
        @param filename Name of the TOML file (relative to definitions_dir)
        @return Parsed TOML as dictionary
        @throws FileNotFoundError if file doesn't exist
        @throws tomllib.TOMLDecodeError if invalid TOML
        """
        filepath = self.definitions_dir / filename
        with filepath.open("rb") as f:
            return tomllib.load(f)

    def parse_aliases(self) -> AliasDefinitions:
        """
        @description Parse aliases.toml into validated model
        @return AliasDefinitions with all alias groups
        """
        data = self._read_toml("aliases.toml")
        raw_aliases = data.get("aliases", {})

        aliases: dict[str, dict[str, Alias]] = {}
        for group_name, group_entries in raw_aliases.items():
            aliases[group_name] = {
                name: Alias(**entry) for name, entry in group_entries.items()
            }

        return AliasDefinitions(aliases=aliases)

    def parse_functions(self) -> FunctionDefinitions:
        """
        @description Parse functions.toml into validated model
        @return FunctionDefinitions with all functions
        """
        data = self._read_toml("functions.toml")
        raw_functions = data.get("functions", {})

        functions: dict[str, Function] = {
            name: Function(**entry) for name, entry in raw_functions.items()
        }

        return FunctionDefinitions(functions=functions)

    def parse_env(self) -> EnvDefinitions:
        """
        @description Parse env.toml into validated model
        @return EnvDefinitions with all environment variable groups
        """
        data = self._read_toml("env.toml")
        raw_env = data.get("env", {})

        env: dict[str, dict[str, EnvVar]] = {}
        for group_name, group_entries in raw_env.items():
            env[group_name] = {
                name: EnvVar(**entry) for name, entry in group_entries.items()
            }

        return EnvDefinitions(env=env)

    def parse_path(self) -> PathDefinitions:
        """
        @description Parse path.toml into validated model
        @return PathDefinitions with ordered PATH entries
        """
        data = self._read_toml("path.toml")
        raw_paths = data.get("path", [])

        paths = [PathEntry(**entry) for entry in raw_paths]
        return PathDefinitions(path=paths)

    def parse_highlights(self) -> HighlightDefinitions:
        """
        @description Parse highlights.toml into validated model
        @return HighlightDefinitions with all highlight groups
        """
        data = self._read_toml("highlights.toml")
        raw_highlights = data.get("highlights", {})

        highlights: dict[str, dict[str, HighlightStyle]] = {}
        for group_name, group_entries in raw_highlights.items():
            highlights[group_name] = {
                name: HighlightStyle(**entry) for name, entry in group_entries.items()
            }

        return HighlightDefinitions(highlights=highlights)

    def parse_keybindings(self) -> KeybindingDefinitions:
        """
        @description Parse keybindings.toml into validated model
        @return KeybindingDefinitions with all keybinding groups
        """
        data = self._read_toml("keybindings.toml")
        raw_keybindings = data.get("keybindings", {})

        keybindings: dict[str, dict[str, Keybinding]] = {}
        for group_name, group_entries in raw_keybindings.items():
            keybindings[group_name] = {
                name: Keybinding(**entry) for name, entry in group_entries.items()
            }

        return KeybindingDefinitions(keybindings=keybindings)

    def parse_init(self) -> InitDefinitions:
        """
        @description Parse init.toml into validated model (sorted by priority)
        @return InitDefinitions with all tool init entries
        """
        data = self._read_toml("init.toml")
        raw_init = data.get("init", {})

        init_entries: dict[str, InitEntry] = {
            name: InitEntry(**entry) for name, entry in raw_init.items()
        }

        return InitDefinitions(init=init_entries)

    def parse_plugins(self) -> PluginDefinitions:
        """
        @description Parse plugins.toml into validated model
        @return PluginDefinitions with all zsh plugin entries
        """
        data = self._read_toml("plugins.toml")
        raw_plugins = data.get("plugins", {})

        plugins: dict[str, Plugin] = {}
        for name, entry in raw_plugins.items():
            if "from" in entry:
                entry["from_source"] = entry.pop("from")
            plugins[name] = Plugin(**entry)

        return PluginDefinitions(plugins=plugins)

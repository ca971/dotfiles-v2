"""
@file generators/tests/test_parser.py
@description Unit tests for the SSOT definition parser
@since 1.0.0
@version 1.0.0
"""

from pathlib import Path

import pytest

from src.parser import DefinitionParser


@pytest.fixture
def parser() -> DefinitionParser:
    """Fixture providing parser pointed at the real definitions."""
    definitions_dir = Path(__file__).resolve().parent.parent.parent / "definitions"
    return DefinitionParser(definitions_dir)


class TestParseAliases:
    """Tests for alias parsing."""

    def test_parse_aliases_returns_groups(self, parser: DefinitionParser) -> None:
        result = parser.parse_aliases()
        assert len(result.aliases) > 0

    def test_parse_aliases_has_navigation(self, parser: DefinitionParser) -> None:
        result = parser.parse_aliases()
        assert "navigation" in result.aliases

    def test_parse_aliases_has_git(self, parser: DefinitionParser) -> None:
        result = parser.parse_aliases()
        assert "git" in result.aliases

    def test_alias_has_command(self, parser: DefinitionParser) -> None:
        result = parser.parse_aliases()
        ls_alias = result.aliases["listing"]["ls"]
        assert ls_alias.command == "eza --icons --group-directories-first"

    def test_alias_has_description(self, parser: DefinitionParser) -> None:
        result = parser.parse_aliases()
        ls_alias = result.aliases["listing"]["ls"]
        assert ls_alias.description == "List files"

    def test_alias_has_requires(self, parser: DefinitionParser) -> None:
        result = parser.parse_aliases()
        ls_alias = result.aliases["listing"]["ls"]
        assert ls_alias.requires == "eza"


class TestParseFunctions:
    """Tests for function parsing."""

    def test_parse_functions_returns_entries(self, parser: DefinitionParser) -> None:
        result = parser.parse_functions()
        assert len(result.functions) > 0

    def test_function_has_body(self, parser: DefinitionParser) -> None:
        result = parser.parse_functions()
        mkcd = result.functions["mkcd"]
        assert "mkdir" in mkcd.body

    def test_function_has_description(self, parser: DefinitionParser) -> None:
        result = parser.parse_functions()
        mkcd = result.functions["mkcd"]
        assert mkcd.description == "Create a directory and cd into it"


class TestParseEnv:
    """Tests for environment variable parsing."""

    def test_parse_env_returns_groups(self, parser: DefinitionParser) -> None:
        result = parser.parse_env()
        assert len(result.env) > 0

    def test_env_has_xdg(self, parser: DefinitionParser) -> None:
        result = parser.parse_env()
        assert "xdg" in result.env

    def test_env_has_editor(self, parser: DefinitionParser) -> None:
        result = parser.parse_env()
        assert "EDITOR" in result.env["editor"]
        assert result.env["editor"]["EDITOR"].value == "nvim"

    def test_env_platform_restriction(self, parser: DefinitionParser) -> None:
        result = parser.parse_env()
        homebrew_var = result.env["darwin"]["HOMEBREW_NO_ANALYTICS"]
        assert homebrew_var.platforms == ["darwin"]


class TestParsePath:
    """Tests for PATH parsing."""

    def test_parse_path_returns_entries(self, parser: DefinitionParser) -> None:
        result = parser.parse_path()
        assert len(result.path) > 0

    def test_path_first_is_local_bin(self, parser: DefinitionParser) -> None:
        result = parser.parse_path()
        assert "$HOME/.local/bin" in result.path[0].path

    def test_path_has_prepend_flag(self, parser: DefinitionParser) -> None:
        result = parser.parse_path()
        assert result.path[0].prepend is True

    def test_path_last_entries_are_append(self, parser: DefinitionParser) -> None:
        result = parser.parse_path()
        assert result.path[-1].prepend is False


class TestParseKeybindings:
    """Tests for keybinding parsing."""

    def test_parse_keybindings_returns_groups(self, parser: DefinitionParser) -> None:
        result = parser.parse_keybindings()
        assert len(result.keybindings) > 0

    def test_keybindings_has_navigation(self, parser: DefinitionParser) -> None:
        result = parser.parse_keybindings()
        assert "navigation" in result.keybindings

    def test_keybinding_has_key(self, parser: DefinitionParser) -> None:
        result = parser.parse_keybindings()
        ctrl_r = result.keybindings["navigation"]["ctrl_r"]
        assert ctrl_r.key == "ctrl-r"

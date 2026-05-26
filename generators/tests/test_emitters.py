"""
@file generators/tests/test_emitters.py
@description Unit tests for shell-specific emitters
@since 1.0.0
@version 1.0.0
"""

from pathlib import Path

import pytest

from src.emitters import BashEmitter, FishEmitter, NushellEmitter, ZshEmitter
from src.models import (
    Alias,
    AliasDefinitions,
    EnvDefinitions,
    EnvVar,
    Function,
    FunctionDefinitions,
    PathDefinitions,
    PathEntry,
)


@pytest.fixture
def tmp_output(tmp_path: Path) -> Path:
    """Fixture providing temporary output directory."""
    return tmp_path


@pytest.fixture
def sample_aliases() -> AliasDefinitions:
    """Fixture with sample alias definitions."""
    return AliasDefinitions(
        aliases={
            "navigation": {
                "..": Alias(command="cd ..", description="Go up"),
            },
            "listing": {
                "ls": Alias(command="eza --icons", description="List files", requires="eza"),
                "ll": Alias(command="eza -la", description="Long list"),
            },
        }
    )


@pytest.fixture
def sample_functions() -> FunctionDefinitions:
    """Fixture with sample function definitions."""
    return FunctionDefinitions(
        functions={
            "mkcd": Function(
                description="Create and cd",
                body='mkdir -p "$1" && cd "$1"',
            ),
        }
    )


@pytest.fixture
def sample_env() -> EnvDefinitions:
    """Fixture with sample env definitions."""
    return EnvDefinitions(
        env={
            "editor": {
                "EDITOR": EnvVar(value="nvim", description="Editor"),
                "PAGER": EnvVar(value="less", description="Pager"),
            },
        }
    )


@pytest.fixture
def sample_path() -> PathDefinitions:
    """Fixture with sample PATH definitions."""
    return PathDefinitions(
        path=[
            PathEntry(path="$HOME/.local/bin", description="Local bin", prepend=True),
            PathEntry(
                path="$GOPATH/bin",
                description="Go bin",
                prepend=True,
                condition="$GOPATH",
            ),
            PathEntry(path="/usr/bin", description="System", prepend=False),
        ]
    )


class TestBashEmitter:
    """Tests for Bash code generation."""

    def test_shell_name(self, tmp_output: Path) -> None:
        emitter = BashEmitter(tmp_output)
        assert emitter.shell_name == "bash"

    def test_emit_aliases(self, tmp_output: Path, sample_aliases: AliasDefinitions) -> None:
        emitter = BashEmitter(tmp_output)
        result = emitter.emit_aliases(sample_aliases)
        assert "alias ..='cd ..'" in result
        assert "alias ls='eza --icons'" in result
        assert "alias ll='eza -la'" in result

    def test_emit_functions(
        self, tmp_output: Path, sample_functions: FunctionDefinitions
    ) -> None:
        emitter = BashEmitter(tmp_output)
        result = emitter.emit_functions(sample_functions)
        assert "mkcd()" in result
        assert "mkdir" in result

    def test_emit_env(self, tmp_output: Path, sample_env: EnvDefinitions) -> None:
        emitter = BashEmitter(tmp_output)
        result = emitter.emit_env(sample_env)
        assert 'export EDITOR="nvim"' in result
        assert 'export PAGER="less"' in result

    def test_emit_path(self, tmp_output: Path, sample_path: PathDefinitions) -> None:
        emitter = BashEmitter(tmp_output)
        result = emitter.emit_path(sample_path)
        assert "$HOME/.local/bin" in result
        assert "$GOPATH" in result
        assert "PATH" in result


class TestZshEmitter:
    """Tests for Zsh code generation."""

    def test_shell_name(self, tmp_output: Path) -> None:
        emitter = ZshEmitter(tmp_output)
        assert emitter.shell_name == "zsh"

    def test_emit_aliases(self, tmp_output: Path, sample_aliases: AliasDefinitions) -> None:
        emitter = ZshEmitter(tmp_output)
        result = emitter.emit_aliases(sample_aliases)
        assert "alias ls='eza --icons'" in result

    def test_emit_path_uses_typeset(
        self, tmp_output: Path, sample_path: PathDefinitions
    ) -> None:
        emitter = ZshEmitter(tmp_output)
        result = emitter.emit_path(sample_path)
        assert "typeset -U path" in result


class TestFishEmitter:
    """Tests for Fish code generation."""

    def test_shell_name(self, tmp_output: Path) -> None:
        emitter = FishEmitter(tmp_output)
        assert emitter.shell_name == "fish"

    def test_emit_aliases_uses_abbr(
        self, tmp_output: Path, sample_aliases: AliasDefinitions
    ) -> None:
        emitter = FishEmitter(tmp_output)
        result = emitter.emit_aliases(sample_aliases)
        assert "abbr -a ls 'eza --icons'" in result

    def test_emit_functions_uses_function_end(
        self, tmp_output: Path, sample_functions: FunctionDefinitions
    ) -> None:
        emitter = FishEmitter(tmp_output)
        result = emitter.emit_functions(sample_functions)
        assert "function mkcd" in result
        assert "end" in result

    def test_emit_path_uses_fish_add_path(
        self, tmp_output: Path, sample_path: PathDefinitions
    ) -> None:
        emitter = FishEmitter(tmp_output)
        result = emitter.emit_path(sample_path)
        assert "fish_add_path" in result


class TestNushellEmitter:
    """Tests for Nushell code generation."""

    def test_shell_name(self, tmp_output: Path) -> None:
        emitter = NushellEmitter(tmp_output)
        assert emitter.shell_name == "nushell"

    def test_emit_aliases_uses_equals(
        self, tmp_output: Path, sample_aliases: AliasDefinitions
    ) -> None:
        emitter = NushellEmitter(tmp_output)
        result = emitter.emit_aliases(sample_aliases)
        assert "alias ls = eza --icons" in result

    def test_emit_aliases_skips_dot_aliases(
        self, tmp_output: Path, sample_aliases: AliasDefinitions
    ) -> None:
        emitter = NushellEmitter(tmp_output)
        result = emitter.emit_aliases(sample_aliases)
        assert "alias .." not in result

    def test_emit_env_uses_dollar_env(
        self, tmp_output: Path, sample_env: EnvDefinitions
    ) -> None:
        emitter = NushellEmitter(tmp_output)
        result = emitter.emit_env(sample_env)
        assert "$env.EDITOR" in result


class TestWriteOutput:
    """Tests for file writing."""

    def test_write_creates_file(self, tmp_output: Path, sample_aliases: AliasDefinitions) -> None:
        emitter = BashEmitter(tmp_output)
        content = emitter.emit_aliases(sample_aliases)
        path = emitter.write("aliases.gen.sh", content)
        assert path.exists()
        assert path.read_text().startswith("# ═══")

    def test_write_includes_header(
        self, tmp_output: Path, sample_aliases: AliasDefinitions
    ) -> None:
        emitter = BashEmitter(tmp_output)
        content = emitter.emit_aliases(sample_aliases)
        path = emitter.write("aliases.gen.sh", content)
        file_content = path.read_text()
        assert "AUTO-GENERATED" in file_content
        assert "DO NOT EDIT" in file_content
        assert "Shell: bash" in file_content

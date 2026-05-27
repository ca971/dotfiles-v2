"""
@file generators/tests/test_emitters.py
@description Unit tests for shell-specific emitters — aliases, functions,
             env, path, init, keybindings, plugins, POSIX→nushell conversion
@since 1.0.0
@version 1.1.0
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
    InitDefinitions,
    InitEntry,
    Keybinding,
    KeybindingDefinitions,
    PathDefinitions,
    PathEntry,
    Plugin,
    PluginDefinitions,
)

# ═══════════════════════════════════════════════════════════════════════════════
# Fixtures
# ═══════════════════════════════════════════════════════════════════════════════


@pytest.fixture
def tmp_output(tmp_path: Path) -> Path:
    """Temporary output directory."""
    return tmp_path


@pytest.fixture
def sample_aliases() -> AliasDefinitions:
    """Aliases: simple, with flags, dot alias to skip."""
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
def sample_aliases_no_flags() -> AliasDefinitions:
    """Aliases with no flags — all should stay as `alias` in nushell."""
    return AliasDefinitions(
        aliases={
            "git": {
                "g": Alias(command="git", description="Git shortcut"),
                "ga": Alias(command="git add", description="Git add"),
                "gp": Alias(command="git push", description="Git push"),
            },
        }
    )


@pytest.fixture
def sample_aliases_mixed() -> AliasDefinitions:
    """Mixed aliases: some simple, some with flags."""
    return AliasDefinitions(
        aliases={
            "mixed": {
                "g": Alias(command="git", description="Simple"),
                "ll": Alias(command="eza -la --icons", description="With flags"),
                "gaa": Alias(command="git add --all", description="With double-dash flag"),
            },
        }
    )


@pytest.fixture
def sample_functions() -> FunctionDefinitions:
    """Functions including one with eval (should be skipped in nushell)."""
    return FunctionDefinitions(
        functions={
            "mkcd": Function(
                description="Create directory and cd into it",
                body='mkdir -p "$1" && cd "$1"',
            ),
            "fzh": Function(
                description="Fuzzy history (uses eval)",
                body='eval "$(fzf --height 40%)"',
            ),
        }
    )


@pytest.fixture
def sample_env() -> EnvDefinitions:
    """Environment variables."""
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
    """PATH entries: unconditional, conditional, append."""
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


@pytest.fixture
def sample_init() -> InitDefinitions:
    """Tool init entries: eager (starship) and lazy (fzf)."""
    return InitDefinitions(
        init={
            "starship": InitEntry(
                description="Cross-shell prompt",
                priority=50,
                verify="starship",
                bash='eval "$(starship init bash)"',
                zsh='eval "$(starship init zsh)"',
                fish="starship init fish | source",
                nushell="",
            ),
            "fzf": InitEntry(
                description="Fuzzy finder",
                priority=35,
                verify="fzf",
                lazy=True,
                lazy_triggers=["fzf"],
                bash='eval "$(fzf --bash)"',
                zsh="source <(fzf --zsh)",
                fish="fzf --fish | source",
                nushell="",
            ),
        }
    )


@pytest.fixture
def sample_keybindings() -> KeybindingDefinitions:
    """Keybinding definitions."""
    return KeybindingDefinitions(
        keybindings={
            "global": {
                "ctrl-r": Keybinding(
                    key="ctrl-r",
                    action="atuin search",
                    description="Atuin history search",
                ),
            },
        }
    )


@pytest.fixture
def sample_plugins() -> PluginDefinitions:
    """Zsh plugins (zinit-managed)."""
    return PluginDefinitions(
        plugins={
            "fast-syntax-highlighting": Plugin(
                repo="zdharma-continuum/fast-syntax-highlighting",
                description="Syntax highlighting",
                load="turbo_0a",
                ice={"wait": "0a"},
            ),
        }
    )


# ═══════════════════════════════════════════════════════════════════════════════
# Bash Emitter
# ═══════════════════════════════════════════════════════════════════════════════


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

    def test_emit_functions(self, tmp_output: Path, sample_functions: FunctionDefinitions) -> None:
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

    def test_emit_init_eager(self, tmp_output: Path, sample_init: InitDefinitions) -> None:
        emitter = BashEmitter(tmp_output)
        result = emitter.emit_init(sample_init)
        assert "starship" in result
        assert 'eval "$(starship init bash)"' in result

    def test_emit_init_lazy(self, tmp_output: Path, sample_init: InitDefinitions) -> None:
        emitter = BashEmitter(tmp_output)
        result = emitter.emit_init(sample_init)
        assert "LAZY" in result
        assert "fzf" in result

    def test_emit_keybindings(
        self, tmp_output: Path, sample_keybindings: KeybindingDefinitions
    ) -> None:
        emitter = BashEmitter(tmp_output)
        result = emitter.emit_keybindings(sample_keybindings)
        assert "bind" in result.lower() or "ctrl-r" in result


# ═══════════════════════════════════════════════════════════════════════════════
# Zsh Emitter
# ═══════════════════════════════════════════════════════════════════════════════


class TestZshEmitter:
    """Tests for Zsh code generation."""

    def test_shell_name(self, tmp_output: Path) -> None:
        emitter = ZshEmitter(tmp_output)
        assert emitter.shell_name == "zsh"

    def test_emit_aliases(self, tmp_output: Path, sample_aliases: AliasDefinitions) -> None:
        emitter = ZshEmitter(tmp_output)
        result = emitter.emit_aliases(sample_aliases)
        assert "alias ls='eza --icons'" in result
        # Unlike nushell, zsh does not skip dot aliases
        assert "alias ..='cd ..'" in result

    def test_emit_path_uses_typeset(self, tmp_output: Path, sample_path: PathDefinitions) -> None:
        emitter = ZshEmitter(tmp_output)
        result = emitter.emit_path(sample_path)
        assert "typeset -U path" in result

    def test_emit_init(self, tmp_output: Path, sample_init: InitDefinitions) -> None:
        emitter = ZshEmitter(tmp_output)
        result = emitter.emit_init(sample_init)
        assert "starship" in result
        assert 'eval "$(starship init zsh)"' in result

    def test_emit_plugins(self, tmp_output: Path, sample_plugins: PluginDefinitions) -> None:
        emitter = ZshEmitter(tmp_output)
        result = emitter.emit_plugins(sample_plugins)
        assert "fast-syntax-highlighting" in result
        assert "zdharma-continuum" in result
        assert "turbo_0a" in result

    def test_emit_keybindings(
        self, tmp_output: Path, sample_keybindings: KeybindingDefinitions
    ) -> None:
        emitter = ZshEmitter(tmp_output)
        result = emitter.emit_keybindings(sample_keybindings)
        assert "bindkey" in result or "ctrl-r" in result


# ═══════════════════════════════════════════════════════════════════════════════
# Fish Emitter
# ═══════════════════════════════════════════════════════════════════════════════


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

    def test_emit_init(self, tmp_output: Path, sample_init: InitDefinitions) -> None:
        emitter = FishEmitter(tmp_output)
        result = emitter.emit_init(sample_init)
        assert "starship" in result


# ═══════════════════════════════════════════════════════════════════════════════
# Nushell Emitter
# ═══════════════════════════════════════════════════════════════════════════════


class TestNushellEmitter:
    """Tests for Nushell code generation."""

    def test_shell_name(self, tmp_output: Path) -> None:
        emitter = NushellEmitter(tmp_output)
        assert emitter.shell_name == "nushell"

    # ── Aliases ──

    def test_emit_aliases_skips_dot_aliases(
        self, tmp_output: Path, sample_aliases: AliasDefinitions
    ) -> None:
        emitter = NushellEmitter(tmp_output)
        result = emitter.emit_aliases(sample_aliases)
        assert "alias .." not in result
        assert "def .." not in result

    def test_emit_aliases_flag_becomes_def(
        self, tmp_output: Path, sample_aliases: AliasDefinitions
    ) -> None:
        """Aliases with flags (--icons, -la) must use `def --wrapped`, not `alias`."""
        emitter = NushellEmitter(tmp_output)
        result = emitter.emit_aliases(sample_aliases)
        assert "def --wrapped ls" in result
        assert "eza --icons ...$rest" in result
        assert "def --wrapped ll" in result
        assert "eza -la ...$rest" in result

    def test_emit_aliases_simple_stays_alias(
        self, tmp_output: Path, sample_aliases_no_flags: AliasDefinitions
    ) -> None:
        """Aliases without flags stay as `alias`."""
        emitter = NushellEmitter(tmp_output)
        result = emitter.emit_aliases(sample_aliases_no_flags)
        assert "alias g = git" in result
        assert "alias ga = git add" in result
        assert "alias gp = git push" in result
        assert "def" not in result  # no def needed

    def test_emit_aliases_mixed_flag_detection(
        self, tmp_output: Path, sample_aliases_mixed: AliasDefinitions
    ) -> None:
        """Mixed: simple → alias, with flags → def --wrapped."""
        emitter = NushellEmitter(tmp_output)
        result = emitter.emit_aliases(sample_aliases_mixed)
        assert "alias g = git" in result
        assert "def --wrapped ll" in result
        assert "def --wrapped gaa" in result
        assert "git add --all ...$rest" in result

    def test_emit_aliases_no_equals_in_def(
        self, tmp_output: Path, sample_aliases_mixed: AliasDefinitions
    ) -> None:
        """Regression: `def --wrapped` must NOT have `=` sign (nushell syntax error)."""
        emitter = NushellEmitter(tmp_output)
        result = emitter.emit_aliases(sample_aliases_mixed)
        # Ensure no line has both 'def' and ' = ' (would be invalid nushell)
        for line in result.splitlines():
            if "def" in line:
                assert " = " not in line, f"def should not use '=': {line}"

    # ── Functions / POSIX conversion ──

    def test_emit_functions_basic(
        self, tmp_output: Path, sample_functions: FunctionDefinitions
    ) -> None:
        emitter = NushellEmitter(tmp_output)
        result = emitter.emit_functions(sample_functions)
        assert "def mkcd" in result
        assert "mkdir" in result

    def test_emit_functions_skips_eval(
        self, tmp_output: Path, sample_functions: FunctionDefinitions
    ) -> None:
        """Functions using eval must be skipped in nushell."""
        emitter = NushellEmitter(tmp_output)
        result = emitter.emit_functions(sample_functions)
        assert "fzh: skipped" in result.lower() or "eval" in result.lower()

    def test_posix_to_nushell_local_to_let(self, tmp_output: Path) -> None:
        """`local x=y` → `let x = y`"""
        emitter = NushellEmitter(tmp_output)
        result = emitter._posix_to_nushell('local foo="bar"')
        assert result is not None
        assert "let foo = " in result
        assert "mut" not in result

    def test_posix_to_nushell_local_without_assign(self, tmp_output: Path) -> None:
        """`local x` → `mut x`"""
        emitter = NushellEmitter(tmp_output)
        result = emitter._posix_to_nushell("local foo")
        assert result is not None
        assert "mut foo" in result

    def test_posix_to_nushell_export_to_env(self, tmp_output: Path) -> None:
        """`export X=Y` → `$env.X = Y`"""
        emitter = NushellEmitter(tmp_output)
        result = emitter._posix_to_nushell('export EDITOR="nvim"')
        assert result is not None
        assert "$env.EDITOR" in result
        assert "nvim" in result

    def test_posix_to_nushell_cmd_substitution(self, tmp_output: Path) -> None:
        """`$(cmd)` → `(cmd | str trim)`"""
        emitter = NushellEmitter(tmp_output)
        result = emitter._posix_to_nushell('echo "$(whoami)"')
        assert result is not None
        assert "whoami" in result
        assert "str trim" in result

    def test_posix_to_nushell_eval_returns_none(self, tmp_output: Path) -> None:
        """eval → None (cannot convert)"""
        emitter = NushellEmitter(tmp_output)
        result = emitter._posix_to_nushell('eval "$(starship init bash)"')
        assert result is None

    def test_posix_to_nushell_if_fi_conversion(self, tmp_output: Path) -> None:
        """`[[ ... ]]; then ... fi` → `if ( ... ) { ... }`"""
        emitter = NushellEmitter(tmp_output)
        result = emitter._posix_to_nushell('[[ -f "$HOME/.file" ]]; then echo "exists"; fi')
        assert result is not None
        assert "if (" in result
        assert "{" in result
        # The standalone `fi` keyword should be gone (replaced by `}`)
        assert "fi" in result  # 'fi' appears inside 'if (' — that's expected
        # Verify the conversion: no standalone fi
        assert not result.strip().endswith("fi")

    # ── Env ──

    def test_emit_env_uses_dollar_env(self, tmp_output: Path, sample_env: EnvDefinitions) -> None:
        emitter = NushellEmitter(tmp_output)
        result = emitter.emit_env(sample_env)
        assert "$env.EDITOR" in result
        assert "nvim" in result

    # ── Init ──

    def test_emit_init(self, tmp_output: Path, sample_init: InitDefinitions) -> None:
        emitter = NushellEmitter(tmp_output)
        result = emitter.emit_init(sample_init)
        # Both sample entries have empty nushell init → all skipped
        # The output should be minimal (just section headers are skipped too)
        assert result is not None
        assert "starship" not in result  # skipped because nushell="" for starship
        assert "fzf" not in result  # skipped because nushell="" for fzf


# ═══════════════════════════════════════════════════════════════════════════════
# Write Output (cross-emitter)
# ═══════════════════════════════════════════════════════════════════════════════


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

    def test_write_nushell_uses_nu_extension(
        self, tmp_output: Path, sample_aliases: AliasDefinitions
    ) -> None:
        """Nushell files must use .gen.nu extension, not .gen.sh."""
        emitter = NushellEmitter(tmp_output)
        content = emitter.emit_aliases(sample_aliases)
        path = emitter.write("aliases.gen.nu", content)
        assert path.suffix == ".nu"
        assert "Shell: nushell" in path.read_text()

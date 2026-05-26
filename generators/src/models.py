"""
@file generators/src/models.py
@description Pydantic data models for SSOT definitions
@since 1.0.0
@version 1.0.0
@see docs/SSOT.md
"""

from __future__ import annotations

from pydantic import BaseModel, Field


class Alias(BaseModel):
    """Single alias definition."""

    command: str = Field(description="Command to alias to")
    description: str = Field(description="Human-readable description")
    requires: str | None = Field(default=None, description="Required tool")
    platforms: list[str] | None = Field(default=None, description="Platform restrictions")


class Function(BaseModel):
    """Single function definition."""

    description: str = Field(description="Human-readable description")
    body: str = Field(description="Function body (POSIX-compatible)")
    requires: list[str] | None = Field(default=None, description="Required tools")
    platforms: list[str] | None = Field(default=None, description="Platform restrictions")


class EnvVar(BaseModel):
    """Single environment variable definition."""

    value: str = Field(description="Value to set")
    description: str = Field(description="Human-readable description")
    platforms: list[str] | None = Field(default=None, description="Platform restrictions")
    condition: str | None = Field(default=None, description="Condition to check before setting")


class PathEntry(BaseModel):
    """Single PATH entry definition."""

    path: str = Field(description="Directory to add to PATH")
    description: str = Field(description="Human-readable description")
    platforms: list[str] | None = Field(default=None, description="Platform restrictions")
    condition: str | None = Field(default=None, description="Only add if path exists")
    prepend: bool = Field(default=True, description="Prepend to PATH (vs append)")


class HighlightStyle(BaseModel):
    """Single syntax highlight style."""

    fg: str = Field(description="Foreground color (hex)")
    bold: bool = Field(default=False, description="Bold text")
    italic: bool = Field(default=False, description="Italic text")
    underline: bool = Field(default=False, description="Underlined text")
    description: str = Field(description="Human-readable description")


class Keybinding(BaseModel):
    """Single keybinding definition."""

    key: str = Field(description="Key sequence")
    action: str = Field(description="Command or widget to execute")
    description: str = Field(description="Human-readable description")
    mode: str | None = Field(default=None, description="Vi mode (insert, normal)")


class AliasDefinitions(BaseModel):
    """All alias groups."""

    aliases: dict[str, dict[str, Alias]] = Field(default_factory=dict)


class FunctionDefinitions(BaseModel):
    """All function definitions."""

    functions: dict[str, Function] = Field(default_factory=dict)


class EnvDefinitions(BaseModel):
    """All environment variable groups."""

    env: dict[str, dict[str, EnvVar]] = Field(default_factory=dict)


class PathDefinitions(BaseModel):
    """All PATH entries."""

    path: list[PathEntry] = Field(default_factory=list)


class HighlightDefinitions(BaseModel):
    """All highlight style groups."""

    highlights: dict[str, dict[str, HighlightStyle]] = Field(default_factory=dict)


class KeybindingDefinitions(BaseModel):
    """All keybinding groups."""

    keybindings: dict[str, dict[str, Keybinding]] = Field(default_factory=dict)


class InitEntry(BaseModel):
    """Single tool shell initialization entry."""

    description: str = Field(description="What the tool does")
    priority: int = Field(description="Loading order (lower = first)")
    verify: str = Field(description="Command to check availability")
    lazy: bool = Field(default=False, description="Defer init until first usage")
    lazy_triggers: list[str] = Field(default_factory=list, description="Commands that trigger lazy load")
    bash: str = Field(default="", description="Bash init command")
    zsh: str = Field(default="", description="Zsh init command")
    fish: str = Field(default="", description="Fish init command")
    nushell: str = Field(default="", description="Nushell init command")


class InitDefinitions(BaseModel):
    """All tool initialization entries."""

    init: dict[str, InitEntry] = Field(default_factory=dict)


class Plugin(BaseModel):
    """Single Zsh plugin definition (zinit-managed)."""

    repo: str = Field(description="GitHub owner/repo or snippet identifier")
    description: str = Field(description="Human-readable description")
    load: str = Field(description="Loading strategy (immediate, turbo_0a, etc.)")
    ice: dict[str, str | bool] = Field(default_factory=dict, description="Zinit ice modifiers")
    pick: str | None = Field(default=None, description="Specific file to source")
    from_source: str | None = Field(default=None, description="Source type (github, snippet)")
    depends_on: str | None = Field(default=None, description="Plugin dependency")


class PluginDefinitions(BaseModel):
    """All Zsh plugin definitions."""

    plugins: dict[str, Plugin] = Field(default_factory=dict)

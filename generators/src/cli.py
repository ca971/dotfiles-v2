"""
@file generators/src/cli.py
@description CLI entry point for the SSOT generator
@since 1.0.0
@version 1.0.0
@see bin/dotfiles-gen

Usage:
    python -m src.cli generate --all
    python -m src.cli generate --shell bash
    python -m src.cli validate
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from .emitters import BashEmitter, FishEmitter, NushellEmitter, ShellEmitter, ZshEmitter
from .parser import DefinitionParser

SHELLS = ("bash", "zsh", "fish", "nushell")


def get_project_root() -> Path:
    """
    @description Find the dotfiles project root from the generators directory
    @return Path to the project root (~/.dotfiles)
    """
    generators_dir = Path(__file__).resolve().parent.parent
    return generators_dir.parent


def get_emitter(shell: str, output_dir: Path) -> ShellEmitter:
    """
    @description Factory for shell-specific emitters
    @param shell Shell name (bash, zsh, fish, nushell)
    @param output_dir Path to write generated files
    @return Appropriate ShellEmitter subclass instance
    """
    emitters: dict[str, type[ShellEmitter]] = {
        "bash": BashEmitter,
        "zsh": ZshEmitter,
        "fish": FishEmitter,
        "nushell": NushellEmitter,
    }
    emitter_cls = emitters.get(shell)
    if not emitter_cls:
        raise ValueError(f"Unknown shell: {shell}. Must be one of: {SHELLS}")
    return emitter_cls(output_dir)


def generate(shells: list[str], project_root: Path) -> int:
    """
    @description Generate shell configs from SSOT definitions
    @param shells List of shells to generate for
    @param project_root Dotfiles project root
    @return Exit code (0 = success)
    """
    definitions_dir = project_root / "definitions"
    parser = DefinitionParser(definitions_dir)

    print(f"Parsing definitions from: {definitions_dir}")

    try:
        aliases = parser.parse_aliases()
        functions = parser.parse_functions()
        env = parser.parse_env()
        paths = parser.parse_path()
        keybindings = parser.parse_keybindings()
        init = parser.parse_init()
        plugins = parser.parse_plugins()
    except Exception as e:
        print(f"ERROR: Failed to parse definitions: {e}", file=sys.stderr)
        return 1

    print(f"  Aliases: {sum(len(g) for g in aliases.aliases.values())} entries")
    print(f"  Functions: {len(functions.functions)} entries")
    print(f"  Env vars: {sum(len(g) for g in env.env.values())} entries")
    print(f"  PATH entries: {len(paths.path)} entries")
    print(f"  Keybindings: {sum(len(g) for g in keybindings.keybindings.values())} entries")
    print(f"  Init: {len(init.init)} tool initializations")
    print(f"  Plugins: {len(plugins.plugins)} zsh plugins")

    for shell in shells:
        output_dir = project_root / "shells" / shell / "generated"
        emitter = get_emitter(shell, output_dir)

        ext = "fish" if shell == "fish" else "sh"
        print(f"\nGenerating for {shell} -> {output_dir}")

        emitter.write(f"aliases.gen.{ext}", emitter.emit_aliases(aliases))
        emitter.write(f"functions.gen.{ext}", emitter.emit_functions(functions))
        emitter.write(f"env.gen.{ext}", emitter.emit_env(env))
        emitter.write(f"path.gen.{ext}", emitter.emit_path(paths))
        emitter.write(f"keybindings.gen.{ext}", emitter.emit_keybindings(keybindings))
        emitter.write(f"init.gen.{ext}", emitter.emit_init(init))

        file_count = 6
        if shell == "zsh":
            from .emitters.zsh import ZshEmitter
            assert isinstance(emitter, ZshEmitter)
            emitter.write("plugins.gen.sh", emitter.emit_plugins(plugins))
            file_count = 7

        print(f"  Generated {file_count} files for {shell}")

    print("\nDone!")
    return 0


def validate(project_root: Path) -> int:
    """
    @description Validate all SSOT definitions without generating
    @param project_root Dotfiles project root
    @return Exit code (0 = valid, 1 = errors)
    """
    definitions_dir = project_root / "definitions"
    parser = DefinitionParser(definitions_dir)

    errors: list[str] = []

    print("Validating definitions...")

    try:
        aliases = parser.parse_aliases()
        print(f"  aliases.toml: {sum(len(g) for g in aliases.aliases.values())} aliases OK")
    except Exception as e:
        errors.append(f"  aliases.toml: FAILED - {e}")

    try:
        functions = parser.parse_functions()
        print(f"  functions.toml: {len(functions.functions)} functions OK")
    except Exception as e:
        errors.append(f"  functions.toml: FAILED - {e}")

    try:
        env = parser.parse_env()
        print(f"  env.toml: {sum(len(g) for g in env.env.values())} vars OK")
    except Exception as e:
        errors.append(f"  env.toml: FAILED - {e}")

    try:
        paths = parser.parse_path()
        print(f"  path.toml: {len(paths.path)} entries OK")
    except Exception as e:
        errors.append(f"  path.toml: FAILED - {e}")

    try:
        highlights = parser.parse_highlights()
        print(
            f"  highlights.toml: "
            f"{sum(len(g) for g in highlights.highlights.values())} styles OK"
        )
    except Exception as e:
        errors.append(f"  highlights.toml: FAILED - {e}")

    try:
        keybindings = parser.parse_keybindings()
        print(
            f"  keybindings.toml: "
            f"{sum(len(g) for g in keybindings.keybindings.values())} bindings OK"
        )
    except Exception as e:
        errors.append(f"  keybindings.toml: FAILED - {e}")

    if errors:
        print("\nValidation FAILED:")
        for err in errors:
            print(err, file=sys.stderr)
        return 1

    print("\nAll definitions valid!")
    return 0


def main() -> None:
    """@description CLI main entry point"""
    arg_parser = argparse.ArgumentParser(
        prog="dotfiles-gen",
        description="Generate shell configs from SSOT definitions",
    )

    subparsers = arg_parser.add_subparsers(dest="command", required=True)

    gen_parser = subparsers.add_parser("generate", help="Generate shell configs")
    gen_parser.add_argument("--all", action="store_true", help="Generate for all shells")
    gen_parser.add_argument("--shell", choices=SHELLS, help="Generate for specific shell")

    subparsers.add_parser("validate", help="Validate definitions without generating")

    args = arg_parser.parse_args()
    project_root = get_project_root()

    if args.command == "generate":
        if args.all:
            shells = list(SHELLS)
        elif args.shell:
            shells = [args.shell]
        else:
            arg_parser.error("Either --all or --shell required")
            return

        sys.exit(generate(shells, project_root))

    elif args.command == "validate":
        sys.exit(validate(project_root))


if __name__ == "__main__":
    main()

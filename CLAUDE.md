# CLAUDE.md — Dotfiles Project Instructions

## Project Overview

Enterprise-grade, cross-platform (macOS, Linux, WSL, BSD), cross-shell (bash, zsh, fish, nushell)
dotfiles system with a Single Source of Truth (SSOT) architecture.

## Architecture

```
definitions/*.toml → generators/ (Python) → shells/<shell>/generated/
tools/available/*.toml → lib/hotload/engine.sh → adapters → local/state.json
```

### Key Directories

- `bin/` — CLI entry points (dotfiles, dotfiles-gen, dotfiles-theme, dotfiles-nix)
- `lib/core/` — Low-level primitives (no external deps beyond coreutils)
- `lib/modules/` — High-level orchestration (depends on core/ + tools)
- `lib/hotload/` — Hot-loading engine with adapter pattern
- `definitions/` — TOML source of truth (aliases, env, path, functions, colors, icons)
- `generators/` — Python transpiler (TOML → bash/zsh/fish/nushell)
- `shells/<shell>/` — Shell-specific configs + generated/ output
- `platform/` — Platform-specific provisioning scripts
- `tools/available/` — One TOML descriptor per tool (multi-install strategy)
- `tools/nix/` — Nix multi-environment manager (flakes)
- `config/` — XDG tool configurations (symlinked to ~/.config/)
- `local/` — Machine-specific vault (NEVER committed)
- `tests/` — bats-core unit + integration + Docker e2e

## Code Standards

### Language

- ALL comments, documentation, and commit messages MUST be in English
- Variable names, function names, and identifiers in English

### Documentation Style (Elite Standard)

Every file MUST have a header block with relevant tags:

```bash
#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file lib/core/platform.sh
# @description Cross-platform OS/distro/architecture detection engine
# @class Platform
# @since 1.0.0
# @version 1.0.0
# @see docs/ARCHITECTURE.md
# ═══════════════════════════════════════════════════════════════════════════════
```

For Python files:

```python
"""
@file generators/src/models.py
@description Pydantic data models for SSOT definitions
@since 1.0.0
@version 1.0.0
@see docs/SSOT.md
"""
```

### Supported Tags

- `@file` — Relative path from project root
- `@description` — One-line purpose
- `@class` — OOP class name (even in shell scripts)
- `@type` — Type annotation where applicable
- `@since` — Version when introduced
- `@version` — Current version
- `@see` — Related files or documentation
- `@field` — Class/struct field description
- `@param` — Function parameter (name, type, description)
- `@return` — Return value description
- `@throws` — Error conditions
- `@example` — Usage example
- `@deprecated` — Deprecation notice with alternative
- `@abstract` — Abstract method/class marker
- `@extends` — Inheritance relationship

### Shell Scripts

- Use `#!/usr/bin/env bash` shebang (never `#!/bin/bash`)
- Must pass `shellcheck` without warnings
- Use `set -euo pipefail` in all executable scripts
- Quote all variables: `"${var}"` not `$var`
- Use `local` for function variables
- OOP pattern: prefix functions with class name (e.g., `Platform::detect()`)
- Use `readonly` for constants

### Python (generators/)

- Managed with `uv`
- Type hints on all functions
- Pydantic models for data validation
- Abstract base classes for emitter pattern
- Run `ruff check` and `ruff format` before committing

### TOML (definitions/, tools/)

- Use descriptive inline comments sparingly
- Group related entries with `[section.subsection]`
- Keep arrays on multiple lines when > 3 items

## Installation Priority

Tools are installed using the FIRST compatible method (top = highest priority):

1. `mise` — Cross-platform binary manager (primary: ~63 tools)
2. `uv` — Python tools in isolated envs (~23 tools)
3. `curl` — Static binaries / install scripts
4. `cargo` — Rust tools not in mise
5. `brew` — macOS-only fallback
6. `system` — apt/dnf/pacman last resort

## Hard Dependencies (bootstrap order)

1. bash (≥4.0)
2. curl
3. git
4. jq
5. mise
6. uv
7. python3

## Testing

- Unit tests: `bats-core` in `tests/unit/`
- Integration: `bats-core` in `tests/integration/`
- E2E: Docker multi-distro in `tests/e2e/`
- Generator tests: `pytest` in `generators/tests/`
- Run all: `just test` or `make test`

## DRY Principles

- ONE definition in `definitions/*.toml` → compiled to ALL shells
- ONE tool descriptor in `tools/available/*.toml` → works on ALL platforms
- Platform-specific code ONLY in `platform/` directory
- Shell-specific code ONLY in `shells/<shell>/` (non-generated files)
- Local overrides ONLY in `local/` (gitignored)

## Security

- `local/` is ALWAYS gitignored — contains secrets, SSH keys, overrides
- `local/secrets/` and `local/ssh/` have mode 700
- Never hardcode paths — use `${DOTFILES_DIR}` variable
- Validate all external input in `lib/core/validator.sh`
- Use `age`/`sops` for secret encryption

## Git Workflow

- Conventional commits (enforced by commitizen)
- Branch naming: `feat/`, `fix/`, `refactor/`, `docs/`, `test/`
- PR required for main branch
- CI must pass (shellcheck + tests) before merge

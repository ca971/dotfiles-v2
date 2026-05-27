# CLAUDE.md — Shared AI Agent Instructions
# ═══════════════════════════════════════════════════════════════════════════════
# This file is loaded by Hermes, Claude Code, and other AI agents.
# Contains project-wide rules that apply to ALL agents.
# ═══════════════════════════════════════════════════════════════════════════════

## Project: Dotfiles

Enterprise-grade, cross-platform (macOS, Linux, WSL, BSD), cross-shell (bash, zsh, fish, nushell)
dotfiles system with a Single Source of Truth (SSOT) architecture.

### Architecture
```
definitions/*.toml → generators/ (Python) → shells/<shell>/generated/
skills/available/*.toml → skills/generate.py → skills/generated/<agent>/
tools/available/*.toml → lib/hotload/engine.sh → adapters → local/state.json
```

### Key Rules
- ALL comments, documentation, and commit messages MUST be in English
- Use `#!/usr/bin/env bash` shebang (never `#!/bin/bash`)
- Shell scripts must pass `shellcheck` without warnings
- Python must pass `ruff check && ruff format`
- TOML must pass `taplo format --check`
- Conventional commits (enforced by commitizen): `type(scope): description`
- NEVER commit to `local/` directory (gitignored, contains secrets)

### Testing
- Python: `cd generators && uv run pytest tests/ -v`
- Shell: `bats tests/unit/ tests/integration/`
- Docker E2E: `DOCKER_BUILDKIT=0 docker build -f tests/e2e/Dockerfile.interactive -t dotfiles-test .`
- All: `just test`

### Before committing
- Run `ruff check && ruff format` on Python changes
- Run `shellcheck` on shell changes
- Run `taplo format --check .` on TOML changes
- Run the full test suite
- Use Docker for testing bootstrap behavior changes

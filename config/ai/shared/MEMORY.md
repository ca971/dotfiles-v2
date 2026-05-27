# MEMORY.md — Persistent Context & Project Conventions
# ═══════════════════════════════════════════════════════════════════════════════
# Shared across all AI agents. Contains durable facts about the project,
# environment, and conventions. Updated as the project evolves.
# ═══════════════════════════════════════════════════════════════════════════════

## Project: Dotfiles (~/.dotfiles)

- **Architecture**: SSOT — TOML definitions → Python generators → 4 shell outputs
- **Shells**: bash, zsh, fish, nushell
- **Platforms**: macOS, Linux (Debian/Arch/Fedora), WSL, BSD
- **Tools**: 224 descriptors in `tools/available/`, installed via mise/brew/curl/cargo/system
- **Profiles**: 6 (minimal 24, dev 109, server 44, data 124, devops 143, full 193)
- **Nix envs**: 11 (default, devops, go, node, python, rust, data, security, elixir, zig, ruby)
- **Config**: 25 versioned config directories, all symlinked on install

## Key Conventions

- ALL comments, docs, and commits in English
- Shell: `#!/usr/bin/env bash`, `set -euo pipefail`, OOP naming (`Module::function()`)
- Python: type hints, Pydantic models, ruff format + check
- TOML: validated by taplo, descriptive inline comments
- Git: conventional commits (`type(scope): description`), rebase workflow
- Testing: Docker E2E for bootstrap changes, pytest + bats for everything else

## Environment

- Host: macOS Tahoe 26.5, Apple Silicon (arm64), MacBook Pro M3 Pro
- Docker: Colima (not Docker Desktop), socket at `~/.config/colima/default/docker.sock`
- BuildKit: buildx component missing — always use `DOCKER_BUILDKIT=0`
- Shell: zsh (primary), bash fallback
- Editor: neovim (nightly via mise)

## Project State

- Git: initialized, main branch, ~25 commits
- Coverage: 224/224 tools in profiles, 25/25 config dirs with symlinks
- CI: GitHub Actions (shellcheck, taplo, ruff, hadolint, pytest, bats, docker-e2e)
- Not yet pushed to GitHub (local only)

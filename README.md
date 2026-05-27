# Dotfiles

> Enterprise-grade, cross-platform, cross-shell dotfiles with Single Source of Truth architecture.
> **210 tools · 4 shells · 6 profiles · 100% platform coverage**

[![CI](https://github.com/ca/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/ca/dotfiles/actions/workflows/ci.yml)
![Platforms](https://img.shields.io/badge/platform-macOS%20|%20Linux%20|%20WSL%20|%20BSD-blue)
![Shells](https://img.shields.io/badge/shell-bash%20|%20zsh%20|%20fish%20|%20nushell-green)
![Tools](https://img.shields.io/badge/tools-210-orange)
![Tests](https://img.shields.io/badge/tests-58%20passing-brightgreen)

---

## Quick Start

```bash
# One-liner — installs minimal profile (starship, eza, neovim, fzf, fonts...)
curl -fsSL https://raw.githubusercontent.com/ca/dotfiles/main/install.sh | bash

# With specific profile
curl -fsSL https://raw.githubusercontent.com/ca/dotfiles/main/install.sh | bash -s -- --profile dev

# Preview without installing
curl -fsSL https://raw.githubusercontent.com/ca/dotfiles/main/install.sh | bash -s -- --dry-run
```

After installation, you land in a fully configured shell with **starship prompt**, **aliases**, **modern CLI tools**, and **Nerd Font icons** — instantly.

## What You Get

```bash
# Modern replacements for everyday commands
ls      → eza --icons          # beautiful file listing
cat     → bat                  # syntax-highlighted cat
grep    → rg                   # ripgrep, 10x faster
find    → fd                   # user-friendly find
cd      → zoxide               # smart directory jumper
du      → dust                 # intuitive disk usage
df      → duf                  # pretty disk free
top     → btop                 # gorgeous system monitor
ps      → procs                # human-readable processes
```

## Profiles

| Profile | Tools | Use Case |
|---------|-------|----------|
| `minimal` | 24 | Essential CLI — perfect for servers, VMs, fresh installs |
| `server` | 44 | Headless machines — monitoring, networking, security |
| `dev` | 109 | Developer workstation — languages, linters, formatters, docker |
| `data` | 125 | Data engineering — duckdb, sqlite, miller, visidata |
| `ai` | 122 | AI agents & LLM tools — hermes, claude-code, codex, opencode, ollama |
| `devops` | 144 | Cloud & K8s — kubectl, helm, terraform, awscli, colima |
| `full` | 194 | Everything — devops + data + multimedia + AI tools |

## Daily Usage

```bash
# System
dotfiles doctor               # Health check (9 checks)
dotfiles upgrade              # Pull + regenerate + upgrade tools + doctor
dotfiles update               # Quick pull + regenerate (lighter than upgrade)
dotfiles status               # What's installed vs available

# Tools
dotfiles install <name>       # Install a tool via hot-loading
dotfiles uninstall <name>     # Remove a tool

# Theme
dotfiles-theme minimal        # Clean prompt
dotfiles-theme full           # Rich prompt with icons
dotfiles-theme powerline      # Powerline style

# Nix
dotfiles-nix enter python     # Reproducible dev environment
dotfiles-nix list             # Available environments

# Just (task runner)
just generate                 # Regenerate all shell configs
just test                     # Run all tests
just lint                     # ShellCheck all scripts
```

## Architecture

```
definitions/*.toml     →  generators/ (Python)    →  shells/<shell>/generated/
tools/available/       →  lib/hotload/engine.sh   →  local/state.json
```

**Single Source of Truth** — define aliases, env vars, functions, and tool specs once in TOML. The Python generator compiles them to native syntax for bash, zsh, fish, and nushell.

**Hot-Load Engine** — each tool has a TOML descriptor with prioritized install methods (`mise` → `uv` → `curl` → `cargo` → `brew` → `system`). Tools are installed, tracked, and verified without touching the OS package manager.

## Installation Priority

| Priority | Method | Coverage |
|----------|--------|----------|
| 1 | `mise` | Cross-platform binary manager (~63 tools) |
| 2 | `uv` | Python tools in isolated environments (~23 tools) |
| 3 | `curl` | Static binaries / install scripts |
| 4 | `cargo` | Rust ecosystem |
| 5 | `brew` | macOS Homebrew |
| 6 | `system` | Native package manager (apt/dnf/pacman) |

## Adding a Tool

Create `tools/available/mytool.toml`:

```toml
[meta]
name = "mytool"
description = "What it does"
homepage = "https://example.com"
category = "core"
verify = "mytool --version"

[[install]]
method = "mise"
platforms = ["darwin", "linux", "wsl", "bsd"]
plugin = "mytool"
version = "latest"

[[install]]
method = "brew"
platforms = ["darwin"]
package = "mytool"
```

Add it to a profile in `definitions/profiles.toml`, then run `dotfiles install mytool`.

## Testing

```bash
just test              # All tests (58 emitter + 20 parser + 136 bats)
just test-unit         # bats unit tests
just test-integration  # bats integration tests
just test-generators   # pytest generator tests
just lint              # ShellCheck all scripts
just test-e2e          # Docker multi-distro E2E
```

## Requirements

- bash ≥ 4.0 · curl · git · jq
- mise (auto-installed by bootstrap)
- uv (auto-installed by bootstrap)
- python3

## License

MIT

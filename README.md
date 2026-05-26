# Dotfiles

Enterprise-grade, cross-platform, cross-shell dotfiles with a Single Source of Truth architecture.

## Features

- **Cross-platform**: macOS, Linux (Debian, Arch, Fedora), WSL, BSD
- **Cross-shell**: bash, zsh, fish, nushell — one definition, four outputs
- **SSOT**: TOML definitions compiled to native shell syntax
- **Hot-loading**: Install/uninstall tools without affecting the system
- **Nix environments**: Reproducible dev shells (go, node, python, rust, devops)
- **Starship themes**: Switch between minimal, full (nerd), and powerline
- **Secure vault**: age-encrypted secrets, SSH keys, local overrides

## Quick Start

```bash
# One-liner install
curl -fsSL https://raw.githubusercontent.com/USER/dotfiles/main/install.sh | bash

# Or clone and bootstrap manually
git clone https://github.com/USER/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./bootstrap.sh
```

## Architecture

```
definitions/*.toml  -->  generators/ (Python)  -->  shells/<shell>/generated/
tools/available/*.toml  -->  lib/hotload/engine.sh  -->  local/state.json
```

| Directory | Purpose |
|-----------|---------|
| `bin/` | CLI entry points (`dotfiles`, `dotfiles-gen`, `dotfiles-theme`, `dotfiles-nix`) |
| `definitions/` | SSOT TOML files (aliases, env, functions, path, colors, icons, init) |
| `generators/` | Python transpiler (TOML to bash/zsh/fish/nushell) |
| `shells/` | Shell-specific configs + generated output |
| `lib/core/` | Low-level primitives (platform, logger, validator, fs, net) |
| `lib/hotload/` | Hot-loading engine + installer adapters |
| `tools/available/` | Tool descriptors (one TOML per tool, multi-install strategy) |
| `tools/nix/` | Nix flake environments |
| `config/` | XDG tool configurations (starship, git, tmux, bat, etc.) |
| `platform/` | Platform-specific provisioning scripts |
| `local/` | Machine-specific vault (gitignored, encrypted) |
| `tests/` | bats-core unit + integration + Docker e2e |

## CLI Usage

```bash
# Tool management
dotfiles install bat          # Install a tool
dotfiles uninstall bat        # Remove a tool
dotfiles status               # Show all tools
dotfiles verify               # Check installed tools work

# System
dotfiles doctor               # Health check
dotfiles generate             # Regenerate shell configs from SSOT
dotfiles update               # Git pull + regenerate

# Vault
dotfiles vault-init           # Initialize secure vault
dotfiles vault-keygen         # Generate age encryption key
dotfiles vault-encrypt FILE   # Encrypt a file
dotfiles vault-decrypt FILE   # Decrypt a file

# Theme
dotfiles-theme minimal        # Switch to minimal prompt
dotfiles-theme full           # Switch to full nerd font prompt
dotfiles-theme powerline      # Switch to powerline prompt

# Nix environments
dotfiles-nix list             # List environments
dotfiles-nix enter python     # Enter Python dev shell
dotfiles-nix create elixir    # Create new environment
```

## Installation Priority

Tools use the first compatible method (highest priority first):

| Priority | Method | Scope |
|----------|--------|-------|
| 1 | `mise` | Cross-platform binaries + runtimes (~63 tools) |
| 2 | `uv` | Python tools in isolated envs (~23 tools) |
| 3 | `curl` | Static binaries / install scripts |
| 4 | `cargo` | Rust tools not in mise |
| 5 | `brew` | macOS-only fallback |
| 6 | `system` | apt/dnf/pacman last resort |

## Adding a Tool

Create `tools/available/mytool.toml`:

```toml
[meta]
name = "mytool"
description = "What it does"
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

Then run: `dotfiles install mytool`

## Requirements

- bash >= 4.0
- curl
- git
- jq
- mise (installed by bootstrap)
- uv (installed by bootstrap)
- python3

## Testing

```bash
just test              # All tests
just test-unit         # bats unit tests
just test-integration  # bats integration tests
just test-generators   # pytest generator tests
just lint              # shellcheck
just test-e2e          # Docker multi-distro
```

## License

MIT

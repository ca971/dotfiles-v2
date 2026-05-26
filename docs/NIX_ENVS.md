# Nix Environments

## Overview

Nix provides reproducible, isolated development environments via flakes. Each environment is a self-contained directory with a `flake.nix` and `manifest.toml`.

## Available Environments

| Name | Description | Default |
|------|-------------|---------|
| `default` | Base utilities (coreutils, jq, curl) | enabled |
| `devops` | Terraform, kubectl, helm, awscli, k9s | enabled |
| `go` | Go compiler, gopls, delve, golangci-lint | enabled |
| `node` | Node.js 22, pnpm, typescript, prettier | enabled |
| `python` | Python 3.13, uv, ruff, mypy, ipython | enabled |
| `rust` | rustc, cargo, clippy, rust-analyzer | enabled |
| `data` | sqlite, datasette, duckdb, visidata | disabled |
| `security` | age, sops, gnupg, cosign | disabled |

## CLI Usage

```bash
dotfiles-nix list              # Show all environments
dotfiles-nix enter python      # Enter Python dev shell
dotfiles-nix enter rust        # Enter Rust dev shell
dotfiles-nix enable data       # Enable the data environment
dotfiles-nix disable security  # Disable an environment
dotfiles-nix create elixir     # Create new from template
dotfiles-nix update            # Update all flake.lock files
dotfiles-nix update python     # Update specific env
```

## direnv Integration

In any project directory, create an `.envrc`:

```bash
source_env ~/.dotfiles/tools/nix/hooks/activate.bash
use_nix_env python
```

This automatically activates the Python Nix environment when you `cd` into the directory.

## Creating a New Environment

```bash
dotfiles-nix create myenv
```

This copies `tools/nix/envs/_template/` and updates names. Then edit the flake:

```bash
$EDITOR ~/.dotfiles/tools/nix/envs/myenv/flake.nix
```

Add packages from nixpkgs:

```nix
packages = with pkgs; [
  mypackage
  another-tool
];
```

## Environment Structure

```
tools/nix/envs/<name>/
  manifest.toml    # Metadata (name, description, enabled, packages)
  flake.nix        # Nix flake definition
  flake.lock       # Pinned dependencies (auto-generated)
```

## How It Works

1. Each env is a standalone Nix flake using `nixpkgs-unstable`
2. `nix develop` creates an isolated shell with the declared packages
3. `flake.lock` pins exact versions for reproducibility
4. `dotfiles-nix update` refreshes pins to latest

## Prerequisites

- Nix installed (run `tools/nix/install.sh` or `dotfiles install nix`)
- Flakes enabled (automatic with Determinate Systems installer)
- direnv (optional, for automatic activation)

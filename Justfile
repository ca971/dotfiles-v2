# ═══════════════════════════════════════════════════════════════════════════════
# @file Justfile
# @description Primary task runner for dotfiles management
# @since 1.0.0
# @version 1.0.0
# @see Makefile (fallback)
# ═══════════════════════════════════════════════════════════════════════════════

set dotenv-load := false
set shell := ["bash", "-euo", "pipefail", "-c"]

dotfiles_dir := env_var_or_default("DOTFILES_DIR", "~/.dotfiles")

# ───────────────────────────────────────────────────────────────────────────────
# Default: show available recipes
# ───────────────────────────────────────────────────────────────────────────────
default:
    @just --list --unsorted

# ═══════════════════════════════════════════════════════════════════════════════
# Bootstrap & Install
# ═══════════════════════════════════════════════════════════════════════════════

# Run full bootstrap
bootstrap *args:
    ./bootstrap.sh {{args}}

# Run bootstrap in dry-run mode
dry-run:
    ./bootstrap.sh --dry-run

# Run bootstrap with minimal packages
minimal:
    ./bootstrap.sh --minimal

# ═══════════════════════════════════════════════════════════════════════════════
# Generators (SSOT → Shell)
# ═══════════════════════════════════════════════════════════════════════════════

# Generate shell configs from SSOT definitions
generate:
    cd generators && uv run python -m src.cli generate --all

# Generate for a specific shell (bash, zsh, fish, nushell)
generate-shell shell:
    cd generators && uv run python -m src.cli generate --shell {{shell}}

# Validate SSOT definitions without generating
validate-defs:
    cd generators && uv run python -m src.cli validate

# ═══════════════════════════════════════════════════════════════════════════════
# Tools (Hot-Loading)
# ═══════════════════════════════════════════════════════════════════════════════

# Install a tool by name
install tool:
    ./bin/dotfiles install {{tool}}

# Uninstall a tool by name
uninstall tool:
    ./bin/dotfiles uninstall {{tool}}

# List all available tools
tools-list:
    @find tools/available -name '*.toml' -exec basename {} .toml \; | sort

# List installed tools (from state)
tools-installed:
    @jq -r '.tools | to_entries[] | select(.value.installed == true) | .key' local/state.json 2>/dev/null || echo "No tools installed"

# Show tool status
tools-status:
    ./bin/dotfiles status

# ═══════════════════════════════════════════════════════════════════════════════
# Theme Management
# ═══════════════════════════════════════════════════════════════════════════════

# Switch starship theme (minimal, full, powerline)
theme name:
    ./bin/dotfiles-theme {{name}}

# Show current theme
theme-current:
    @jq -r '.theme // "minimal"' local/state.json

# ═══════════════════════════════════════════════════════════════════════════════
# Nix Environments
# ═══════════════════════════════════════════════════════════════════════════════

# List Nix environments
nix-list:
    ./bin/dotfiles-nix list

# Enter a Nix environment
nix-enter env:
    ./bin/dotfiles-nix enter {{env}}

# Create a new Nix environment from template
nix-create env:
    ./bin/dotfiles-nix create {{env}}

# ═══════════════════════════════════════════════════════════════════════════════
# Testing
# ═══════════════════════════════════════════════════════════════════════════════

# Run all tests
test: test-unit test-integration test-generators

# Run unit tests
test-unit:
    bats tests/unit/

# Run integration tests
test-integration:
    bats tests/integration/

# Run generator tests
test-generators:
    cd generators && uv run pytest tests/ -v

# Run shellcheck on all shell scripts
lint:
    find lib/ bin/ -name '*.sh' -exec shellcheck -x {} +
    shellcheck install.sh bootstrap.sh

# Run e2e tests in Docker
test-e2e:
    cd tests/e2e && docker compose up --build --abort-on-container-exit

# ═══════════════════════════════════════════════════════════════════════════════
# Maintenance
# ═══════════════════════════════════════════════════════════════════════════════

# Run doctor (health check)
doctor:
    ./bin/dotfiles doctor

# Update dotfiles (git pull + regenerate)
update:
    git pull --rebase
    just generate

# Clean generated files
clean:
    rm -rf shells/bash/generated/*
    rm -rf shells/zsh/generated/*
    rm -rf shells/fish/generated/*
    rm -rf shells/nushell/generated/*

# Show platform info
info:
    @source lib/core/platform.sh && Platform::summary
    @source lib/core/shell.sh && ShellDetector::summary

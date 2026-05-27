# ═══════════════════════════════════════════════════════════════════════════════
# @file Makefile
# @description Minimal fallback task runner (for systems without just)
# @since 1.0.0
# @version 1.1.0
# @see Justfile (preferred — use `just` for the full recipe set)
# ═══════════════════════════════════════════════════════════════════════════════

SHELL := /bin/bash
.DEFAULT_GOAL := help
DOTFILES_DIR ?= $(HOME)/.dotfiles

.PHONY: help bootstrap generate test lint

# ═══════════════════════════════════════════════════════════════════════════════
# Help
# ═══════════════════════════════════════════════════════════════════════════════

help: ## Show this help (use `just` for full recipe set)
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ═══════════════════════════════════════════════════════════════════════════════
# Bootstrap
# ═══════════════════════════════════════════════════════════════════════════════

bootstrap: ## Run full bootstrap (default: minimal via install.sh)
	@if [ -f install.sh ]; then \
		./install.sh; \
	else \
		./bootstrap.sh --minimal; \
	fi

# ═══════════════════════════════════════════════════════════════════════════════
# Generators
# ═══════════════════════════════════════════════════════════════════════════════

generate: ## Generate shell configs from SSOT definitions
	cd generators && uv run python -m src.cli generate --all

# ═══════════════════════════════════════════════════════════════════════════════
# Testing
# ═══════════════════════════════════════════════════════════════════════════════

test: ## Run all tests (unit + integration + generators)
	bats tests/unit/
	bats tests/integration/
	cd generators && uv run pytest tests/ -v

# ═══════════════════════════════════════════════════════════════════════════════
# Quality
# ═══════════════════════════════════════════════════════════════════════════════

lint: ## Run shellcheck on all scripts
	find lib/ bin/ -name '*.sh' -exec shellcheck -x {} +
	shellcheck install.sh bootstrap.sh

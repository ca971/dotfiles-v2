# ═══════════════════════════════════════════════════════════════════════════════
# @file Makefile
# @description Fallback task runner (for systems without just)
# @since 1.0.0
# @version 1.0.0
# @see Justfile (preferred)
# ═══════════════════════════════════════════════════════════════════════════════

SHELL := /bin/bash
.DEFAULT_GOAL := help
DOTFILES_DIR ?= $(HOME)/.dotfiles

.PHONY: help bootstrap dry-run minimal generate lint test test-unit test-integration test-generators test-e2e doctor update clean info

# ═══════════════════════════════════════════════════════════════════════════════
# Help
# ═══════════════════════════════════════════════════════════════════════════════

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ═══════════════════════════════════════════════════════════════════════════════
# Bootstrap & Install
# ═══════════════════════════════════════════════════════════════════════════════

bootstrap: ## Run full bootstrap
	./bootstrap.sh

dry-run: ## Run bootstrap in dry-run mode
	./bootstrap.sh --dry-run

minimal: ## Run bootstrap with minimal packages
	./bootstrap.sh --minimal

# ═══════════════════════════════════════════════════════════════════════════════
# Generators
# ═══════════════════════════════════════════════════════════════════════════════

generate: ## Generate shell configs from SSOT definitions
	cd generators && uv run python -m src.cli generate --all

# ═══════════════════════════════════════════════════════════════════════════════
# Testing
# ═══════════════════════════════════════════════════════════════════════════════

test: test-unit test-integration test-generators ## Run all tests

test-unit: ## Run unit tests (bats)
	bats tests/unit/

test-integration: ## Run integration tests (bats)
	bats tests/integration/

test-generators: ## Run generator tests (pytest)
	cd generators && uv run pytest tests/ -v

test-e2e: ## Run e2e tests in Docker
	cd tests/e2e && docker compose up --build --abort-on-container-exit

# ═══════════════════════════════════════════════════════════════════════════════
# Quality
# ═══════════════════════════════════════════════════════════════════════════════

lint: ## Run shellcheck on all scripts
	find lib/ bin/ -name '*.sh' -exec shellcheck -x {} +
	shellcheck install.sh bootstrap.sh

# ═══════════════════════════════════════════════════════════════════════════════
# Maintenance
# ═══════════════════════════════════════════════════════════════════════════════

doctor: ## Run health check
	./bin/dotfiles doctor

update: ## Update dotfiles (pull + regenerate)
	git pull --rebase
	$(MAKE) generate

clean: ## Remove generated files
	rm -rf shells/bash/generated/*
	rm -rf shells/zsh/generated/*
	rm -rf shells/fish/generated/*
	rm -rf shells/nushell/generated/*

info: ## Show platform info
	@bash -c 'source lib/core/platform.sh && Platform::summary'
	@bash -c 'source lib/core/shell.sh && ShellDetector::summary'

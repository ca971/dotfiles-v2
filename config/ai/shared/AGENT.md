# AGENT.md — Agent Capabilities & Tool Configuration
# ═══════════════════════════════════════════════════════════════════════════════
# Shared across all AI agents. Defines available tools, commands, and
# configuration for working on this project.
# ═══════════════════════════════════════════════════════════════════════════════

## Available Commands

### Build & Test
- `just test` — Run all tests (bats + pytest)
- `just test-unit` — Shell unit tests only
- `just test-integration` — Shell integration tests
- `just test-generators` — Python generator tests
- `just lint` — ShellCheck all scripts
- `just generate` — Regenerate shell configs from SSOT
- `just generate-skills` — Regenerate AI agent skills

### Docker (via Colima on macOS)
- `colima start` — Start Docker runtime
- `DOCKER_BUILDKIT=0 docker build -f tests/e2e/Dockerfile.interactive -t dotfiles-test .`
- `docker run --rm dotfiles-test ./bootstrap.sh --minimal --dry-run`

### Dotfiles CLI
- `dotfiles doctor` — Health check (9 checks)
- `dotfiles upgrade` — Pull + regenerate + upgrade tools + health check
- `dotfiles status` — Show installed vs available tools
- `dotfiles install <tool>` — Install a tool via hot-loading
- `dotfiles snapshot create` — Save current state
- `dotfiles snapshot rollback <name>` — Restore previous state

### Git Workflow
- `git switch -c feat/name` — Start feature
- `git commit -m "type(scope): message"` — Conventional commit
- `gh pr create --fill` — Create PR from current branch

## Project-Specific Tools
- `taplo` — TOML formatter and linter
- `shellcheck` — Shell script linter
- `ruff` — Python linter and formatter
- `hadolint` — Dockerfile linter
- `bats` — Bash Automated Testing System
- `mise` — Runtime and tool version manager
- `uv` — Python package and project manager

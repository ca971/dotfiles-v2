<div align="center">

# 🔧 Dotfiles

**Cross-Platform · Cross-Shell · SSOT Architecture · 7 Profiles · 233 Tools**

A meticulously engineered, production-ready dotfiles framework built on Single
Source of Truth principles for maximum consistency and reproducibility across
all platforms, shells, and machine profiles.

<br/>

[![Shell](https://img.shields.io/badge/Shell-ZSH%20·%20Bash%20·%20Fish%20·%20Nushell-green?style=for-the-badge&logo=gnubash&logoColor=white)](#-cross-shell-support)
[![Platform](https://img.shields.io/badge/Platform-macOS%20·%20Linux%20·%20WSL%20·%20BSD-E95420?style=for-the-badge&logo=linux&logoColor=white)](#-cross-platform-support)
[![License](https://img.shields.io/badge/License-MIT-F7DF1E?style=for-the-badge)](./LICENSE)
[![Tools](https://img.shields.io/badge/Tools-233-blue?style=for-the-badge&logo=hackthebox&logoColor=white)](#-integrated-tools)
[![Profiles](https://img.shields.io/badge/Profiles-7-purple?style=for-the-badge&logo=windowsterminal&logoColor=white)](#-profiles)

[![CI](https://img.shields.io/badge/CI-Passing-success?style=flat-square&logo=githubactions&logoColor=white)](../../actions)
[![Tests](https://img.shields.io/badge/Tests-69%20passing-brightgreen?style=flat-square)](./generators/tests)
[![SSOT](https://img.shields.io/badge/SSOT-TOML%20→%204%20Shells-orange?style=flat-square&logo=toml&logoColor=white)](#-ssot-architecture)
[![Coverage](https://img.shields.io/badge/Coverage-100%25-success?style=flat-square)](#-profiles)
[![Maintained](https://img.shields.io/badge/Status-Active-success?style=flat-square)](https://github.com/ca/dotfiles-v2)

<br/>

[Quick Start](#-quick-start) · [Profiles](#-profiles) ·
[Architecture](#-architecture) · [CLI](#-dotfiles-cli) ·
[Tools](#-integrated-tools) · [Testing](#-testing) ·
[Nix](#-nix-environments)

</div>

---

## 📑 Table of Contents

<details>
<summary><strong>Click to expand</strong></summary>

- [✨ Core Philosophy](#-core-philosophy)
- [🚀 Key Features](#-key-features)
- [📦 Requirements](#-requirements)
- [⚡ Quick Start](#-quick-start)
- [📊 Profiles](#-profiles)
- [🔧 Daily Usage](#-daily-usage)
- [📐 Architecture](#-architecture)
- [🎯 SSOT Architecture](#-ssot-architecture)
- [🛠️ Integrated Tools](#-integrated-tools)
- [❄️ Nix Environments](#-nix-environments)
- [🎨 Themes](#-themes)
- [🧪 Testing](#-testing)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

</details>

---

## ✨ Core Philosophy

| Principle             | Description                                                      |
| :-------------------- | :--------------------------------------------------------------- |
| 🎯 **SSOT**           | Define once in TOML, generate for all shells — zero duplication  |
| 🌍 **Cross-Platform** | macOS, Linux, WSL, BSD — auto-detected, auto-configured          |
| 🐚 **Cross-Shell**    | ZSH, Bash, Fish, Nushell — shared config, native syntax          |
| 📊 **Profiles**       | 7 curated profiles from minimal (24 tools) to full (194 tools)   |
| 🔧 **Hot-Load**       | One tool = one TOML descriptor. Automatic install + verification |
| 🔒 **Secure**         | Secrets vault, GPG encryption, SSH hardening, git-signing        |
| 🧩 **Modular**        | Each tool, config, and profile is independent and composable     |
| 📋 **Documented**     | JSDoc-style headers, comprehensive README, inline help           |

---

## 🚀 Key Features

<table>
<tr>
<td width="50%" valign="top">

### 🎯 SSOT Architecture

- **TOML → 4 shells**: aliases, functions, env vars, PATH, keybindings
- Python generators transpile TOML to bash, zsh, fish, nushell
- Change once → regenerate → all shells updated
- 233 tool descriptors with prioritized install methods
- AI agent skills SSOT (TOML → hermes/claude/codex/opencode)

</td>
<td width="50%" valign="top">

### 📊 Smart Profiles

- **7 curated profiles** with inheritance (extends)
- minimal (24) → dev (109) → devops (144) → full (194)
- server (44) for headless machines
- data (125) for data engineering
- ai (122) for AI agents & LLM tools
- One-liner installs minimal by default

</td>
</tr>
<tr>
<td width="50%" valign="top">

### 🔧 Hot-Load Engine

- Priority-based installer: mise → uv → curl → cargo → brew → system
- Automatic verification after install
- Idempotent — run anytime, safe for CI/CD
- `dotfiles sync` for full profile reconciliation
- `dotfiles doctor` health checks (9 checks)

</td>
<td width="50%" valign="top">

### 🐚 Multi-Shell Support

| Shell   | Config                  | Generated         |
| :------ | :---------------------- | :---------------- |
| **ZSH** | `shells/zsh/`           | 7 files (plugins) |
| **Bash**| `shells/bash/`          | 6 files           |
| **Fish**| `shells/fish/`          | 6 files           |
| **Nushell** | `shells/nushell/`   | 6 files (.nu)     |

</td>
</tr>
<tr>
<td width="50%" valign="top">

### 🔐 Security

- `local/` vault (gitignored, 700 perms)
- SSH key management with Keychain integration
- GPG signing + pinentry auto-detect
- `age`/`sops` secret encryption
- `dotfiles vault-init|keygen|encrypt|decrypt`
- Pre-commit hooks: no secrets, no .env

</td>
<td width="50%" valign="top">

### ❄️ Nix Environments

- 11 declarative dev environments (python, go, rust, node, elixir, zig, ruby, devops, data, nix, c)
- Per-environment `manifest.toml`
- `dotfiles-nix enter <env>` for reproducible shells
- Flake-based, locked dependencies

</td>
</tr>
</table>

---

## 🌍 Cross-Platform Support

| Platform           | Status | Package Manager | Module                      |
| :----------------- | :----: | :-------------- | :-------------------------- |
| 🍎 macOS           |   ✅   | Homebrew        | `platform/darwin/brew.sh`   |
| 🐧 Ubuntu / Debian |   ✅   | apt             | `platform/linux/debian.sh`  |
| 🎩 Fedora / RHEL   |   ✅   | dnf             | `platform/linux/fedora.sh`  |
| 🏔️ Arch / Manjaro  |   ✅   | pacman          | `platform/linux/arch.sh`    |
| 🪟 WSL / WSL2      |   ✅   | apt / dnf       | `platform/linux/wsl.sh`     |
| 😈 FreeBSD         |   ✅   | pkg             | `platform/bsd/common.sh`    |

---

## 📦 Requirements

| Dependency                          | Version  | Auto-Installed |
| :---------------------------------- | :------: | :------------: |
| [Bash](https://www.gnu.org/software/bash/) | `≥ 4.0` |      ❌        |
| [cURL](https://curl.se/)            |  latest  |      ❌        |
| [Git](https://git-scm.com/)         | `≥ 2.30` |      ❌        |
| [mise](https://mise.jdx.dev)        |  latest  |      ✅        |
| [uv](https://docs.astral.sh/uv/)    |  latest  |      ✅        |
| [Python](https://python.org)        | `≥ 3.10` |      ✅        |
| [Homebrew](https://brew.sh) (macOS) |  latest  |      ✅        |

> **macOS fresh install note**: Xcode Command Line Tools and Homebrew are
> installed automatically by `install.sh` and `bootstrap.sh`.

---

## ⚡ Quick Start

### One-Liner (recommended)

```bash
# Installs minimal profile (24 essential tools)
curl -fsSL https://raw.githubusercontent.com/ca/dotfiles-v2/main/install.sh | bash
```

You land in a fully configured shell with **starship prompt**, **aliases**,
**modern CLI tools**, and **Nerd Font icons** — instantly.

### With Custom Profile

```bash
curl -fsSL https://raw.githubusercontent.com/ca/dotfiles-v2/main/install.sh | bash -s -- --profile dev
curl -fsSL https://raw.githubusercontent.com/ca/dotfiles-v2/main/install.sh | bash -s -- --profile ai
```

### Dry-Run (preview)

```bash
curl -fsSL https://raw.githubusercontent.com/ca/dotfiles-v2/main/install.sh | bash -s -- --dry-run
```

### Interactive Mode

```bash
curl -fsSL https://raw.githubusercontent.com/ca/dotfiles-v2/main/install.sh | bash -s -- --interactive
```

Choose your shell, profile, and confirm — guided setup wizard.

### Manual Install

```bash
git clone https://github.com/ca/dotfiles-v2.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh --interactive
```

### macOS Power-User Flow

```bash
# 1. Xcode Command Line Tools (auto-detected by install.sh)
xcode-select --install

# 2. One-liner handles the rest:
#    → Homebrew → mise → uv → jq → generators → tools
curl -fsSL https://raw.githubusercontent.com/ca/dotfiles-v2/main/install.sh | bash
```

---

## 📊 Profiles

Profiles use inheritance (`extends`) — each profile builds on its parent.

| Profile  | Tools | Extends  | Use Case |
| :------- | :---: | :------- | :------- |
| `minimal`|   24  | —        | Essential CLI — perfect for servers, VMs, fresh installs |
| `server` |   44  | minimal  | Headless machines — monitoring, networking, security |
| `dev`    |  109  | minimal  | Developer workstation — languages, linters, docker |
| `data`   |  125  | dev      | Data engineering — duckdb, sqlite, miller, visidata |
| `ai`     |  122  | dev      | AI agents & LLM tools — hermes, claude-code, ollama |
| `devops` |  144  | dev      | Cloud & K8s — kubectl, helm, terraform, awscli, colima |
| `full`   |  194  | devops   | Everything — devops + data + multimedia + AI |

```bash
dotfiles sync --profile ai     # Full idempotent install for AI profile
dotfiles status                # What's installed vs available
```

---

## 🔧 Daily Usage

```bash
# System
dotfiles doctor               # Health check (9 checks)
dotfiles upgrade              # Pull + regenerate + upgrade tools + doctor
dotfiles update               # Quick pull + regenerate
dotfiles status               # What's installed vs available
dotfiles sync [--dry-run]     # Full idempotent profile reconciliation
dotfiles defaults             # Apply macOS system defaults (on demand)
dotfiles bench                # Benchmark shell startup time

# Tools
dotfiles install <name>       # Install a tool via hot-loading
dotfiles uninstall <name>     # Remove a tool
dotfiles verify               # Verify installed tools work

# Config
dotfiles config               # Reapply all config symlinks
dotfiles generate             # Regenerate shell configs from SSOT

# AI Agents
dotfiles-ai link              # Symlink AI context files to ~/.hermes/, ~/.claude/
dotfiles-ai status            # Show what's linked

# Themes
dotfiles-theme minimal        # Clean prompt
dotfiles-theme full           # Rich prompt with icons
dotfiles-theme powerline      # Powerline style

# Vault
dotfiles vault-init           # Initialize secrets vault (age encryption)
dotfiles vault-keygen         # Generate age key pair
dotfiles vault-encrypt <f>    # Encrypt a file
dotfiles vault-decrypt <f>    # Decrypt a file

# Snapshots
dotfiles snapshot create      # Save current tool state
dotfiles snapshot list        # List saved snapshots
dotfiles snapshot rollback    # Restore previous state

# Nix
dotfiles-nix enter python     # Reproducible dev environment
dotfiles-nix list             # Available environments
```

---

## 📐 Architecture

```
definitions/*.toml     →  generators/ (Python)    →  shells/<shell>/generated/
tools/available/*.toml →  lib/hotload/engine.sh   →  local/state.json
skills/available/*.toml →  skills/generate.py     →  skills/generated/<agent>/
```

```
~/dotfiles/
├── bin/                            # CLI entry points
│   ├── dotfiles                    # Main CLI (install, doctor, sync, vault...)
│   ├── dotfiles-theme              # Theme switcher (starship + bat + delta)
│   ├── dotfiles-gen                # SSOT generator wrapper
│   ├── dotfiles-nix                # Nix environment manager
│   └── dotfiles-ai                 # AI agent context linker
│
├── definitions/                    # Single Source of Truth (TOML)
│   ├── profiles.toml               # 7 profiles with inheritance
│   ├── aliases.toml                # 68 shell aliases
│   ├── functions.toml              # 17 shell functions
│   ├── env.toml                    # 34 environment variables
│   ├── path.toml                   # 16 PATH entries
│   ├── keybindings.toml            # 15 keybindings
│   ├── init.toml                   # 12 tool initializations
│   ├── plugins.toml                # 10 zsh plugins
│   ├── colors.toml                 # Color palette
│   └── icons.toml                  # Nerd Font icons
│
├── generators/                     # TOML → Shell transpilers
│   ├── src/
│   │   ├── cli.py                  # CLI: generate --all | --shell zsh | skills
│   │   ├── parser.py               # TOML parser with platform filtering
│   │   ├── models.py               # Pydantic data models
│   │   └── emitters/               # Per-shell emitters
│   │       ├── bash.py             # Bash emitter
│   │       ├── zsh.py              # ZSH emitter (+ plugins)
│   │       ├── fish.py             # Fish emitter (abbr, fish_add_path)
│   │       └── nushell.py          # Nushell emitter (def --wrapped, let)
│   └── tests/                      # 69 pytest tests
│
├── shells/                         # Shell-specific configs
│   ├── bash/                       # .bashrc, .bash_profile
│   ├── zsh/                        # .zshrc, .zshenv, completions/
│   ├── fish/                       # config.fish
│   └── nushell/                    # config.nu, env.nu
│   └── */generated/                # Auto-generated (gitignored)
│       ├── aliases.gen.{sh,fish,nu}
│       ├── env.gen.{sh,fish,nu}
│       ├── functions.gen.{sh,fish,nu}
│       ├── init.gen.{sh,fish,nu}
│       ├── keybindings.gen.{sh,fish,nu}
│       ├── path.gen.{sh,fish,nu}
│       └── plugins.gen.sh          # ZSH only
│
├── lib/                            # Core libraries
│   ├── core/                       # Low-level primitives
│   │   ├── logger.sh               # Structured logging (info/warn/error/debug)
│   │   ├── platform.sh             # OS/distro/arch detection
│   │   ├── validator.sh            # Input validation
│   │   ├── fs.sh                   # Filesystem operations (symlink, mkdir)
│   │   ├── shell.sh                # Shell detection
│   │   └── net.sh                  # Network utilities
│   ├── modules/                    # High-level modules
│   │   ├── doctor.sh               # Health check (9 checks)
│   │   ├── snapshot.sh             # State snapshots
│   │   ├── onboarding.sh           # Interactive setup
│   │   └── secrets.sh              # Vault (age encryption)
│   └── hotload/                    # Tool installation engine
│       ├── engine.sh               # install_profile, _resolve_profile_tools
│       └── install.sh              # ToolInstaller, StateManager
│
├── tools/                          # Tool ecosystem
│   ├── available/                  # 233 TOML descriptors (one per tool)
│   │   ├── starship.toml           # Multi-method: mise, brew, system
│   │   ├── neovim.toml             # With config symlink
│   │   └── ...                     # Every tool has a descriptor
│   └── nix/                        # Nix environments
│       └── envs/                   # 11 environments with manifest.toml
│
├── platform/                       # Platform-specific provisioning
│   ├── darwin/
│   │   ├── brew.sh                 # Homebrew install + Brewfile
│   │   ├── defaults.sh             # macOS defaults (on demand)
│   │   └── Brewfile                # macOS-only casks & formulae
│   ├── linux/                      # debian.sh, arch.sh, fedora.sh, wsl.sh
│   └── bsd/                        # common.sh
│
├── config/                         # XDG config templates (versioned)
│   ├── starship/                   # Prompt configs
│   ├── git/                        # .gitconfig, gitignore_global
│   ├── atuin/                      # Shell history
│   ├── bat/                        # Syntax highlighting
│   ├── ghostty/, wezterm/          # Terminal configs
│   ├── nvim/                       # Neovim bootstrap
│   ├── tmux/, zellij/              # Multiplexers
│   └── ...                         # 26 config directories total
│
├── skills/                         # AI agent skills SSOT
│   ├── available/                  # 5 TOML skill definitions
│   └── generate.py                 # Multi-agent emitter (markdown/yaml/toml)
│
├── config/ai/                      # AI agent context files
│   ├── shared/                     # CLAUDE.md, SOUL.md, AGENT.md, MEMORY.md
│   └── <agent>/                    # Per-agent templates
│
├── local/                          # Machine-specific vault (NEVER committed)
│   ├── state.json                  # Tool installation state
│   ├── secrets/                    # Encrypted secrets (age)
│   └── ssh/                        # SSH keys
│
├── tests/                          # Test suites
│   ├── unit/                       # bats unit tests
│   ├── integration/                # bats integration tests
│   └── e2e/                        # Docker multi-distro E2E
│
├── .github/workflows/ci.yml        # CI/CD (8 jobs)
├── bootstrap.sh                    # Universal bootstrap orchestrator
├── install.sh                      # One-liner entry point (curl-pipeable)
├── Justfile                        # Task runner (26 recipes)
├── Makefile                        # Minimal (4 essential recipes)
└── README.md                       # This file
```

---

## 🎯 SSOT Architecture

Define configuration **once** in TOML, generate for **all shells**.

| TOML Source       | Generated Outputs                          | Content                        |
| :---------------- | :----------------------------------------- | :----------------------------- |
| `aliases.toml`    | `aliases.gen.{sh,fish,nu}`                | 68 aliases with descriptions   |
| `functions.toml`  | `functions.gen.{sh,fish,nu}`              | 17 shell functions             |
| `env.toml`        | `env.gen.{sh,fish,nu}`                    | 34 environment variables       |
| `path.toml`       | `path.gen.{sh,fish,nu}`                   | 16 PATH entries                |
| `keybindings.toml`| `keybindings.gen.{sh,fish,nu}`            | 15 keybindings                 |
| `init.toml`       | `init.gen.{sh,fish,nu}`                   | 12 tool initializations        |
| `plugins.toml`    | `plugins.gen.sh`                           | 10 zsh plugins                 |

```bash
# Regenerate all shell configs
dotfiles generate

# Or via Just
just generate
```

---

## 🛠️ Integrated Tools

> 233 tools across 7 profiles. Each tool has a TOML descriptor with prioritized
> install methods. Tools are installed, verified, and tracked by the hot-load
> engine without touching the OS package manager directly.

### Installation Priority

| Priority | Method   | Coverage   | Description |
| :------: | :------- | :--------: | :---------- |
|    1     | `mise`   | ~137 tools | Cross-platform binary manager — primary method |
|    2     | `uv`     |  ~23 tools | Python tools in isolated environments |
|    3     | `curl`   |  ~30 tools | Static binaries / install scripts |
|    4     | `cargo`  |  ~17 tools | Rust ecosystem |
|    5     | `brew`   |  ~20 tools | macOS-only fallback |
|    6     | `system` |   ~6 tools | Native package manager (apt/dnf/pacman) |

### Essential Tools (minimal profile — 24 tools)

| Tool                            | Purpose            | Install |
| :------------------------------ | :----------------- | :------ |
| [starship](https://starship.rs) | Prompt             | mise    |
| [eza](https://eza.rocks)        | Modern `ls`        | mise    |
| [neovim](https://neovim.io)     | Editor             | mise    |
| [atuin](https://atuin.sh)       | Shell history      | mise    |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder | mise    |
| [btop](https://github.com/aristocratos/btop) | System monitor | mise |
| [duf](https://github.com/muesli/duf) | Disk usage     | mise    |
| [mise](https://mise.jdx.dev)    | Runtime manager    | curl    |
| [uv](https://docs.astral.sh/uv) | Python packager    | curl    |
| [taplo](https://taplo.tamasfe.dev) | TOML toolkit   | mise    |
| [yq](https://github.com/mikefarah/yq) | YAML/TOML   | mise    |
| [keychain](https://www.funtoo.org/Keychain) | SSH agent | system |

### Developer Tools (dev profile — 109 tools)

| Category       | Tools |
| :------------- | :---- |
| **Languages**  | python, go, rust (rustup), nodejs, deno, bun, ruby, elixir, erlang, lua (luajit, luarocks) |
| **Linters**    | shellcheck, ruff, biome, stylua, hadolint, typos, cppcheck, rubocop, mypy |
| **Formatters** | black, topiary, pre-commit |
| **Git**        | lazygit, gh, git-delta, git-lfs, commitizen, jj |
| **Docker**     | docker-cli, docker-compose, colima, lima |
| **Shell**      | zsh, bash, fish, nushell, carapace, thefuck |
| **Utils**      | bat, fd, ripgrep, zoxide, jq, direnv, just, dust, procs, navi, tealdeer, lsd, broot, yazi, zellij, fastfetch, sd, hexyl, lychee, grex, tokei, hyperfine, onefetch, ast-grep, vivid, tree-sitter-cli, cmake, silicon, vim, ghostscript |

### DevOps (devops profile — 144 tools, extends dev)

| Category    | Tools |
| :---------- | :---- |
| **K8s**     | kubectl, kubectx, k9s, helm, kustomize, argocd, stern |
| **Cloud**   | awscli, aws-sam-cli, doctl, terraform |
| **Security**| trivy, grype, cosign, syft, sops, gitleaks, git-secrets |
| **Containers** | dive, lazydocker, podman |
| **Network** | rustscan, bore, hurl, curlie, websocat, miniserve |
| **Backup**  | rclone, restic |
| **CI/CD**   | act, ansible, pueue |
| **Nix**     | nix |

### AI Agents (ai profile — 122 tools, extends dev)

| Tool                                                          | Purpose |
| :------------------------------------------------------------ | :------ |
| [hermes-agent](https://hermes-agent.nousresearch.com)         | CLI AI agent |
| [hermes-web-ui](https://github.com/nousresearch/hermes-web-ui) | Web interface |
| [claude-code](https://claude.ai)                              | Anthropic coding agent |
| [codex](https://github.com/openai/codex)                      | OpenAI coding agent |
| [opencode](https://opencode.ai)                               | Open-source coding agent |
| [open-webui](https://openwebui.com)                           | Universal AI interface |
| [continue](https://continue.dev)                              | IDE AI assistant |
| [ollama](https://ollama.com)                                  | Local LLM runtime |
| [aichat](https://github.com/sigoden/aichat)                   | Multi-LLM CLI |
| [llm](https://llm.datasette.io)                               | LLM CLI toolkit |
| [mods](https://github.com/charmbracelet/mods)                 | Pipeable LLM |
| [free-claude-code](https://github.com/robertpiosik/free-claude-code) | Open Claude Code |
| [fabric](https://github.com/danielmiessler/fabric)            | AI pattern framework |

### Adding a Tool

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

[symlinks]
"mytool" = "~/.config/mytool"
```

Add it to a profile in `definitions/profiles.toml`, then:

```bash
dotfiles install mytool
```

---

## ❄️ Nix Environments

11 declarative, reproducible dev environments via Nix Flakes. Each has a
`manifest.toml` defining its toolset.

```bash
dotfiles-nix list              # Available environments
dotfiles-nix enter python      # Enter Python dev shell
dotfiles-nix enter go          # Enter Go dev shell
dotfiles-nix enter devops      # Enter DevOps shell
```

| Environment | Key Tools |
| :---------- | :-------- |
| **python**  | python, ruff, black, mypy, pytest, ipython |
| **go**      | go, gopls, dlv, golangci-lint |
| **rust**    | rustup, rust-analyzer, cargo-audit |
| **node**    | nodejs, bun, pnpm, biome, typescript |
| **elixir**  | elixir, erlang, hex, rebar3 |
| **zig**     | zig, zls |
| **ruby**    | ruby, solargraph, rubocop |
| **devops**  | terraform, kubectl, helm, ansible, awscli |
| **data**    | duckdb, sqlite, miller, visidata |
| **nix**     | nixpkgs-fmt, statix, nil |
| **c**       | gcc, cmake, gdb, valgrind, cppcheck |

---

## 🎨 Themes

Three Starship prompt themes, switchable at runtime:

```bash
dotfiles-theme minimal        # Clean, minimal prompt
dotfiles-theme full           # Rich prompt with icons and git info
dotfiles-theme powerline      # Powerline-style prompt
```

Also configures `bat` (syntax theme) and `delta` (git diff theme) to match.

---

## 🧪 Testing

```bash
just test                     # All tests
just test-unit                # bats unit tests
just test-integration         # bats integration tests
just test-generators          # pytest (69 tests)
just test-e2e                 # Docker multi-distro E2E
just lint                     # ShellCheck + ruff + taplo
```

| Suite         | Framework     | Tests | Description |
| :------------ | :------------ | :---: | :---------- |
| Generators    | pytest        |   69  | Emitter correctness + hotload integrity |
| Unit          | bats-core     |   —   | Core library functions |
| Integration   | bats-core     |   —   | Cross-module workflows |
| E2E           | Docker        |   —   | Bootstrap on Debian (full install) |
| Lint          | shellcheck    |   —   | No warnings |
| Lint          | ruff          |   —   | Python style |
| Lint          | taplo         |   —   | TOML validation |

### CI/CD

8 jobs on every push: shellcheck, bats, pytest, ruff, taplo, hadolint, Docker
E2E, locale check.

---

## 🤝 Contributing

```bash
git checkout -b feat/amazing-feature
# Make changes, following conventions in CLAUDE.md
git commit -m "feat: amazing feature"  # Conventional commits
git push origin feat/amazing-feature
# Open PR
```

| Contribution       | How |
| :----------------- | :-- |
| Add a tool         | Create `tools/available/TOOL.toml` |
| Add to profile     | Edit `definitions/profiles.toml` |
| Add an alias       | Edit `definitions/aliases.toml` |
| Add a platform     | Create `platform/{os}/script.sh` |
| Add a Nix env      | Create `tools/nix/envs/<name>/` |

---

## 📄 License

[MIT](./LICENSE) — free for personal, educational, and commercial use.

---

<div align="center">

**Crafted for power users who live in the terminal.**

[⬆ Back to Top](#-dotfiles)

</div>

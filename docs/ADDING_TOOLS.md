# Adding Tools

## Quick Guide

To add a new tool to the dotfiles system:

1. Create a descriptor: `tools/available/<name>.toml`
2. Install it: `dotfiles install <name>`

## Descriptor Template

```toml
[meta]
name = "toolname"
description = "One-line description of what it does"
homepage = "https://github.com/author/tool"
category = "core"           # core, dev, system, network, etc.
version = "latest"
verify = "toolname --version"

# Install strategies (ordered by priority — first compatible wins)

[[install]]
method = "mise"
platforms = ["darwin", "linux", "wsl", "bsd"]
plugin = "toolname"
version = "latest"

[[install]]
method = "uv"
platforms = ["darwin", "linux", "wsl", "bsd"]
package = "toolname"

[[install]]
method = "curl"
platforms = ["darwin", "linux", "wsl"]
command = "curl -fsSL https://example.com/install.sh | sh"

[[install]]
method = "cargo"
platforms = ["darwin", "linux", "wsl", "bsd"]
crate = "toolname"

[[install]]
method = "brew"
platforms = ["darwin"]
package = "toolname"

[[install]]
method = "system"
platforms = ["linux.debian"]
package = "toolname"

[[install]]
method = "system"
platforms = ["linux.arch"]
package = "toolname"

[[install]]
method = "system"
platforms = ["linux.fedora"]
package = "toolname"

[config]
symlinks = []
dependencies = []
```

## Fields Reference

### [meta]

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Tool identifier (matches filename) |
| `description` | yes | Human-readable description |
| `homepage` | no | Project URL |
| `category` | yes | Grouping category |
| `version` | no | Default version ("latest") |
| `verify` | yes | Command to verify installation works |

### [[install]]

| Field | Required | Description |
|-------|----------|-------------|
| `method` | yes | Adapter: mise, uv, curl, cargo, brew, system |
| `platforms` | yes | List: darwin, linux, wsl, bsd, linux.debian, etc. |
| `plugin` | mise | Mise plugin name |
| `package` | uv/brew/system | Package name |
| `crate` | cargo | Crate name |
| `command` | curl | Full install command |
| `version` | no | Version override for this method |

### [config]

| Field | Description |
|-------|-------------|
| `symlinks` | List of `{src, dst}` for config files |
| `dependencies` | Tools that must be installed first |

## Platform Specifiers

| Specifier | Matches |
|-----------|---------|
| `darwin` | macOS |
| `linux` | Any Linux |
| `linux.debian` | Debian, Ubuntu, Mint, Pop!_OS |
| `linux.arch` | Arch, Manjaro, EndeavourOS |
| `linux.fedora` | Fedora, RHEL, CentOS, Rocky |
| `wsl` | Windows Subsystem for Linux |
| `bsd` | FreeBSD, OpenBSD, NetBSD |

## Adding a Shell Init

If your tool needs shell initialization (like `eval "$(tool init bash)"`), add it to `definitions/init.toml`:

```toml
[init.toolname]
description = "What the init does"
priority = 50              # See docs/ARCHITECTURE.md for ranges
verify = "toolname"
bash = 'eval "$(toolname init bash)"'
zsh = 'eval "$(toolname init zsh)"'
fish = "toolname init fish | source"
nushell = ""
```

Then regenerate: `dotfiles generate`

## Adding a Config

If the tool has configuration files:

1. Create `config/toolname/` with the config files
2. Add symlink in the descriptor: `symlinks = [{src = "config/toolname", dst = "~/.config/toolname"}]`
3. The bootstrap will symlink it automatically

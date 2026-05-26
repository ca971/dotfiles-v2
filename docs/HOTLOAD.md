# Hot-Loading Engine

## Overview

The hot-loading engine allows installing, uninstalling, and managing tools dynamically without affecting the rest of the system. Each tool is described by a single TOML file with multiple install strategies.

## Tool Descriptor Format

Each tool has one file at `tools/available/<name>.toml`:

```toml
[meta]
name = "bat"
description = "Cat clone with syntax highlighting"
homepage = "https://github.com/sharkdp/bat"
category = "core"
verify = "bat --version"

[[install]]
method = "mise"
platforms = ["darwin", "linux", "wsl", "bsd"]
plugin = "bat"
version = "latest"

[[install]]
method = "cargo"
platforms = ["darwin", "linux", "wsl", "bsd"]
crate = "bat"

[[install]]
method = "brew"
platforms = ["darwin"]
package = "bat"

[[install]]
method = "system"
platforms = ["linux.debian"]
package = "bat"

[config]
symlinks = [{ src = "config/bat", dst = "~/.config/bat" }]
dependencies = []
```

## Resolution Algorithm

```
For each tool:
  1. Read tools/available/<tool>.toml
  2. Parse [[install]] entries (ordered by priority in file)
  3. For each entry:
     a. Check platform matches current system
     b. Check adapter backend is available
     c. If both match -> use this method
  4. Execute install via the matching adapter
  5. Verify with meta.verify command
  6. Record in local/state.json
```

## Adapters

| Adapter | Command | Priority |
|---------|---------|----------|
| `mise` | `mise install <plugin>@<version>` | 1 |
| `uv` | `uv tool install <package>` | 2 |
| `curl` | Custom command execution | 3 |
| `cargo` | `cargo install <crate>` | 4 |
| `brew` | `brew install <package>` | 5 |
| `system` | apt/dnf/pacman/apk dispatch | 6 |
| `nix` | `nix profile install nixpkgs#<pkg>` | - |

## State Management

Installation state is persisted in `local/state.json`:

```json
{
  "version": 1,
  "tools": {
    "bat": {
      "installed": true,
      "method": "mise",
      "version": "0.24.0",
      "installed_at": "2024-01-15T10:30:00Z"
    }
  },
  "theme": "full"
}
```

## Commands

```bash
dotfiles install <tool>     # Install using best available method
dotfiles uninstall <tool>   # Remove (uses the method from state)
dotfiles status             # Show all tools and their status
dotfiles verify             # Check all installed tools still work
```

## Adding a New Adapter

1. Create `lib/hotload/adapters/newbackend.sh`
2. Implement: `is_available`, `install`, `uninstall`, `is_installed`
3. Source it in `lib/hotload/engine.sh`
4. Add case in `lib/hotload/install.sh` resolution logic

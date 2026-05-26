# Single Source of Truth (SSOT)

## Overview

All shell configuration is defined once in `definitions/*.toml` and compiled to native syntax for each supported shell by the Python generator.

## Definition Files

| File | Content |
|------|---------|
| `aliases.toml` | All aliases (grouped by category) |
| `functions.toml` | Shell utility functions |
| `env.toml` | Environment variables |
| `path.toml` | PATH entries (ordered, conditional) |
| `colors.toml` | Color palette (Catppuccin Mocha) |
| `icons.toml` | Nerd Font icon mappings |
| `highlights.toml` | Syntax highlighting styles |
| `keybindings.toml` | Shell keybindings |
| `completions.toml` | Custom completion definitions |
| `init.toml` | Tool shell initializations (priority-ordered) |
| `plugins.toml` | Zsh plugins (zinit, turbo mode) |

## Alias Format

```toml
[aliases.category]
name = { command = "...", description = "...", requires = "tool" }
```

- `command` — The command to alias to
- `description` — Human-readable (used in docs/completions)
- `requires` — Optional tool dependency
- `platforms` — Optional platform restriction

## Function Format

```toml
[functions.name]
description = "What it does"
body = '''
POSIX-compatible shell code
'''
requires = ["tool1", "tool2"]
```

## Environment Variable Format

```toml
[env.group]
VAR_NAME = { value = "...", description = "...", condition = "command -v tool" }
```

- `condition` — Only set if this command succeeds
- `platforms` — Only set on these platforms

## PATH Format

```toml
[[path]]
path = "$HOME/.local/bin"
description = "User local binaries"
condition = "$HOME/.local/bin"   # Only add if exists
prepend = true                   # Prepend (high priority) vs append
platforms = ["darwin"]           # Platform restriction
```

## Init Format

```toml
[init.tool_name]
description = "What the tool does"
priority = 40                    # Lower = loads first
verify = "tool_name"            # Command to check availability
bash = 'eval "$(tool init bash)"'
zsh = 'eval "$(tool init zsh)"'
fish = "tool init fish | source"
nushell = ""
```

## Generation

```bash
dotfiles-gen generate --all      # All shells
dotfiles-gen generate --shell zsh  # Single shell
dotfiles-gen validate            # Check definitions without generating
```

## Output

Generated files are placed in `shells/<shell>/generated/` and gitignored:

- `aliases.gen.sh` (or `.fish`)
- `functions.gen.sh`
- `env.gen.sh`
- `path.gen.sh`
- `keybindings.gen.sh`
- `init.gen.sh`
- `plugins.gen.sh` (zsh only)

## Shell Syntax Mapping

| Concept | bash/zsh | fish | nushell |
|---------|----------|------|---------|
| Alias | `alias x='cmd'` | `abbr -a x 'cmd'` | `alias x = cmd` |
| Export | `export X="v"` | `set -gx X "v"` | `$env.X = "v"` |
| PATH prepend | `PATH="x:$PATH"` | `fish_add_path --prepend x` | `$env.PATH \| prepend x` |
| Availability | `command -v x` | `command -sq x` | `which x \| is-not-empty` |
| Function | `f() { ... }` | `function f ... end` | `def f [] { ... }` |

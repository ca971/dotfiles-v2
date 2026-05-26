# Architecture

## Design Principles

1. **DRY** — One definition, compiled to all targets
2. **Cross-platform** — macOS, Linux (Debian/Arch/Fedora), WSL, BSD
3. **Cross-shell** — bash, zsh, fish, nushell from the same source
4. **Hot-loadable** — Add/remove tools without breaking the system
5. **Secure** — Secrets encrypted, permissions enforced, vault gitignored
6. **Testable** — Every layer has automated tests

## Data Flow

```
definitions/*.toml
       |
       v
generators/ (Python: parse -> validate -> emit)
       |
       |---> shells/bash/generated/
       |---> shells/zsh/generated/
       |---> shells/fish/generated/
       |---> shells/nushell/generated/

tools/available/*.toml
       |
       v
lib/hotload/engine.sh
       |
       |---> lib/hotload/adapters/mise.sh   (priority 1)
       |---> lib/hotload/adapters/uv.sh     (priority 2)
       |---> lib/hotload/adapters/curl.sh   (priority 3)
       |---> lib/hotload/adapters/cargo.sh  (priority 4)
       |---> lib/hotload/adapters/brew.sh   (priority 5)
       |---> lib/hotload/adapters/system.sh (priority 6)
       |
       v
local/state.json
```

## Shell Loading Order

### Zsh (.zshrc)

1. Environment variables (env.gen.sh)
2. PATH construction (path.gen.sh)
3. Aliases (aliases.gen.sh)
4. Functions (functions.gen.sh)
5. Keybindings (keybindings.gen.sh)
6. Plugins via zinit (plugins.gen.sh)
7. Tool initializations — priority ordered (init.gen.sh)
8. Completion system
9. Local overrides (local/shell/zsh.local)

### Init Priority System

Tools requiring shell initialization are ordered by priority in `definitions/init.toml`:

```
Priority 10-19 : Core (mise, direnv)
Priority 20-29 : Navigation (zoxide)
Priority 30-39 : Completions (carapace, fzf)
Priority 40-49 : History (atuin — overrides fzf ctrl+r)
Priority 50-59 : UI/Prompt (starship)
Priority 60-69 : Helpers (thefuck)
Priority 70-79 : File managers (broot, navi)
Priority 80-89 : Security (keychain)
Priority 90-99 : Misc (vivid)
```

## Library Layers

### lib/core/ (no external dependencies)

- `platform.sh` — OS/distro/arch detection
- `shell.sh` — Shell name/version detection
- `logger.sh` — Structured logging with levels
- `validator.sh` — Input sanitization
- `fs.sh` — Safe filesystem operations
- `net.sh` — Download with retry/checksum
- `registry.sh` — Service locator pattern

### lib/modules/ (depends on core + tools)

- `bootstrap.sh` — Full system provisioning
- `secrets.sh` — Vault management (age/sops)
- `symlink.sh` — XDG config symlinks
- `doctor.sh` — Health diagnostics
- `theme.sh` — Starship theme management

### lib/hotload/ (tool lifecycle)

- `engine.sh` — Orchestrator
- `state.sh` — JSON state persistence (jq)
- `install.sh` — Method resolution + dispatch
- `uninstall.sh` — Reverse dispatch
- `adapters/*.sh` — Backend implementations

## OOP Convention

Shell scripts use a namespace pattern simulating classes:

```bash
ClassName::method_name() {
    local param="${1:?Required}"
    # implementation
}
```

Python code uses proper classes with abstract base classes and Pydantic models.

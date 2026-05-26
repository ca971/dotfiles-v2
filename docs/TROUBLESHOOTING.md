# Troubleshooting

## Common Issues

### Shell doesn't load aliases/functions

**Symptom**: After install, aliases like `ls` don't use `eza`.

**Fix**: Regenerate and reload:
```bash
dotfiles generate
exec $SHELL
```

### "command not found: taplo" during install

**Symptom**: Hot-loading fails because taplo isn't available for TOML parsing.

**Fix**: taplo is needed for the hot-loading engine to parse tool descriptors:
```bash
mise install taplo@latest
mise use --global taplo@latest
```

### Permission denied on local/secrets

**Symptom**: Scripts fail when accessing the vault.

**Fix**:
```bash
dotfiles vault-init
```
This resets all vault permissions to 700.

### Generated files are empty

**Symptom**: `shells/<shell>/generated/` has empty files.

**Fix**: Ensure the generator dependencies are installed:
```bash
cd ~/.dotfiles/generators && uv sync
dotfiles generate
```

### atuin doesn't override ctrl+r

**Symptom**: ctrl+r opens fzf history instead of atuin.

**Fix**: Check init priorities in `definitions/init.toml`. atuin must have a higher priority number than fzf (loaded later = overrides):
```toml
[init.fzf]
priority = 35

[init.atuin]
priority = 40    # Loaded AFTER fzf, overrides ctrl+r
```

Regenerate: `dotfiles generate`

### Nix environment won't enter

**Symptom**: `dotfiles-nix enter python` fails.

**Fix**:
1. Check Nix is installed: `nix --version`
2. If not: `bash ~/.dotfiles/tools/nix/install.sh`
3. Restart shell
4. Check flakes are enabled: `nix flake --help`

### Bootstrap fails on fresh system

**Symptom**: `install.sh` fails early.

**Fix**: Ensure minimum requirements:
```bash
# Must have: bash >= 4.0, curl, git
bash --version
curl --version
git --version
```

On old macOS with bash 3.x:
```bash
# Install newer bash first
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install bash
```

### state.json is corrupt

**Symptom**: `dotfiles status` shows errors.

**Fix**: Reset state:
```bash
echo '{"version":1,"tools":{},"nix_envs":{},"theme":"minimal"}' > ~/.dotfiles/local/state.json
```

### zinit plugins not loading

**Symptom**: No syntax highlighting or autosuggestions in zsh.

**Fix**:
1. Check zinit is installed: `ls ~/.local/share/zinit/`
2. If missing, it auto-installs on next shell start
3. Force reinstall: `rm -rf ~/.local/share/zinit && exec zsh`

## Diagnostic Commands

```bash
dotfiles doctor              # Full health check
source lib/core/platform.sh && Platform::summary   # Platform info
source lib/core/shell.sh && ShellDetector::summary  # Shell info
dotfiles status              # Tool installation state
dotfiles-nix list            # Nix environments
dotfiles-theme               # Current theme
```

## Getting Help

1. Run `dotfiles doctor` first
2. Check this file
3. Look at `docs/ARCHITECTURE.md` for system overview
4. Check generated files: `ls shells/<your-shell>/generated/`
5. Verify state: `cat local/state.json | jq .`

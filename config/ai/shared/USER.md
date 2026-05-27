# USER.md — User Profile & Preferences
# ═══════════════════════════════════════════════════════════════════════════════
# Shared across all AI agents. Describes who the user is and how they prefer
# to work. Personal details stay in local/ai/USER.md (gitignored).
# ═══════════════════════════════════════════════════════════════════════════════

## Communication

- **Language**: French (respond in French unless technical terms)
- **Tone**: Professional but friendly, no excessive emojis
- **Level**: Technical — assume deep CLI/Linux/macOS knowledge

## Preferences

- **Approval**: Prefer showing diffs before making changes. Ask for confirmation on
  destructive operations (rm, sudo, Docker cleanup).
- **Testing**: Always test in Docker containers before deploying to real system.
  Dry-run mode preferred for any system-changing operation.
- **Commits**: Conventional commits, no `--no-verify` bypasses unless necessary.
- **Documentation**: Inline comments in English, header blocks on new files.

## Environment

- **Home**: `/Users/ca`
- **Editor**: neovim
- **Dotfiles**: Active at `~/dotfiles` (without dot), developing at `~/.dotfiles`
- **Shell**: zsh with starship prompt
- **Terminal**: Ghostty (preferred), WezTerm (fallback)
- **Font**: JetBrainsMono Nerd Font Mono

## What I Care About

1. Reliability — the system must work after a fresh install
2. Automation — manual steps are bugs waiting to happen
3. Consistency — everything follows the same conventions
4. Performance — shell startup under 50ms
5. Portability — works on macOS, Linux, WSL, BSD

## Pet Peeves

- Hardcoded paths instead of variables
- Duplicated logic (DRY violations)
- Unquoted shell variables
- Commands that don't work in dry-run mode
- "It works on my machine" without Docker verification

# ═══════════════════════════════════════════════════════════════════════════════
# @file shells/fish/config.fish
# @description Fish interactive shell configuration
# @since 1.0.0
# @version 1.0.0
# @see docs/ARCHITECTURE.md
#
# Loading order:
#   1. Environment (PATH, exports)
#   2. Generated configs (from SSOT definitions)
#   3. Tool integrations (mise, atuin, starship, etc.)
#   4. Local overrides
# ═══════════════════════════════════════════════════════════════════════════════

# Exit early for non-interactive
if not status is-interactive
    return
end

# ───────────────────────────────────────────────────────────────────────────────
# Core variables
# ───────────────────────────────────────────────────────────────────────────────
set -gx DOTFILES_DIR (set -q DOTFILES_DIR; and echo $DOTFILES_DIR; or echo "$HOME/.dotfiles")
set -l FISH_GEN_DIR "$DOTFILES_DIR/shells/fish/generated"

# ───────────────────────────────────────────────────────────────────────────────
# Fish options
# ───────────────────────────────────────────────────────────────────────────────
set -g fish_greeting ""
set -g fish_autosuggestion_enabled 1

# ───────────────────────────────────────────────────────────────────────────────
# Source generated configs (SSOT → fish)
# ORDER MATTERS: env/path first, then aliases/functions, then init (tool hooks)
# ───────────────────────────────────────────────────────────────────────────────
function _fish_source_if_exists
    test -f $argv[1]; and source $argv[1]
end

_fish_source_if_exists "$FISH_GEN_DIR/env.gen.fish"
_fish_source_if_exists "$FISH_GEN_DIR/path.gen.fish"
_fish_source_if_exists "$FISH_GEN_DIR/aliases.gen.fish"
_fish_source_if_exists "$FISH_GEN_DIR/functions.gen.fish"
_fish_source_if_exists "$FISH_GEN_DIR/keybindings.gen.fish"
_fish_source_if_exists "$FISH_GEN_DIR/init.gen.fish"
functions -e _fish_source_if_exists

# ───────────────────────────────────────────────────────────────────────────────
# Custom functions directory
# ───────────────────────────────────────────────────────────────────────────────
if test -d "$DOTFILES_DIR/shells/fish/functions"
    set -p fish_function_path "$DOTFILES_DIR/shells/fish/functions"
end

# ───────────────────────────────────────────────────────────────────────────────
# conf.d (additional config fragments)
# ───────────────────────────────────────────────────────────────────────────────
if test -d "$DOTFILES_DIR/shells/fish/conf.d"
    for f in $DOTFILES_DIR/shells/fish/conf.d/*.fish
        if test -f "$f"
            source "$f"
        end
    end
end


# ───────────────────────────────────────────────────────────────────────────────
# Local overrides (machine-specific, gitignored)
# ───────────────────────────────────────────────────────────────────────────────
if test -f "$DOTFILES_DIR/local/shell/fish.local"
    source "$DOTFILES_DIR/local/shell/fish.local"
end

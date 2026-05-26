# ═══════════════════════════════════════════════════════════════════════════════
# @file tools/nix/hooks/activate.fish
# @description Fish hook for Nix environment activation
# @since 1.0.0
# @version 1.0.0
#
# Usage: nix_env_enter python
# ═══════════════════════════════════════════════════════════════════════════════

function nix_env_enter
    set -l env_name $argv[1]
    set -l env_dir "$DOTFILES_DIR/tools/nix/envs/$env_name"

    if not test -d "$env_dir"
        echo "Nix environment not found: $env_name" >&2
        return 1
    end

    echo "Entering nix env: $env_name"
    nix develop "$env_dir" --command fish
end

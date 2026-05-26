# ═══════════════════════════════════════════════════════════════════════════════
# @file tools/nix/hooks/activate.nu
# @description Nushell hook for Nix environment activation
# @since 1.0.0
# @version 1.0.0
#
# Usage: nix-env-enter python
# ═══════════════════════════════════════════════════════════════════════════════

def nix-env-enter [env_name: string] {
    let env_dir = ($env.DOTFILES_DIR | path join "tools" "nix" "envs" $env_name)

    if not ($env_dir | path exists) {
        error make {msg: $"Nix environment not found: ($env_name)"}
    }

    print $"Entering nix env: ($env_name)"
    ^nix develop $env_dir --command nu
}

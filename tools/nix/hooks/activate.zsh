#!/usr/bin/env zsh
# ═══════════════════════════════════════════════════════════════════════════════
# @file tools/nix/hooks/activate.zsh
# @description Zsh hook for Nix environment activation (same as bash for direnv)
# @since 1.0.0
# @version 1.0.0
# ═══════════════════════════════════════════════════════════════════════════════

# direnv uses the same hook format for bash/zsh
source "${0:A:h}/activate.bash"

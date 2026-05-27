# ═══════════════════════════════════════════════════════════════════════════════
# @file shells/nushell/env.nu
# @description Nushell environment configuration (loaded before config.nu)
# @since 1.0.0
# @version 1.0.0
# @see shells/nushell/config.nu
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
# Core variables
# ───────────────────────────────────────────────────────────────────────────────
$env.DOTFILES_DIR = ($env.DOTFILES_DIR? | default ($env.HOME | path join ".dotfiles"))
let gen_dir = ($env.DOTFILES_DIR | path join "shells" "nushell" "generated")

# ───────────────────────────────────────────────────────────────────────────────
# XDG Base Directories
# ───────────────────────────────────────────────────────────────────────────────
$env.XDG_CONFIG_HOME = ($env.XDG_CONFIG_HOME? | default ($env.HOME | path join ".config"))
$env.XDG_DATA_HOME = ($env.XDG_DATA_HOME? | default ($env.HOME | path join ".local" "share"))
$env.XDG_STATE_HOME = ($env.XDG_STATE_HOME? | default ($env.HOME | path join ".local" "state"))
$env.XDG_CACHE_HOME = ($env.XDG_CACHE_HOME? | default ($env.HOME | path join ".cache"))
$env.XDG_BIN_HOME = ($env.XDG_BIN_HOME? | default ($env.HOME | path join ".local" "bin"))

# ───────────────────────────────────────────────────────────────────────────────
# Editor & Pager
# ───────────────────────────────────────────────────────────────────────────────
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.PAGER = "less"

# ───────────────────────────────────────────────────────────────────────────────
# PATH construction
# ───────────────────────────────────────────────────────────────────────────────
$env.PATH = ($env.PATH | split row (char esep))

# Prepend high-priority paths
let local_bin = ($env.HOME | path join ".local" "bin")
if ($local_bin | path exists) { $env.PATH = ($env.PATH | prepend $local_bin) }

let dotfiles_bin = ($env.DOTFILES_DIR | path join "bin")
if ($dotfiles_bin | path exists) { $env.PATH = ($env.PATH | prepend $dotfiles_bin) }

# Homebrew (macOS)
let brew_path = "/opt/homebrew/bin"
if ($brew_path | path exists) { $env.PATH = ($env.PATH | prepend $brew_path) }

# ───────────────────────────────────────────────────────────────────────────────
# Source generated configs (SSOT → nushell)
# ───────────────────────────────────────────────────────────────────────────────
let gen_env = ($gen_dir | path join "env.gen.nu")
if ($gen_env | path exists) { source $gen_env }

let gen_path = ($gen_dir | path join "path.gen.nu")
if ($gen_path | path exists) { source $gen_path }

# ───────────────────────────────────────────────────────────────────────────────
# Tool integrations (env phase)
# ───────────────────────────────────────────────────────────────────────────────

# Starship prompt
$env.STARSHIP_CONFIG = ($env.XDG_CONFIG_HOME | path join "starship" "base.toml")

# mise
if (which mise | is-not-empty) {
    $env.MISE_SHELL = "nu"
}

# ═══════════════════════════════════════════════════════════════════════════════
# @file shells/nushell/config.nu
# @description Nushell interactive configuration
# @since 1.0.0
# @version 1.0.0
# @see shells/nushell/env.nu
#
# Loading order:
#   1. Generated aliases (from SSOT)
#   2. Shell settings
#   3. Tool integrations
#   4. Keybindings
#   5. Local overrides
# ═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
# Source generated configs (SSOT → nushell)
# ───────────────────────────────────────────────────────────────────────────────
# Source generated configs (SSOT → nushell)
# nushell 0.113+ requires source paths to be literals (not let variables)
# ───────────────────────────────────────────────────────────────────────────────
let gen_dir = ($env.DOTFILES_DIR | path join "shells" "nushell" "generated")

try { source ($env.DOTFILES_DIR | path join "shells" "nushell" "generated" "aliases.gen.nu") }
try { source ($env.DOTFILES_DIR | path join "shells" "nushell" "generated" "functions.gen.nu") }
try { source ($env.DOTFILES_DIR | path join "shells" "nushell" "generated" "init.gen.nu") }

# ───────────────────────────────────────────────────────────────────────────────
# Shell settings
# ───────────────────────────────────────────────────────────────────────────────
$env.config = {
    show_banner: false

    ls: {
        use_ls_colors: true
        clickable_links: true
    }

    rm: {
        always_trash: true
    }

    table: {
        mode: rounded
        index_mode: always
        show_empty: true
        padding: { left: 1, right: 1 }
        trim: {
            methodology: wrapping
            wrapping_try_keep_words: true
        }
    }

    history: {
        max_size: 50000
        sync_on_enter: true
        file_format: "sqlite"
        isolation: false
    }

    completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
    }

    cursor_shape: {
        emacs: line
        vi_insert: line
        vi_normal: block
    }

    color_config: {
        leading_trailing_space_bg: { attr: n }
        separator: white
        header: green_bold
        empty: blue
        row_index: green_bold
        bool: light_cyan
        int: white
        float: white
        string: white
        filesize: cyan
        duration: white
        date: purple
        range: white
        nothing: white
        binary: white
        cell_path: white
    }

    footer_mode: 25
    float_precision: 2
    use_ansi_coloring: true
    edit_mode: emacs
    shell_integration: true
    highlight_resolved_externals: true
}

# ───────────────────────────────────────────────────────────────────────────────
# Tool integrations
# ───────────────────────────────────────────────────────────────────────────────

# mise (runtime manager)
if (which mise | is-not-empty) {
    # mise activate generates hooks for nushell
}

# zoxide (smart cd)
if (which zoxide | is-not-empty) {
    # zoxide init nushell generates __zoxide_z and related commands
}

# starship (prompt)
if (which starship | is-not-empty) {
    # Starship is configured via STARSHIP_CONFIG env var set in env.nu
}

# carapace (multi-shell completions)
if (which carapace | is-not-empty) {
    $env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'
}

# ───────────────────────────────────────────────────────────────────────────────
# Custom modules
# ───────────────────────────────────────────────────────────────────────────────
let modules_dir = ($env.DOTFILES_DIR | path join "shells" "nushell" "modules")
# Modules are loaded via `use` statements as needed

# ───────────────────────────────────────────────────────────────────────────────
# Local overrides (machine-specific, gitignored)
# ───────────────────────────────────────────────────────────────────────────────
try { source ($env.DOTFILES_DIR | path join "local" "shell" "nushell.local") }

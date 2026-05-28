--- @module "events.cheat_sheet""
--- @description Custom event that opens a scrollable tab displaying
--- all available keybindings with Nerd Font icons.
--- Uses native WezTerm rendering for perfect icon display.
--- Triggered via LEADER + ? or Cmd/Alt + ? or command palette.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Icons = require("core.icons")
local Settings = require("core.settings")

local M = {}

--- Build the cheat sheet as an array of WezTerm FormatItem elements.
--- This uses wezterm.format() for pixel-perfect icon rendering.
--- @param wezterm table The wezterm module
--- @return string content The formatted text with ANSI colors
local function build_cheat_sheet(wezterm)
  local is_macos = package.config:sub(1, 1) ~= "\\"
  local super = is_macos and "Cmd" or "Alt"
  local leader = Settings.get("keys.leader", { key = "a", mods = "CTRL" })
  local leader_str = leader.mods .. "+" .. leader.key

  -- ANSI color codes
  local reset = "\x1b[0m"
  local bold = "\x1b[1m"
  local dim = "\x1b[2m"
  local italic = "\x1b[3m"
  local blue = "\x1b[38;5;111m"
  local green = "\x1b[38;5;114m"
  local yellow = "\x1b[38;5;222m"
  local magenta = "\x1b[38;5;176m"
  local cyan = "\x1b[38;5;116m"
  local orange = "\x1b[38;5;209m"
  local pink = "\x1b[38;5;211m"
  local red = "\x1b[38;5;203m"
  local gray = "\x1b[38;5;245m"
  local white = "\x1b[38;5;255m"

  local function header(icon, text, color)
    color = color or blue
    return string.format(
      "\n  %s%s%s  %s%s%s%s\n  %s%s%s\n",
      color,
      bold,
      icon,
      white,
      bold,
      text,
      reset,
      dim,
      string.rep("─", 68),
      reset
    )
  end

  local function row(keys, desc)
    return string.format("  %s%-26s%s %s%s%s", yellow, keys, reset, gray, desc, reset)
  end

  local function subrow(keys, desc)
    return string.format("  %s%-26s%s %s%s%s", cyan, keys, reset, gray, desc, reset)
  end

  local function info(text)
    return string.format("  %s%s%s", dim, text, reset)
  end

  local lines = {
    "",
    string.format("  %s%s%s", bold .. magenta, string.rep("━", 68), reset),
    "",
    string.format(
      "  %s%s  %sWEZTERM ENTERPRISE%s  %s─%s  %sCOMPLETE CHEAT SHEET%s",
      bold .. magenta,
      Icons.ui("rocket"),
      white .. bold,
      reset,
      dim,
      reset,
      italic .. gray,
      reset
    ),
    "",
    string.format("  %s%s%s", bold .. magenta, string.rep("━", 68), reset),
    "",
    row("Leader key", leader_str),
    row("Super key", super .. " (platform-aware)"),
    row("Config", "~/.config/wezterm/"),
    row("Local overrides", "~/.config/wezterm/local/"),

    -- ══ TAB MANAGEMENT ══
    header(Icons.ui("plus"), "TAB MANAGEMENT", blue),
    row(super .. " + t", "New tab"),
    row(super .. " + w", "Close tab (confirm)"),
    row(super .. " + {", "Previous tab"),
    row(super .. " + }", "Next tab"),
    row(super .. " + Shift + {", "Move tab left"),
    row(super .. " + Shift + }", "Move tab right"),
    row(super .. " + 1-8", "Jump to tab N"),
    row(super .. " + 9", "Jump to last tab"),

    -- ══ PANE MANAGEMENT ══
    header(Icons.ui("gear"), "PANE MANAGEMENT", green),
    row(super .. " + d", "Split pane horizontal"),
    row(super .. " + Shift + d", "Split pane vertical"),
    row(super .. " + z", "Toggle pane zoom (fullscreen)"),
    row(super .. " + x", "Close current pane (confirm)"),

    -- ══ PANE NAVIGATION ══
    header(Icons.ui("arrow_right"), "PANE NAVIGATION", green),
    row(super .. " + Ctrl + Left", "Focus pane left"),
    row(super .. " + Ctrl + Right", "Focus pane right"),
    row(super .. " + Ctrl + Up", "Focus pane up"),
    row(super .. " + Ctrl + Down", "Focus pane down"),

    -- ══ PANE RESIZING ══
    header(Icons.ui("gear"), "PANE RESIZING", green),
    row(super .. " + Shift + Left", "Resize pane left (2 cells)"),
    row(super .. " + Shift + Right", "Resize pane right (2 cells)"),
    row(super .. " + Shift + Up", "Resize pane up (2 cells)"),
    row(super .. " + Shift + Down", "Resize pane down (2 cells)"),

    -- ══ CLIPBOARD ══
    header(Icons.ui("check"), "CLIPBOARD", yellow),
    row(super .. " + c", "Copy selection to clipboard"),
    row(super .. " + v", "Paste from clipboard"),

    -- ══ SEARCH ══
    header(Icons.ui("search"), "SEARCH", yellow),
    row(super .. " + /", "Open search bar"),
    row("Ctrl + Shift + f", "Search (WezTerm default)"),
    row("Enter (in search)", "Next match"),
    row("Shift + Enter", "Previous match"),
    row("Escape", "Close search bar"),

    -- ══ SCROLL ══
    header(Icons.ui("arrow_right"), "SCROLL", cyan),
    row(super .. " + k", "Scroll up one line"),
    row(super .. " + j", "Scroll down one line"),
    row(super .. " + u", "Scroll up half page"),
    row(super .. " + f", "Scroll down half page"),
    row("Shift + PageUp", "Scroll up full page"),
    row("Shift + PageDown", "Scroll down full page"),
    row("Shift + Home", "Scroll to top of scrollback"),
    row("Shift + End", "Scroll to bottom"),

    -- ══ FONT SIZE ══
    header(Icons.ui("flame"), "FONT SIZE", orange),
    row(super .. " + =", "Increase font size"),
    row(super .. " + -", "Decrease font size"),
    row(super .. " + 0", "Reset font size to default"),
    row("Ctrl + Scroll Up", "Increase font size (mouse)"),
    row("Ctrl + Scroll Down", "Decrease font size (mouse)"),

    -- ══ WORKSPACES ══
    header(Icons.ui("folder"), "WORKSPACES", magenta),
    row(super .. " + s", "Workspace switcher (fuzzy)"),
    row(super .. " + n", "Next workspace"),

    -- ══ UTILITIES ══
    header(Icons.ui("rocket"), "UTILITIES & SYSTEM", magenta),
    row(super .. " + p", "Open command palette"),
    row(super .. " + l", "Show debug overlay"),
    row(super .. " + r", "Reload configuration"),
    row(super .. " + ?", "This cheat sheet"),
    row("Ctrl + Shift + l", "Debug overlay (WezTerm default)"),
    row("Ctrl + Shift + p", "Command palette (WezTerm default)"),

    -- ══ LEADER SEQUENCES ══
    header(Icons.ui("keyboard"), "LEADER KEY SEQUENCES  (" .. leader_str .. " then key)", pink),
    row("Leader -> o", "Toggle window opacity"),
    row("Leader -> t", "Cycle through 10 themes"),
    row("Leader -> ?", "Show this cheat sheet"),

    -- ══ COMMAND PALETTE ══
    header(Icons.ui("info"), "COMMAND PALETTE EXTRAS  (" .. super .. " + p)", pink),
    row("Toggle Opacity", "Switch opaque / transparent"),
    row("Cycle Theme", "Rotate through color themes"),
    row("Show Cheat Sheet", "Open this reference"),
    row("Show Debug Overlay", "WezTerm debug panel"),
    row("Rename Tab", "Set custom tab title"),
    row("Rename Workspace", "Set custom workspace name"),

    -- ══ COPY MODE ══
    header(Icons.ui("check"), "COPY MODE  (vi-style text selection)", cyan),
    row("Ctrl + Shift + x", "Enter copy mode"),
    row("v", "Start char selection"),
    row("V", "Start line selection"),
    row("Ctrl + v", "Start block/rectangle selection"),
    row("y", "Yank (copy) selection"),
    row("Escape / q", "Exit copy mode"),
    "",
    info("  Movement:"),
    subrow("  h / j / k / l", "Move left / down / up / right"),
    subrow("  w / b / e", "Forward / backward / end of word"),
    subrow("  0 / $ / ^", "Start / end / first non-blank"),
    subrow("  g / G", "Top / bottom of scrollback"),
    subrow("  H / M / L", "Top / middle / bottom of screen"),
    subrow("  Ctrl+u / Ctrl+d", "Half page up / down"),
    subrow("  Ctrl+b / Ctrl+f", "Full page up / down"),
    "",
    info("  Search in copy mode:"),
    subrow("  /", "Search forward"),
    subrow("  ?", "Search backward"),
    subrow("  n / N", "Next / previous match"),

    -- ══ QUICK SELECT ══
    header(Icons.ui("search"), "QUICK SELECT MODE", cyan),
    row("Ctrl + Shift + Space", "Enter quick select mode"),
    row("(type label)", "Select the labeled text"),
    row("Escape", "Cancel quick select"),

    -- ══ MOUSE ══
    header(Icons.ui("info"), "MOUSE ACTIONS", gray),
    row("Left click + drag", "Select text"),
    row("Double click", "Select word"),
    row("Triple click", "Select entire line"),
    row("Ctrl + click", "Open URL / hyperlink in browser"),
    row("Right click (+ btn)", "Open launch menu"),
    row("Middle click", "Paste from primary selection"),
    row("Scroll wheel", "Scroll terminal output"),
    row("Ctrl + Scroll", "Change font size"),
    row("Alt + click", "Rectangular / block selection"),

    -- ══ BUILT-IN DEFAULTS ══
    header(Icons.ui("gear"), "WEZTERM BUILT-IN DEFAULTS", gray),
    row("Ctrl + Shift + t", "New tab"),
    row("Ctrl + Shift + w", "Close tab"),
    row("Ctrl + Tab", "Next tab"),
    row("Ctrl + Shift + Tab", "Previous tab"),
    row("Ctrl + Shift + n", "New window"),
    row("Ctrl + Shift + m", "Hide / minimize window"),
    row("Ctrl + Shift + u", "Unicode character input"),
    row("Ctrl + Shift + c", "Copy to clipboard"),
    row("Ctrl + Shift + v", "Paste from clipboard"),
    row("Ctrl + Shift + r", "Reload configuration"),
    row("Ctrl + Shift + e", "Open scrollback in $EDITOR"),
    row("Ctrl + Shift + 1-9", "Activate tab by index"),

    -- ══ MULTIPLEXER ══
    header(Icons.devops("docker"), "MULTIPLEXER & REMOTE DOMAINS", orange),
    row(super .. " + s", "Domain launcher (fuzzy finder)"),
    row("SSH domains", "Defined in local/settings.lua"),
    row("Unix domains", "Local multiplexer sockets"),
    row("TLS domains", "Encrypted remote connections"),
    row("secret:KEY", "Load credentials from secrets"),
    row("WEZTERM_* env vars", "Override secrets from environment"),

    -- ══ STATUS BAR ══
    header(Icons.ui("info"), "STATUS BAR SEGMENTS  (info center)", blue),
    subrow(Icons.ui("rocket") .. " mode", "Key mode: NORMAL / COPY / SEARCH"),
    subrow(Icons.ui("folder") .. " workspace", "Active workspace name"),
    subrow(Icons.ui("folder_open") .. " cwd", "Current working directory"),
    subrow(Icons.get("git", "branch") .. " git", "Git branch + dirty/clean status"),
    subrow(Icons.runtime("node") .. " runtimes", "Node, Python, Ruby, Go, Rust, Lua..."),
    subrow(Icons.devops("docker") .. " tools", "tmux, Docker, Podman, kubectl..."),
    subrow(Icons.get("env", "container") .. " environment", "Docker/K8s/SSH/VPS/Proxmox..."),
    subrow(Icons.shell("zsh") .. " shell", "Active shell indicator"),
    subrow(Icons.os("linux") .. " platform", "OS: Linux/macOS/Windows/BSD"),
    subrow(Icons.battery(75, false) .. " battery", "Battery level with adaptive color"),
    subrow(Icons.ui("calendar") .. " datetime", "Current date and time"),
    subrow(Icons.tool("vpn") .. " network", "VPN status (opt-in feature)"),

    -- ══ THEMES ══
    header(Icons.ui("flame"), "AVAILABLE THEMES  (Leader -> t to cycle)", magenta),
    subrow(" 1. catppuccin_mocha", "Warm dark (default)"),
    subrow(" 2. catppuccin_macchiato", "Medium dark"),
    subrow(" 3. tokyo_night", "Deep blue dark"),
    subrow(" 4. tokyo_night_storm", "Stormy blue dark"),
    subrow(" 5. rose_pine", "Soft muted dark"),
    subrow(" 6. rose_pine_moon", "Lighter muted dark"),
    subrow(" 7. kanagawa", "Japanese ink wash painting"),
    subrow(" 8. gruvbox_dark", "Retro warm dark"),
    subrow(" 9. nord", "Arctic blue dark"),
    subrow("10. dracula", "Purple-centric dark"),
    subrow("Custom:", "Define in local/themes.lua"),

    -- ══ CONFIG FILES ══
    header(Icons.ui("file"), "CONFIGURATION FILES  (68 modules)", gray),
    subrow("wezterm.lua", "Entry point"),
    subrow("core/settings.lua", "Default settings registry"),
    subrow("core/colors.lua", "Centralized color palette"),
    subrow("core/icons.lua", "Icon / glyph registry"),
    subrow("core/fonts.lua", "Font config + fallbacks"),
    subrow("core/keybindings.lua", "Key mappings (platform-aware)"),
    subrow("core/appearance.lua", "Window, cursor, rendering"),
    subrow("core/tabs.lua", "Tab bar configuration"),
    subrow("core/launch.lua", "Shell detection & launch menu"),
    subrow("core/multiplexer.lua", "SSH / TLS / Unix domains"),
    subrow("themes/*.lua", "10 built-in theme palettes"),
    subrow("bar/segments/*.lua", "15 status bar segments"),
    subrow("events/*.lua", "9 event handlers"),
    subrow("highlights/*.lua", "6 hyperlink pattern sets"),
    subrow("lib/*.lua", "14 shared utility libraries"),
    subrow("tests/*.lua", "4 test suites (53 tests)"),

    -- ══ LOCAL OVERRIDES ══
    header(Icons.ui("lock"), "LOCAL OVERRIDES  (gitignored)", orange),
    subrow("local/settings.lua", "Override any configuration setting"),
    subrow("local/colors.lua", "Override any color in the palette"),
    subrow("local/keybindings.lua", "Add or override key bindings"),
    subrow("local/themes.lua", "Define your own custom themes"),
    subrow("local/secrets.lua", "SSH creds, API keys, passwords"),

    -- ══ TIPS ══
    header(Icons.ui("info"), "TIPS & TRICKS", green),
    subrow("Auto-reload", "Config reloads automatically on save"),
    subrow("Secrets", "Use 'secret:KEY' in SSH domain configs"),
    subrow("Env vars", "WEZTERM_* env vars override secrets"),
    subrow("Nerd Fonts off", "Set use_nerd_fonts = false for ASCII"),
    subrow("Opacity toggle", "Leader -> o switches transparency"),
    subrow("Theme cycle", "Leader -> t rotates all 10 themes"),
    subrow("Debug overlay", super .. " + l shows WezTerm internals"),
    subrow("Error logs", "Check debug overlay for config issues"),
    subrow("Run tests", "cd ~/.config/wezterm && lua tests/init.lua"),
    subrow("Cross-platform", "Linux, macOS, Windows, BSD, WSL"),
    subrow("Multi-shell", "zsh, fish, bash, nushell, pwsh, cmd"),

    "",
    string.format("  %s%s%s", bold .. magenta, string.rep("━", 68), reset),
    "",
    string.format(
      "  %sPress %sq%s %sto close this tab.%s",
      gray,
      yellow .. bold,
      reset,
      gray,
      reset
    ),
    "",
  }

  return table.concat(lines, "\n")
end

--- Register the show-cheat-sheet custom event.
--- @param wezterm table The wezterm module
function M.register(wezterm)
  wezterm.on("show-cheat-sheet", function(window, pane)
    local content = build_cheat_sheet(wezterm)

    -- Write to temp file
    local tmp_dir = os.getenv("TMPDIR") or "/tmp"
    local file_path = tmp_dir .. "/wezterm_cheat_sheet.txt"

    local f = io.open(file_path, "w")
    if not f then
      wezterm.log_error("Failed to write cheat sheet")
      return
    end
    f:write(content)
    f:close()

    -- Create a small wrapper script that uses scrollable cat
    local script_path = tmp_dir .. "/wezterm_cheat_sheet.sh"
    local sf = io.open(script_path, "w")
    if not sf then
      wezterm.log_error("Failed to write cheat sheet script")
      return
    end
    sf:write("#!/bin/sh\n")
    sf:write("export LANG=en_US.UTF-8\n")
    sf:write("export LC_ALL=en_US.UTF-8\n")
    sf:write("clear\n")
    sf:write(string.format('cat "%s"\n', file_path))
    sf:write('printf "\\n"\n')
    sf:write(
      'printf "  \\033[38;5;245mScroll with mouse or Shift+PgUp/PgDn. Press any key to close.\\033[0m\\n"\n'
    )
    sf:write('printf "\\n"\n')
    sf:write("stty raw -echo 2>/dev/null\n")
    sf:write("dd bs=1 count=1 2>/dev/null\n")
    sf:write("stty sane 2>/dev/null\n")
    sf:close()
    os.execute("chmod +x " .. script_path)

    window:perform_action(
      wezterm.action.SpawnCommandInNewTab({
        set_environment_variables = {
          LANG = "en_US.UTF-8",
          LC_ALL = "en_US.UTF-8",
        },
        args = { "/bin/sh", script_path },
      }),
      pane
    )
  end)
end

return M

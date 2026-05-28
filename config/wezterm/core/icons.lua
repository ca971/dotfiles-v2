--- @module "core.icons""
--- @description Centralized icon and glyph registry for the entire configuration.
--- Provides Nerd Font icons organized by category with fallback support
--- for systems without Nerd Fonts installed. All icons used across the
--- status bar, tabs, and UI are referenced from this single source.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Guard = require("lib.guard")
local TableUtils = require("lib.table_utils")

--- @class Icons
--- @field _VERSION string Module version
--- @field _use_nerd_fonts boolean Whether Nerd Fonts are available
local Icons = {
  _VERSION = "1.0.0",
  _use_nerd_fonts = true,
}

---------------------------------------------------------------------------
-- Icon definitions: Nerd Font glyphs with ASCII fallbacks
---------------------------------------------------------------------------

--- @type table<string, table<string, table>>
--- Organized by category, each icon has { nerd = "...", fallback = "..." }
local ICON_DEFS = {
  -- Operating systems
  os = {
    linux = { nerd = "", fallback = "LNX" },
    ubuntu = { nerd = "", fallback = "UBU" },
    debian = { nerd = "", fallback = "DEB" },
    fedora = { nerd = "", fallback = "FED" },
    arch = { nerd = "", fallback = "ARC" },
    nixos = { nerd = "", fallback = "NIX" },
    macos = { nerd = "", fallback = "MAC" },
    windows = { nerd = "", fallback = "WIN" },
    freebsd = { nerd = "", fallback = "BSD" },
    unknown = { nerd = "󰧟", fallback = "???" },
  },

  -- Shells
  shell = {
    zsh = { nerd = "󱆃", fallback = "zsh" },
    fish = { nerd = "󰈺", fallback = "fish" },
    bash = { nerd = "", fallback = "bash" },
    nushell = { nerd = "󱆀", fallback = "nu" },
    pwsh = { nerd = "󰨊", fallback = "ps" },
    cmd = { nerd = "", fallback = "cmd" },
    default = { nerd = "󰞷", fallback = "$" },
  },

  -- Development runtimes
  runtime = {
    node = { nerd = "󰎙", fallback = "js" },
    python = { nerd = "󰌠", fallback = "py" },
    ruby = { nerd = "", fallback = "rb" },
    go = { nerd = "󰟓", fallback = "go" },
    rust = { nerd = "󱘗", fallback = "rs" },
    java = { nerd = "", fallback = "jv" },
    lua = { nerd = "", fallback = "lua" },
    deno = { nerd = "🦕", fallback = "den" },
    bun = { nerd = "🧅", fallback = "bun" },
    nix = { nerd = "", fallback = "nix" },
  },

  -- DevOps & infrastructure tools
  devops = {
    docker = { nerd = "󰡨", fallback = "dkr" },
    podman = { nerd = "󰡊", fallback = "pod" },
    kubernetes = { nerd = "󱃾", fallback = "k8s" },
    helm = { nerd = "󰠳", fallback = "hlm" },
    terraform = { nerd = "󱁢", fallback = "tf" },
    proxmox = { nerd = "󰒋", fallback = "pmx" },
    opnsense = { nerd = "󰒘", fallback = "opn" },
  },

  -- Tools
  tool = {
    git = { nerd = "󰊢", fallback = "git" },
    tmux = { nerd = "", fallback = "tmx" },
    nvim = { nerd = "", fallback = "vim" },
    copilot = { nerd = "", fallback = "AI" },
    curl = { nerd = "󰌗", fallback = "url" },
    ssh = { nerd = "󰣀", fallback = "ssh" },
    mosh = { nerd = "󰣀", fallback = "msh" },
    vpn = { nerd = "󰖂", fallback = "vpn" },
  },

  -- Git status
  git = {
    branch = { nerd = "", fallback = "⎇" },
    added = { nerd = "", fallback = "+" },
    modified = { nerd = "", fallback = "~" },
    deleted = { nerd = "", fallback = "-" },
    conflict = { nerd = "", fallback = "!" },
    stash = { nerd = "󰘓", fallback = "$" },
    commit = { nerd = "", fallback = "cmt" },
    clean = { nerd = "󰄬", fallback = "ok" },
    dirty = { nerd = "󰶐", fallback = "!!" },
  },

  -- UI elements
  ui = {
    arrow_right = { nerd = "󰅂", fallback = ">" },
    arrow_left = { nerd = "󰅁", fallback = "<" },
    arrow_right_thin = { nerd = "", fallback = "|" },
    arrow_left_thin = { nerd = "", fallback = "|" },
    circle_filled = { nerd = "", fallback = "●" },
    circle_empty = { nerd = "", fallback = "○" },
    diamond = { nerd = "◆", fallback = "◆" },
    dot = { nerd = "•", fallback = "·" },
    ellipsis = { nerd = "…", fallback = "..." },
    lock = { nerd = "󰌾", fallback = "[L]" },
    unlock = { nerd = "󰌿", fallback = "[U]" },
    folder = { nerd = "", fallback = "/" },
    folder_open = { nerd = "", fallback = "/" },
    file = { nerd = "󰈔", fallback = "f" },
    home = { nerd = "󰋜", fallback = "~" },
    gear = { nerd = "", fallback = "*" },
    search = { nerd = "", fallback = "?" },
    clock = { nerd = "󱎫", fallback = "@" },
    calendar = { nerd = "󰃭", fallback = "D" },
    refresh = { nerd = "󰑐", fallback = "R" },
    check = { nerd = "✓", fallback = "v" },
    cross = { nerd = "✗", fallback = "x" },
    warning = { nerd = "", fallback = "!" },
    error = { nerd = "󰅚", fallback = "E" },
    info = { nerd = "󰋽", fallback = "i" },
    debug = { nerd = "󰃤", fallback = "D" },
    plus = { nerd = "󰐕", fallback = "+" },
    minus = { nerd = "󰐖", fallback = "-" },
    flame = { nerd = "󰈸", fallback = "^" },
    rocket = { nerd = "󰓅", fallback = ">" },
    keyboard = { nerd = "󰌌", fallback = "KB" },
  },

  -- Battery levels
  battery = {
    charging = { nerd = "󰂄", fallback = "[C]" },
    full = { nerd = "󰁹", fallback = "[=]" },
    high = { nerd = "󰂂", fallback = "[+]" },
    medium = { nerd = "󰁾", fallback = "[-]" },
    low = { nerd = "󰁺", fallback = "[!]" },
    critical = { nerd = "󰂃", fallback = "[X]" },
  },

  -- Environment indicators
  env = {
    local_machine = { nerd = "󰟀", fallback = "LOC" },
    remote = { nerd = "󰣀", fallback = "REM" },
    container = { nerd = "󰡨", fallback = "CNT" },
    vm = { nerd = "󰜺", fallback = "VM" },
    cloud = { nerd = "󰅟", fallback = "CLD" },
    wsl = { nerd = "", fallback = "WSL" },
  },

  -- Network
  network = {
    connected = { nerd = "󰖩", fallback = "NET" },
    disconnected = { nerd = "󰖪", fallback = "---" },
    wifi = { nerd = "󰤨", fallback = "WFI" },
    ethernet = { nerd = "󰈀", fallback = "ETH" },
  },

  -- Powerline separators
  separator = {
    left_hard = { nerd = "", fallback = "" },
    left_soft = { nerd = "", fallback = "|" },
    right_hard = { nerd = "", fallback = "" },
    right_soft = { nerd = "", fallback = "|" },
    block = { nerd = "█", fallback = "|" },
    thin_block = { nerd = "▊", fallback = "|" },
    bottom_left = { nerd = "", fallback = "\\" },
    bottom_right = { nerd = "", fallback = "/" },
    top_left = { nerd = "", fallback = "/" },
    top_right = { nerd = "", fallback = "\\" },
  },
}

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Get an icon by category and name.
--- @param category string Icon category (e.g. "os", "shell", "ui")
--- @param name string Icon name within the category
--- @param use_fallback? boolean Force ASCII fallback (default: uses _use_nerd_fonts)
--- @return string icon The icon glyph or fallback text
function Icons.get(category, name, use_fallback)
  Guard.is_non_empty_string(category, "category")
  Guard.is_non_empty_string(name, "name")

  local cat = ICON_DEFS[category]
  if not cat then
    return "?"
  end

  local icon_def = cat[name]
  if not icon_def then
    return "?"
  end

  if use_fallback or not Icons._use_nerd_fonts then
    return icon_def.fallback
  end

  return icon_def.nerd
end

--- Get an OS icon.
--- @param os_name string OS name (e.g. "linux", "macos")
--- @return string icon
function Icons.os(os_name)
  return Icons.get("os", os_name:lower())
end

--- Get a shell icon.
--- @param shell_name string Shell name (e.g. "zsh", "fish")
--- @return string icon
function Icons.shell(shell_name)
  return Icons.get("shell", shell_name:lower())
end

--- Get a runtime icon.
--- @param runtime_name string Runtime name (e.g. "node", "python")
--- @return string icon
function Icons.runtime(runtime_name)
  return Icons.get("runtime", runtime_name:lower())
end

--- Get a DevOps icon.
--- @param tool_name string Tool name (e.g. "docker", "kubernetes")
--- @return string icon
function Icons.devops(tool_name)
  return Icons.get("devops", tool_name:lower())
end

--- Get a tool icon.
--- @param tool_name string Tool name (e.g. "git", "tmux")
--- @return string icon
function Icons.tool(tool_name)
  return Icons.get("tool", tool_name:lower())
end

--- Get a UI icon.
--- @param element string UI element name (e.g. "folder", "lock")
--- @return string icon
function Icons.ui(element)
  return Icons.get("ui", element:lower())
end

--- Get a separator icon.
--- @param style string Separator style (e.g. "left_hard", "right_soft")
--- @return string icon
function Icons.separator(style)
  return Icons.get("separator", style:lower())
end

--- Get a battery icon based on level.
--- @param level number Battery percentage (0-100)
--- @param is_charging boolean Whether the battery is charging
--- @return string icon
function Icons.battery(level, is_charging)
  if is_charging then
    return Icons.get("battery", "charging")
  end
  if level >= 90 then
    return Icons.get("battery", "full")
  elseif level >= 60 then
    return Icons.get("battery", "high")
  elseif level >= 30 then
    return Icons.get("battery", "medium")
  elseif level >= 10 then
    return Icons.get("battery", "low")
  else
    return Icons.get("battery", "critical")
  end
end

--- Set whether to use Nerd Font glyphs.
--- @param enabled boolean True to use Nerd Fonts, false for ASCII fallbacks
function Icons.set_nerd_fonts(enabled)
  Icons._use_nerd_fonts = enabled
end

--- Get all icon names in a category.
--- @param category string The category name
--- @return table<number, string> names Array of icon names
function Icons.list_category(category)
  local cat = ICON_DEFS[category]
  if not cat then
    return {}
  end
  local names = {}
  for name, _ in pairs(cat) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

--- Get all category names.
--- @return table<number, string> categories Array of category names
function Icons.list_categories()
  local cats = {}
  for name, _ in pairs(ICON_DEFS) do
    cats[#cats + 1] = name
  end
  table.sort(cats)
  return cats
end

--- Register custom icons (for local overrides).
--- @param category string Category name (existing or new)
--- @param icons table<string, table> Map of name -> {nerd, fallback}
function Icons.register(category, icons)
  Guard.is_non_empty_string(category, "category")
  Guard.is_table(icons, "icons")
  if not ICON_DEFS[category] then
    ICON_DEFS[category] = {}
  end
  for name, def in pairs(icons) do
    ICON_DEFS[category][name] = def
  end
end

return Icons

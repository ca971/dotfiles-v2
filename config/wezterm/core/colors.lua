--- @module "core.colors""
--- @description Centralized color palette registry for the entire configuration.
--- Provides a single source of truth for all colors used across themes,
--- status bar, tabs, highlights, and UI elements. Supports palette extension,
--- color manipulation (lighten, darken, alpha), and semantic color tokens.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Guard = require("lib.guard")
local TableUtils = require("lib.table_utils")

--- @class ColorPalette
--- @field base table<string, string> Base ANSI-like palette
--- @field semantic table<string, string> Semantic tokens (success, error, etc.)
--- @field ui table<string, string> UI element colors (bar, tabs, etc.)
--- @field ansi table<number, string> ANSI 0-15 colors
--- @field brights table<number, string> Bright ANSI variants

--- @class Colors
--- @field _VERSION string Module version
--- @field _palette ColorPalette Active color palette
--- @field _overrides table<string, string> Local overrides applied on top
local Colors = {
  _VERSION = "1.0.0",
}

---------------------------------------------------------------------------
-- Default palette (Catppuccin Mocha inspired — the 2025 default)
---------------------------------------------------------------------------

--- @type ColorPalette
local DEFAULT_PALETTE = {
  -- Base surface colors (dark to light)
  base = {
    crust = "#11111b",
    mantle = "#181825",
    base = "#1e1e2e",
    surface0 = "#313244",
    surface1 = "#45475a",
    surface2 = "#585b70",
    overlay0 = "#6c7086",
    overlay1 = "#7f849c",
    overlay2 = "#9399b2",
    subtext0 = "#a6adc8",
    subtext1 = "#bac2de",
    text = "#cdd6f4",
  },

  -- Accent colors
  accent = {
    rosewater = "#f5e0dc",
    flamingo = "#f2cdcd",
    pink = "#f5c2e7",
    mauve = "#cba6f7",
    red = "#f38ba8",
    maroon = "#eba0ac",
    peach = "#fab387",
    yellow = "#f9e2af",
    green = "#a6e3a1",
    teal = "#94e2d5",
    sky = "#89dceb",
    sapphire = "#74c7ec",
    blue = "#89b4fa",
    lavender = "#b4befe",
  },

  -- Semantic color tokens (meaning-based)
  semantic = {
    success = "#a6e3a1",
    warning = "#f9e2af",
    error = "#f38ba8",
    info = "#89b4fa",
    hint = "#94e2d5",
    debug = "#cba6f7",
    muted = "#6c7086",
    highlight = "#f5c2e7",
    active = "#89b4fa",
    inactive = "#45475a",
    border = "#313244",
  },

  -- UI-specific colors
  ui = {
    bar_bg = "#11111b",
    bar_fg = "#cdd6f4",
    bar_active_bg = "#313244",
    bar_active_fg = "#cdd6f4",
    bar_inactive_bg = "#181825",
    bar_inactive_fg = "#6c7086",
    tab_bg = "#181825",
    tab_fg = "#cdd6f4",
    tab_active_bg = "#313244",
    tab_active_fg = "#cdd6f4",
    tab_hover_bg = "#45475a",
    tab_new_bg = "#181825",
    tab_new_fg = "#6c7086",
    cursor_bg = "#f5e0dc",
    cursor_fg = "#1e1e2e",
    selection_bg = "#45475a",
    selection_fg = "#cdd6f4",
    -- split = "#313244",
    split = "#89b4fa", -- Bright blue split line (active border feel)
    scrollbar = "#45475a",
    visual_bell = "#313244",
  },

  -- Standard ANSI colors (0-7)
  ansi = {
    "#45475a", -- black
    "#f38ba8", -- red
    "#a6e3a1", -- green
    "#f9e2af", -- yellow
    "#89b4fa", -- blue
    "#f5c2e7", -- magenta
    "#94e2d5", -- cyan
    "#bac2de", -- white
  },

  -- Bright ANSI colors (8-15)
  brights = {
    "#585b70", -- bright black
    "#f38ba8", -- bright red
    "#a6e3a1", -- bright green
    "#f9e2af", -- bright yellow
    "#89b4fa", -- bright blue
    "#f5c2e7", -- bright magenta
    "#94e2d5", -- bright cyan
    "#a6adc8", -- bright white
  },
}

---------------------------------------------------------------------------
-- Internal state
---------------------------------------------------------------------------

--- @type ColorPalette
local _active_palette = TableUtils.deep_clone(DEFAULT_PALETTE)

--- @type table
local _overrides = {}

---------------------------------------------------------------------------
-- Color manipulation helpers
---------------------------------------------------------------------------

--- Parse a hex color string to RGB components.
--- @param hex string Color in "#RRGGBB" or "#RRGGBBAA" format
--- @return number r Red (0-255)
--- @return number g Green (0-255)
--- @return number b Blue (0-255)
--- @return number|nil a Alpha (0-255) if present
function Colors.hex_to_rgb(hex)
  Guard.is_string(hex, "hex")
  hex = hex:gsub("^#", "")
  local r = tonumber(hex:sub(1, 2), 16) or 0
  local g = tonumber(hex:sub(3, 4), 16) or 0
  local b = tonumber(hex:sub(5, 6), 16) or 0
  local a = #hex >= 8 and tonumber(hex:sub(7, 8), 16) or nil
  return r, g, b, a
end

--- Convert RGB components to a hex color string.
--- @param r number Red (0-255)
--- @param g number Green (0-255)
--- @param b number Blue (0-255)
--- @return string hex Color in "#RRGGBB" format
function Colors.rgb_to_hex(r, g, b)
  r = math.max(0, math.min(255, math.floor(r + 0.5)))
  g = math.max(0, math.min(255, math.floor(g + 0.5)))
  b = math.max(0, math.min(255, math.floor(b + 0.5)))
  return string.format("#%02x%02x%02x", r, g, b)
end

--- Lighten a hex color by a percentage.
--- @param hex string The base color
--- @param percent number Percentage to lighten (0-100)
--- @return string lightened The lightened color
function Colors.lighten(hex, percent)
  Guard.is_string(hex, "hex")
  Guard.in_range(percent, 0, 100, "percent")
  local r, g, b = Colors.hex_to_rgb(hex)
  local factor = percent / 100
  r = r + (255 - r) * factor
  g = g + (255 - g) * factor
  b = b + (255 - b) * factor
  return Colors.rgb_to_hex(r, g, b)
end

--- Darken a hex color by a percentage.
--- @param hex string The base color
--- @param percent number Percentage to darken (0-100)
--- @return string darkened The darkened color
function Colors.darken(hex, percent)
  Guard.is_string(hex, "hex")
  Guard.in_range(percent, 0, 100, "percent")
  local r, g, b = Colors.hex_to_rgb(hex)
  local factor = 1 - (percent / 100)
  r = r * factor
  g = g * factor
  b = b * factor
  return Colors.rgb_to_hex(r, g, b)
end

--- Add alpha transparency to a hex color.
--- @param hex string The base color "#RRGGBB"
--- @param alpha number Alpha value (0.0 transparent - 1.0 opaque)
--- @return string color Color with alpha in "rgba(r,g,b,a)" format
function Colors.with_alpha(hex, alpha)
  Guard.is_string(hex, "hex")
  Guard.in_range(alpha, 0.0, 1.0, "alpha")
  local r, g, b = Colors.hex_to_rgb(hex)
  return string.format("rgba(%d,%d,%d,%.2f)", r, g, b, alpha)
end

---------------------------------------------------------------------------
-- Palette access API
---------------------------------------------------------------------------

--- Get a color from the active palette using dot notation.
--- @param path string Dot-separated path (e.g. "base.text", "semantic.error")
--- @param fallback? string Fallback color if path not found
--- @return string color The hex color string
function Colors.get(path, fallback)
  Guard.is_non_empty_string(path, "path")

  -- Check overrides first
  if _overrides[path] then
    return _overrides[path]
  end

  -- Navigate the palette
  return TableUtils.get(_active_palette, path, fallback or "#ff00ff")
end

--- Get a base surface color.
--- @param name string Surface name (e.g. "base", "surface0", "text")
--- @return string color The hex color
function Colors.base(name)
  return Colors.get("base." .. name)
end

--- Get an accent color.
--- @param name string Accent name (e.g. "blue", "pink", "mauve")
--- @return string color The hex color
function Colors.accent(name)
  return Colors.get("accent." .. name)
end

--- Get a semantic color.
--- @param name string Semantic name (e.g. "success", "error", "warning")
--- @return string color The hex color
function Colors.semantic(name)
  return Colors.get("semantic." .. name)
end

--- Get a UI color.
--- @param name string UI element name (e.g. "bar_bg", "tab_active_bg")
--- @return string color The hex color
function Colors.ui(name)
  return Colors.get("ui." .. name)
end

--- Get ANSI colors array.
--- @return table ansi Array of 8 ANSI colors
function Colors.ansi()
  return TableUtils.deep_clone(_active_palette.ansi)
end

--- Get bright ANSI colors array.
--- @return table brights Array of 8 bright colors
function Colors.brights()
  return TableUtils.deep_clone(_active_palette.brights)
end

--- Get the full active palette (deep copy).
--- @return ColorPalette palette The active palette
function Colors.get_palette()
  return TableUtils.deep_clone(_active_palette)
end

---------------------------------------------------------------------------
-- Palette management
---------------------------------------------------------------------------

--- Apply a complete palette (typically from a theme).
--- @param palette table Partial or full palette to merge
--- @return nil
function Colors.apply_palette(palette)
  Guard.is_table(palette, "palette")
  _active_palette = TableUtils.deep_merge(DEFAULT_PALETTE, palette)
end

--- Apply local overrides on top of the active palette.
--- @param overrides table<string, string> Map of "path" -> "#color"
--- @return nil
function Colors.apply_overrides(overrides)
  Guard.is_table(overrides, "overrides")
  for k, v in pairs(overrides) do
    _overrides[k] = v
  end
end

--- Reset to default palette.
--- @return nil
function Colors.reset()
  _active_palette = TableUtils.deep_clone(DEFAULT_PALETTE)
  _overrides = {}
end

--- Build a WezTerm color_scheme table from the active palette.
--- @return table scheme WezTerm-compatible color scheme
function Colors.to_wezterm_scheme()
  local p = _active_palette
  return {
    foreground = p.base.text,
    background = p.base.base,
    cursor_bg = p.ui.cursor_bg,
    cursor_fg = p.ui.cursor_fg,
    cursor_border = p.ui.cursor_bg,
    selection_bg = p.ui.selection_bg,
    selection_fg = p.ui.selection_fg,
    split = p.ui.split,
    compose_cursor = p.accent.peach,
    scrollbar_thumb = p.ui.scrollbar,
    visual_bell = p.ui.visual_bell,
    ansi = p.ansi,
    brights = p.brights,

    tab_bar = {
      background = p.ui.tab_bg,
      active_tab = {
        bg_color = p.ui.tab_active_bg,
        fg_color = p.ui.tab_active_fg,
        intensity = "Bold",
      },
      inactive_tab = {
        bg_color = p.ui.bar_inactive_bg,
        fg_color = p.ui.bar_inactive_fg,
      },
      inactive_tab_hover = {
        bg_color = p.ui.tab_hover_bg,
        fg_color = p.ui.tab_active_fg,
        italic = true,
      },
      new_tab = {
        bg_color = p.ui.tab_new_bg,
        fg_color = p.ui.tab_new_fg,
      },
      new_tab_hover = {
        bg_color = p.ui.tab_hover_bg,
        fg_color = p.ui.tab_active_fg,
      },
    },
  }
end

return Colors

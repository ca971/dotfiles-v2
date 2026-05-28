--- @module "core.fonts""
--- @description Font configuration with cross-platform fallback chains.
--- Manages primary font family, fallback fonts, font features,
--- and platform-specific adjustments. Ensures consistent rendering
--- across Linux, macOS, Windows, and BSD.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Guard = require("lib.guard")
local LoggerModule = require("lib.logger")
local Settings = require("core.settings")

--- @class Fonts
--- @field _VERSION string Module version
local Fonts = {
  _VERSION = "1.0.0",
}

--- @type Logger
local _log = nil

--- Lazy logger.
--- @return Logger
local function get_log()
  if not _log then
    _log = LoggerModule.create("fonts")
  end
  return _log
end

---------------------------------------------------------------------------
-- Font family presets
---------------------------------------------------------------------------

--- @type table<string, table>
--- Popular programming font presets with recommended settings.
local FONT_PRESETS = {
  ["JetBrains Mono"] = {
    harfbuzz_features = { "calt=1", "clig=1", "liga=1", "zero=1" },
    weight = "Regular",
    line_height = 1.2,
  },
  ["Fira Code"] = {
    harfbuzz_features = { "calt=1", "liga=1", "zero=1", "ss01=1" },
    weight = "Regular",
    line_height = 1.2,
  },
  ["Cascadia Code"] = {
    harfbuzz_features = { "calt=1", "liga=1", "ss01=1" },
    weight = "Regular",
    line_height = 1.2,
  },
  ["Iosevka"] = {
    harfbuzz_features = { "calt=1", "liga=1" },
    weight = "Regular",
    line_height = 1.3,
  },
  ["Victor Mono"] = {
    harfbuzz_features = { "calt=1", "liga=1", "ss01=1" },
    weight = "Regular",
    line_height = 1.2,
  },
  ["Monaspace Neon"] = {
    harfbuzz_features = { "calt=1", "liga=1", "dlig=1", "ss01=1", "ss02=1" },
    weight = "Regular",
    line_height = 1.2,
  },
  ["Comic Code"] = {
    harfbuzz_features = { "calt=1", "liga=1" },
    weight = "Regular",
    line_height = 1.2,
  },
  ["Berkeley Mono"] = {
    harfbuzz_features = { "calt=1", "liga=1" },
    weight = "Regular",
    line_height = 1.2,
  },
}

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Build the WezTerm font configuration table.
--- Uses settings from core.settings and applies platform adjustments.
--- @param wezterm table The wezterm module reference
--- @param platform_info? table Platform detection info
--- @return table config Font-related config keys to merge
function Fonts.build(wezterm, platform_info)
  Guard.is_table(wezterm, "wezterm")
  platform_info = platform_info or {}

  local family = Settings.get("font.family", "JetBrains Mono")
  local size = Settings.get("font.size", 13.0)
  local weight = Settings.get("font.weight", "Regular")
  local bold_weight = Settings.get("font.bold_weight", "Bold")
  local line_height = Settings.get("font.line_height", 1.2)
  local cell_width = Settings.get("font.cell_width", 1.0)
  local fallbacks = Settings.get("font.fallback_families", {})
  local harfbuzz = Settings.get("font.harfbuzz_features", {})

  -- Apply preset features if available
  local preset = FONT_PRESETS[family]
  if preset then
    if #harfbuzz == 0 then
      harfbuzz = preset.harfbuzz_features
    end
    get_log():debug("Font preset applied", { family = family })
  end

  -- Primary + fallback list
  local font_list = {
    { family = family, weight = weight, harfbuzz_features = harfbuzz },
  }
  for _, fallback_family in ipairs(fallbacks) do
    font_list[#font_list + 1] = { family = fallback_family }
  end

  -- Bold list (configurable weight)
  local bold_list = {
    { family = family, weight = bold_weight, harfbuzz_features = harfbuzz },
  }
  for _, fallback_family in ipairs(fallbacks) do
    bold_list[#bold_list + 1] = { family = fallback_family, weight = bold_weight }
  end

  -- Italic list
  local italic_list = {
    { family = family, weight = weight, italic = true, harfbuzz_features = harfbuzz },
  }
  for _, fallback_family in ipairs(fallbacks) do
    italic_list[#italic_list + 1] = { family = fallback_family, italic = true }
  end

  -- Bold italic list (configurable weight)
  local bold_italic_list = {
    { family = family, weight = bold_weight, italic = true, harfbuzz_features = harfbuzz },
  }
  for _, fallback_family in ipairs(fallbacks) do
    bold_italic_list[#bold_italic_list + 1] =
      { family = fallback_family, weight = bold_weight, italic = true }
  end

  local config = {
    font = wezterm.font_with_fallback(font_list),
    font_size = size,
    line_height = line_height,
    cell_width = cell_width,
    freetype_load_target = Settings.get("font.freetype_load_target", "Light"),
    freetype_render_target = Settings.get("font.freetype_render_target", "HorizontalLcd"),

    font_rules = {
      {
        intensity = "Bold",
        italic = false,
        font = wezterm.font_with_fallback(bold_list),
      },
      {
        intensity = "Normal",
        italic = true,
        font = wezterm.font_with_fallback(italic_list),
      },
      {
        intensity = "Bold",
        italic = true,
        font = wezterm.font_with_fallback(bold_italic_list),
      },
    },
  }

  get_log():info("Font configuration built", {
    family = family,
    size = tostring(size),
    weight = weight,
    bold_weight = bold_weight,
    fallbacks = tostring(#fallbacks),
  })

  return config
end

--- Get the list of available font presets.
--- @return table<number, string> presets Array of preset font family names
function Fonts.list_presets()
  local names = {}
  for name, _ in pairs(FONT_PRESETS) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

--- Get preset details for a specific font family.
--- @param family string The font family name
--- @return table|nil preset The preset details or nil
function Fonts.get_preset(family)
  return FONT_PRESETS[family]
end

return Fonts

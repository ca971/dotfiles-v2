--- @module "themes""
--- @description Theme engine: loads, validates, and applies color themes.
--- Provides theme discovery, switching, and palette application.
--- Themes are defined as modules returning palette override tables.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local LoggerModule = require("lib.logger")

--- @class ThemeEngine
--- @field _VERSION string Module version
local ThemeEngine = {
  _VERSION = "1.0.0",
}

--- @type table<string, string>
--- Map of theme name to module path.
local THEME_MAP = {
  catppuccin_mocha = "themes.catppuccin_mocha",
  catppuccin_macchiato = "themes.catppuccin_macchiato",
  tokyo_night = "themes.tokyo_night",
  tokyo_night_storm = "themes.tokyo_night_storm",
  rose_pine = "themes.rose_pine",
  rose_pine_moon = "themes.rose_pine_moon",
  kanagawa = "themes.kanagawa",
  gruvbox_dark = "themes.gruvbox_dark",
  nord = "themes.nord",
  dracula = "themes.dracula",
}

--- @type table<string, table>
local _loaded_themes = {}

--- @type string|nil
local _active_theme = nil

--- @type Logger
local _log = nil

local function get_log()
  if not _log then
    _log = LoggerModule.create("themes")
  end
  return _log
end

--- Load a theme module by name.
--- @param name string Theme name
--- @return table|nil palette The theme palette or nil
function ThemeEngine.load(name)
  if _loaded_themes[name] then
    return _loaded_themes[name]
  end

  local module_path = THEME_MAP[name]
  if not module_path then
    -- Try local themes
    local ok, mod = pcall(require, "local.themes")
    if ok and type(mod) == "table" and mod[name] then
      _loaded_themes[name] = mod[name]
      return mod[name]
    end
    get_log():warn("Unknown theme", { name = name })
    return nil
  end

  local ok, palette = pcall(require, module_path)
  if ok and type(palette) == "table" then
    _loaded_themes[name] = palette
    get_log():debug("Theme loaded", { name = name })
    return palette
  else
    get_log():error("Failed to load theme", {
      name = name,
      error = tostring(palette),
    })
    return nil
  end
end

--- Apply a theme by name.
--- @param name string Theme name
--- @return boolean success True if the theme was applied
function ThemeEngine.apply(name)
  local palette = ThemeEngine.load(name)
  if not palette then
    get_log():warn("Theme not found, keeping current", { name = name })
    return false
  end

  Colors.apply_palette(palette)
  _active_theme = name

  get_log():info("Theme applied", { name = name })
  return true
end

--- Get the currently active theme name.
--- @return string|nil name The active theme name
function ThemeEngine.get_active()
  return _active_theme
end

--- List all available theme names.
--- @return table<number, string> names Sorted theme names
function ThemeEngine.list()
  local names = {}
  for name, _ in pairs(THEME_MAP) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

--- Register a custom theme.
--- @param name string Theme name
--- @param palette table Theme palette
function ThemeEngine.register(name, palette)
  THEME_MAP[name] = nil -- Clear module path
  _loaded_themes[name] = palette
  get_log():info("Custom theme registered", { name = name })
end

return ThemeEngine

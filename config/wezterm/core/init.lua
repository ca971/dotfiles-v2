--- @module "core"
--- @description Core configuration bootstrapper and orchestrator.
--- Assembles the complete WezTerm configuration by loading and merging
--- all core modules: settings, colors, fonts, appearance, tabs,
--- keybindings, launch menu, and multiplexer domains.
--- Applies platform detection, theme selection, local overrides,
--- and validation in the correct order.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local LoggerModule = require("lib.logger")
local Path = require("lib.path")
local Platform = require("lib.platform")
local TableUtils = require("lib.table_utils")

--- @class Core
--- @field _VERSION string Module version
local Core = {
  _VERSION = "1.0.0",
}

--- @type Logger
local _log = nil

--- Lazy logger.
--- @return Logger
local function get_log()
  if not _log then
    _log = LoggerModule.create("core")
  end
  return _log
end

--- Safely require a module, returning nil on failure.
--- @param module_path string Module to require
--- @return any|nil module The loaded module or nil
--- @return string|nil error Error message if failed
local function safe_require(module_path)
  local ok, mod = pcall(require, module_path)
  if ok and type(mod) == "table" then
    return mod, nil
  elseif ok then
    return nil, string.format("Module '%s' did not return a table", module_path)
  else
    return nil, tostring(mod)
  end
end

--- Load local overrides for a specific module.
--- @param module_name string The override module name (e.g. "settings", "colors")
--- @return table|nil overrides The overrides table or nil
local function load_local_override(module_name)
  local local_path = Path.join(Path.get_local_dir(), module_name .. ".lua")
  if not Path.file_exists(local_path) then
    return nil
  end

  local ok, result = pcall(dofile, local_path)
  if ok and type(result) == "table" then
    get_log():info("Local override loaded", { module = module_name })
    return result
  elseif not ok then
    get_log():warn("Failed to load local override", {
      module = module_name,
      error = tostring(result),
    })
  end

  return nil
end

---------------------------------------------------------------------------
-- Main build function
---------------------------------------------------------------------------

--- Build the complete WezTerm configuration.
--- This is the main entry point called from wezterm.lua.
--- @param wezterm table The wezterm module reference
--- @return table config The complete WezTerm configuration table
function Core.build(wezterm)
  if not wezterm or type(wezterm) ~= "table" then
    error("Core.build() requires the wezterm module as argument")
  end

  local log = get_log()
  log:info("═══ WezTerm Enterprise Config - Build Start ═══")

  local build_start = os.clock()

  -- ╔═══════════════════════════════════════════════════════════════╗
  -- ║ Step 1: Platform Detection                                    ║
  -- ╚═══════════════════════════════════════════════════════════════╝
  local platform_info = Platform.detect()
  log:info("Platform detected", {
    os = platform_info.os,
    arch = platform_info.arch,
    hostname = platform_info.hostname,
  })

  -- ╔═══════════════════════════════════════════════════════════════╗
  -- ║ Step 2: Load Settings & Apply Overrides                       ║
  -- ╚═══════════════════════════════════════════════════════════════╝
  local Settings = require("core.settings")
  Settings.apply_platform_overrides(platform_info.os)
  Settings.apply_local_overrides()
  log:info("Settings loaded and overrides applied")

  -- ╔═══════════════════════════════════════════════════════════════╗
  -- ║ Step 3: Theme & Colors                                        ║
  -- ╚═══════════════════════════════════════════════════════════════╝
  local Colors = require("core.colors")
  local Icons = require("core.icons")

  -- Apply theme if theme engine is available
  local theme_name = Settings.get("theme.name", "catppuccin_mocha")
  local ThemeEngine, theme_err = safe_require("themes")
  if ThemeEngine and ThemeEngine.apply then
    ThemeEngine.apply(theme_name)
    log:info("Theme applied", { theme = theme_name })
  else
    log:debug("Theme engine not available, using default colors", {
      reason = theme_err or "not loaded",
    })
  end

  -- Apply local color overrides
  local color_overrides = load_local_override("colors")
  if color_overrides then
    Colors.apply_overrides(color_overrides)
  end

  -- Set nerd fonts based on settings
  Icons.set_nerd_fonts(Settings.get("theme.use_nerd_fonts", true))

  -- ╔═══════════════════════════════════════════════════════════════╗
  -- ║ Step 4: Build Configuration Sections                          ║
  -- ╚═══════════════════════════════════════════════════════════════╝
  local config = wezterm.config_builder and wezterm.config_builder() or {}

  -- Fonts
  local Fonts = require("core.fonts")
  local font_config = Fonts.build(wezterm, platform_info)

  -- Appearance
  local Appearance = require("core.appearance")
  local appearance_config = Appearance.build(wezterm, platform_info)

  -- Tabs
  local TabsModule = require("core.tabs")
  local tabs_config = TabsModule.build()

  -- Key bindings
  local Keybindings = require("core.keybindings")
  local keys_config = Keybindings.build(wezterm, platform_info)

  -- Launch menu & default shell
  local Launch = require("core.launch")
  local launch_config = Launch.build(platform_info)

  -- Multiplexer domains
  local Multiplexer = require("core.multiplexer")
  local mux_config = Multiplexer.build(platform_info)

  -- ╔═══════════════════════════════════════════════════════════════╗
  -- ║ Step 5: Merge All Sections                                    ║
  -- ╚═══════════════════════════════════════════════════════════════╝
  local merged = TableUtils.deep_merge(
    appearance_config,
    font_config,
    tabs_config,
    keys_config,
    launch_config,
    mux_config
  )

  -- Apply to config builder or table
  for key, value in pairs(merged) do
    config[key] = value
  end

  -- ╔═══════════════════════════════════════════════════════════════╗
  -- ║ Step 6: Register Events                                       ║
  -- ╚═══════════════════════════════════════════════════════════════╝
  local Events, events_err = safe_require("events")
  if Events and Events.register then
    Events.register(wezterm, platform_info)
    log:info("Events registered")
  else
    log:debug("Events module not available", {
      reason = events_err or "not loaded",
    })
  end

  -- ╔═══════════════════════════════════════════════════════════════╗
  -- ║ Step 7: Highlights                                            ║
  -- ╚═══════════════════════════════════════════════════════════════╝
  if Settings.get("features.highlights", true) then
    local Highlights, hl_err = safe_require("highlights")
    if Highlights and Highlights.build then
      local hl_config = Highlights.build()
      for key, value in pairs(hl_config) do
        config[key] = value
      end
      log:info("Highlights applied")
    else
      log:debug("Highlights module not available", {
        reason = hl_err or "not loaded",
      })
    end
  end

  -- ╔═══════════════════════════════════════════════════════════════╗
  -- ║ Step 8: Validate                                              ║
  -- ╚═══════════════════════════════════════════════════════════════╝
  local validation = Settings.validate()
  if not validation.valid then
    log:warn("Settings validation issues detected", {
      errors = tostring(#validation.errors),
    })
  end

  -- ╔═══════════════════════════════════════════════════════════════╗
  -- ║ Build Complete                                                ║
  -- ╚═══════════════════════════════════════════════════════════════╝
  local elapsed = (os.clock() - build_start) * 1000
  log:info("═══ Build Complete ═══", {
    elapsed_ms = string.format("%.2f", elapsed),
    platform = platform_info.os,
    theme = theme_name,
  })

  return config
end

return Core

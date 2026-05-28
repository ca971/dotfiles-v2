--- @module "core.settings""
--- @description Centralized settings registry for the entire configuration.
--- Single source of truth for all configurable parameters: appearance,
--- fonts, behavior, bar layout, key bindings preferences, and feature flags.
--- Supports validation, local overrides, and runtime modification.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Guard = require("lib.guard")
local LoggerModule = require("lib.logger")
local Path = require("lib.path")
local TableUtils = require("lib.table_utils")
local ValidatorModule = require("lib.validator")

--- @class Settings
--- @field _VERSION string Module version
local Settings = {
  _VERSION = "1.0.0",
}

---------------------------------------------------------------------------
-- Default settings definition
---------------------------------------------------------------------------

--- @type table
--- Complete default settings for the entire configuration.
local DEFAULTS = {
  -- General
  general = {
    check_for_updates = false,
    automatically_reload_config = true,
    status_update_interval = 1000,
    scrollback_lines = 10000,
    exit_behavior = "CloseOnCleanExit",
    exit_behavior_messaging = "Verbose",
    audible_bell = "Disabled",
    visual_bell = {
      fade_in_duration_ms = 75,
      fade_out_duration_ms = 75,
    },
  },

  -- Theme
  theme = {
    name = "catppuccin_mocha",
    use_nerd_fonts = true,
    color_scheme_dirs = {},
  },

  -- Font settings
  font = {
    family = "JetBrains Mono",
    size = 13.0,
    weight = "Regular",
    line_height = 1.2,
    cell_width = 1.0,
    fallback_families = {
      "Symbols Nerd Font Mono",
      "Noto Color Emoji",
      "Noto Sans Mono",
    },
    freetype_load_target = "Light",
    freetype_render_target = "HorizontalLcd",
    harfbuzz_features = { "calt=1", "clig=1", "liga=1", "zero=1" },
  },

  -- Window appearance
  window = {
    decorations = "RESIZE",
    initial_cols = 120,
    initial_rows = 35,
    padding = {
      left = "0.5cell",
      right = "0.5cell",
      top = "0.25cell",
      bottom = "0.25cell",
    },
    opacity = 0.95,
    blur = 10,
    max_fps = 120,
    animation_fps = 60,
    cursor_blink_rate = 500,
    cursor_blink_ease_in = "Constant",
    cursor_blink_ease_out = "Constant",
    default_cursor_style = "BlinkingBar",
  },

  -- Tab bar
  tab_bar = {
    enabled = true,
    position = "Top",
    max_width = 30,
    show_close_button = true,
    show_new_tab_button = true,
    hide_when_single = false,
    separator = "right_hard",
  },

  -- Status bar
  bar = {
    enabled = true,
    left_segments = {
      "mode",
      "workspace",
      "cwd",
      "git",
    },
    right_segments = {
      "runtimes",
      "tools",
      "environment",
      "shell",
      "platform",
      "battery",
      "datetime",
    },
    separator_style = "powerline",
    refresh_interval = 1000,
  },

  -- Key bindings
  keys = {
    leader = { key = "a", mods = "CTRL" },
    leader_timeout_ms = 2000,
    disable_default_key_bindings = false,
  },

  -- Shell preferences (in priority order)
  shell = {
    preferred = { "zsh", "fish", "bash" },
    login_shell = true,
  },

  -- Multiplexer
  multiplexer = {
    ssh_domains = {},
    tls_domains = {},
    unix_domains = {},
  },

  -- Logging
  logging = {
    level = "INFO",
    use_colors = true,
    buffer_size = 200,
  },

  -- Secrets
  secrets = {
    env_prefix = "WEZTERM_",
    sources = {
      env = true,
      localfile = true,
      keychain = false,
    },
  },

  -- Feature flags
  features = {
    status_bar = true,
    environment_detection = true,
    runtime_detection = true,
    tool_detection = true,
    git_status = true,
    battery_indicator = true,
    network_indicator = false,
    highlights = true,
    command_palette_extras = true,
  },

  -- Platform-specific overrides
  platform_overrides = {
    macos = {
      window = {
        decorations = "RESIZE",
        opacity = 0.92,
      },
      font = {
        size = 14.0,
      },
    },
    windows = {
      window = {
        decorations = "TITLE | RESIZE",
      },
      font = {
        size = 12.0,
      },
    },
    linux = {},
    bsd = {},
  },
}

---------------------------------------------------------------------------
-- Validation schema
---------------------------------------------------------------------------

local SETTINGS_SCHEMA = {
  ["general.scrollback_lines"] = {
    type = "number",
    min = 100,
    max = 1000000,
    description = "Number of scrollback lines",
  },
  ["general.status_update_interval"] = {
    type = "number",
    min = 100,
    max = 60000,
    description = "Status update interval in milliseconds",
  },
  ["theme.name"] = {
    type = "string",
    required = true,
    min_length = 1,
    description = "Active theme name",
  },
  ["font.size"] = {
    type = "number",
    min = 6.0,
    max = 72.0,
    description = "Font size in points",
  },
  ["font.line_height"] = {
    type = "number",
    min = 0.5,
    max = 3.0,
    description = "Line height multiplier",
  },
  ["window.opacity"] = {
    type = "number",
    min = 0.1,
    max = 1.0,
    description = "Window background opacity",
  },
  ["window.max_fps"] = {
    type = "number",
    min = 10,
    max = 240,
    description = "Maximum frames per second",
  },
  ["logging.level"] = {
    type = "string",
    one_of = { "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "OFF" },
    description = "Minimum log level",
  },
}

---------------------------------------------------------------------------
-- Internal state
---------------------------------------------------------------------------

--- @type table
local _active_settings = TableUtils.deep_clone(DEFAULTS)

--- @type Logger
local _log = nil

--- Lazy logger access.
--- @return Logger
local function get_log()
  if not _log then
    _log = LoggerModule.create("settings")
  end
  return _log
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Get a setting value using dot notation.
--- @param path string Dot-separated path (e.g. "font.size", "window.opacity")
--- @param default? any Default if path not found
--- @return any value The setting value
function Settings.get(path, default)
  Guard.is_non_empty_string(path, "path")
  return TableUtils.get(_active_settings, path, default)
end

--- Set a setting value using dot notation.
--- @param path string Dot-separated path
--- @param value any The value to set
--- @return nil
function Settings.set(path, value)
  Guard.is_non_empty_string(path, "path")
  TableUtils.set(_active_settings, path, value)
  get_log():debug("Setting changed", { path = path, value = tostring(value) })
end

--- Get the complete settings table (deep copy).
--- @return table settings Full settings
function Settings.get_all()
  return TableUtils.deep_clone(_active_settings)
end

--- Get the default settings (deep copy).
--- @return table defaults Default settings
function Settings.get_defaults()
  return TableUtils.deep_clone(DEFAULTS)
end

--- Apply platform-specific overrides based on detected OS.
--- @param os_name string The detected OS: "linux"|"macos"|"windows"|"bsd"
--- @return nil
function Settings.apply_platform_overrides(os_name)
  Guard.is_non_empty_string(os_name, "os_name")
  local overrides = Settings.get("platform_overrides." .. os_name)
  if overrides and type(overrides) == "table" then
    _active_settings = TableUtils.deep_merge(_active_settings, overrides)
    get_log():info("Platform overrides applied", { platform = os_name })
  end
end

--- Apply local user overrides from the local/ directory.
--- @return boolean success True if local overrides were found and applied
function Settings.apply_local_overrides()
  local local_path = Path.join(Path.get_local_dir(), "settings.lua")

  if not Path.file_exists(local_path) then
    get_log():debug("No local settings overrides found")
    return false
  end

  local ok, overrides = pcall(dofile, local_path)
  if not ok then
    get_log():warn("Failed to load local settings", {
      path = local_path,
      error = tostring(overrides),
    })
    return false
  end

  if type(overrides) == "table" then
    _active_settings = TableUtils.deep_merge(_active_settings, overrides)
    get_log():info("Local settings overrides applied", { path = local_path })
    return true
  end

  return false
end

--- Validate current settings against the schema.
--- @return table result Validation result {valid, errors, warnings}
function Settings.validate()
  local validator = ValidatorModule.get_validator()

  -- Register our schema if not already done
  if not TableUtils.contains(validator:list_schemas(), "settings") then
    -- Flatten settings for validation
    validator:register("settings_flat", SETTINGS_SCHEMA)
  end

  -- Flatten active settings for path-based validation
  local flat = {}
  local function flatten(tbl, prefix)
    for k, v in pairs(tbl) do
      local path = prefix and (prefix .. "." .. k) or k
      if type(v) == "table" and not v[1] then
        flatten(v, path)
      else
        flat[path] = v
      end
    end
  end
  flatten(_active_settings, nil)

  -- Manual validation against SETTINGS_SCHEMA
  local errors = {}
  local warnings = {}

  for path, rule in pairs(SETTINGS_SCHEMA) do
    local value = flat[path]

    if value == nil and rule.required then
      errors[#errors + 1] = string.format("Required setting '%s' is missing", path)
    elseif value ~= nil then
      if rule.type and type(value) ~= rule.type then
        errors[#errors + 1] =
          string.format("Setting '%s': expected %s, got %s", path, rule.type, type(value))
      end
      if rule.min and type(value) == "number" and value < rule.min then
        errors[#errors + 1] = string.format(
          "Setting '%s': value %s below minimum %s",
          path,
          tostring(value),
          tostring(rule.min)
        )
      end
      if rule.max and type(value) == "number" and value > rule.max then
        errors[#errors + 1] = string.format(
          "Setting '%s': value %s exceeds maximum %s",
          path,
          tostring(value),
          tostring(rule.max)
        )
      end
      if rule.one_of then
        local found = false
        for _, allowed in ipairs(rule.one_of) do
          if value == allowed then
            found = true
            break
          end
        end
        if not found then
          errors[#errors + 1] =
            string.format("Setting '%s': invalid value '%s'", path, tostring(value))
        end
      end
    end
  end

  return {
    valid = #errors == 0,
    errors = errors,
    warnings = warnings,
  }
end

--- Reset settings to defaults.
--- @return nil
function Settings.reset()
  _active_settings = TableUtils.deep_clone(DEFAULTS)
  _log = nil
end

return Settings

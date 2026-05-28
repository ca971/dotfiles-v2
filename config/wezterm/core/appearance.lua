--- @module "core.appearance""
--- @description Window appearance, GPU, and visual configuration.
--- Manages window decorations, padding, opacity, blur, cursor style,
--- background effects, and rendering settings with platform-specific
--- adjustments for optimal visual experience.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Guard = require("lib.guard")
local LoggerModule = require("lib.logger")
local Settings = require("core.settings")

--- @class Appearance
--- @field _VERSION string Module version
local Appearance = {
  _VERSION = "1.0.0",
}

--- @type Logger
local _log = nil

--- Lazy logger.
--- @return Logger
local function get_log()
  if not _log then
    _log = LoggerModule.create("appearance")
  end
  return _log
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Build the appearance configuration.
--- @param wezterm table The wezterm module reference
--- @param platform_info? table Platform detection info
--- @return table config Appearance-related config keys to merge
function Appearance.build(wezterm, platform_info)
  Guard.is_table(wezterm, "wezterm")
  platform_info = platform_info or {}

  local is_macos = platform_info.os == "macos"
  local is_windows = platform_info.os == "windows"

  -- Window settings from central settings
  local decorations = Settings.get("window.decorations", "RESIZE")
  local opacity = Settings.get("window.opacity", 0.95)
  local blur = Settings.get("window.blur", 10)
  local padding = Settings.get("window.padding", {})

  -- Platform-specific decoration adjustments
  if is_macos then
    decorations = "RESIZE"
  elseif is_windows then
    decorations = Settings.get("window.decorations", "TITLE | RESIZE")
  end

  -- Background layers (for advanced transparency/wallpaper)
  local background = {}

  -- If opacity < 1.0, use background layer for smooth transparency
  if opacity < 1.0 then
    background = {
      {
        source = { Color = Colors.base("base") },
        opacity = opacity,
        width = "100%",
        height = "100%",
      },
    }
  end

  local config = {
    -- Window
    window_decorations = decorations,
    initial_cols = Settings.get("window.initial_cols", 120),
    initial_rows = Settings.get("window.initial_rows", 35),
    window_padding = {
      left = padding.left or "0.5cell",
      right = padding.right or "0.5cell",
      top = padding.top or "0.25cell",
      bottom = padding.bottom or "0.25cell",
    },

    -- Opacity & blur
    window_background_opacity = opacity,
    macos_window_background_blur = is_macos and blur or nil,
    win32_system_backdrop = is_windows and "Acrylic" or nil,
    text_background_opacity = 1.0,

    -- Background layers (if configured)
    background = #background > 0 and background or nil,

    -- Rendering
    max_fps = Settings.get("window.max_fps", 120),
    animation_fps = Settings.get("window.animation_fps", 60),
    front_end = "WebGpu",
    webgpu_power_preference = "HighPerformance",

    -- Cursor
    default_cursor_style = Settings.get("window.default_cursor_style", "BlinkingBar"),
    cursor_blink_rate = Settings.get("window.cursor_blink_rate", 500),
    cursor_blink_ease_in = Settings.get("window.cursor_blink_ease_in", "Constant"),
    cursor_blink_ease_out = Settings.get("window.cursor_blink_ease_out", "Constant"),
    force_reverse_video_cursor = false,
    cursor_thickness = "0.1cell",

    -- General appearance
    enable_scroll_bar = false,
    adjust_window_size_when_changing_font_size = false,
    hide_mouse_cursor_when_typing = true,
    window_close_confirmation = "AlwaysPrompt",
    skip_close_confirmation_for_processes_named = {
      "bash",
      "sh",
      "zsh",
      "fish",
      "tmux",
      "nu",
      "cmd.exe",
      "pwsh.exe",
      "powershell.exe",
      "wsl.exe",
    },

    -- Behavior
    check_for_updates = Settings.get("general.check_for_updates", false),
    automatically_reload_config = Settings.get("general.automatically_reload_config", true),
    scrollback_lines = Settings.get("general.scrollback_lines", 10000),
    exit_behavior = Settings.get("general.exit_behavior", "CloseOnCleanExit"),
    exit_behavior_messaging = Settings.get("general.exit_behavior_messaging", "Verbose"),
    audible_bell = Settings.get("general.audible_bell", "Disabled"),
    visual_bell = Settings.get("general.visual_bell"),
    status_update_interval = Settings.get("general.status_update_interval", 1000),

    -- Pane borders
    -- Thin colored border around the active pane (tmux-style).
    pane_focus_follows_mouse = false,

    -- Pane split & focus indicator (tmux-style)
    -- The split line acts as a visual border between panes.
    -- Combined with inactive dimming, the active pane stands out clearly.

    -- Split line thickness and color (set via colors.lua → ui.split)
    -- A thinner, colored line gives the tmux border feel.

    -- Dim inactive panes (tmux-style active pane indicator)
    inactive_pane_hsb = {
      saturation = Settings.get("window.inactive_pane.saturation", 0.75),
      brightness = Settings.get("window.inactive_pane.brightness", 0.60),
    },
  }

  get_log():info("Appearance configuration built", {
    decorations = decorations,
    opacity = tostring(opacity),
    renderer = "WebGpu",
    platform = platform_info.os or "unknown",
  })

  return config
end

return Appearance

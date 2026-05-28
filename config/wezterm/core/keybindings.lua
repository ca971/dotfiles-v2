--- @module "core.keybindings""
--- @description Key binding configuration with platform-aware defaults.
--- Provides a structured key mapping system with leader key support,
--- modal key tables, and platform-specific modifier handling.
--- macOS uses CMD where Linux/Windows use ALT/CTRL.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Guard = require("lib.guard")
local LoggerModule = require("lib.logger")
local Settings = require("core.settings")

--- @class Keybindings
--- @field _VERSION string Module version
local Keybindings = {
  _VERSION = "1.0.0",
}

--- @type Logger
local _log = nil

--- Lazy logger.
--- @return Logger
local function get_log()
  if not _log then
    _log = LoggerModule.create("keybindings")
  end
  return _log
end

---------------------------------------------------------------------------
-- Platform-aware modifier helper
---------------------------------------------------------------------------

--- Get the platform-appropriate "super" modifier.
--- macOS uses CMD (SUPER), others use ALT.
--- @param platform_info table Platform detection info
--- @return string mod The modifier string
local function get_super_mod(platform_info)
  if platform_info and platform_info.os == "macos" then
    return "SUPER"
  end
  return "ALT"
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Build the complete key bindings configuration.
--- @param wezterm table The wezterm module reference
--- @param platform_info? table Platform info from lib.platform
--- @return table config Key binding config keys to merge
function Keybindings.build(wezterm, platform_info)
  Guard.is_table(wezterm, "wezterm")
  platform_info = platform_info or {}

  local act = wezterm.action
  local super = get_super_mod(platform_info)

  -- Leader key from settings
  local leader_cfg = Settings.get("keys.leader", { key = "Space", mods = "CTRL" })
  local leader_timeout = Settings.get("keys.leader_timeout_ms", 2000)

  -- Build key bindings
  local keys = {
    -- ═══════════════════════════════════════════
    -- Tab management
    -- ═══════════════════════════════════════════
    { key = "t", mods = super, action = act.SpawnTab("CurrentPaneDomain") },
    { key = "w", mods = super, action = act.CloseCurrentTab({ confirm = true }) },
    { key = "{", mods = super, action = act.ActivateTabRelative(-1) },
    { key = "}", mods = super, action = act.ActivateTabRelative(1) },
    { key = "{", mods = super .. "|SHIFT", action = act.MoveTabRelative(-1) },
    { key = "}", mods = super .. "|SHIFT", action = act.MoveTabRelative(1) },

    -- Direct tab access (1-9)
    { key = "1", mods = super, action = act.ActivateTab(0) },
    { key = "2", mods = super, action = act.ActivateTab(1) },
    { key = "3", mods = super, action = act.ActivateTab(2) },
    { key = "4", mods = super, action = act.ActivateTab(3) },
    { key = "5", mods = super, action = act.ActivateTab(4) },
    { key = "6", mods = super, action = act.ActivateTab(5) },
    { key = "7", mods = super, action = act.ActivateTab(6) },
    { key = "8", mods = super, action = act.ActivateTab(7) },
    { key = "9", mods = super, action = act.ActivateTab(-1) },

    -- ═══════════════════════════════════════════
    -- Pane management
    -- ═══════════════════════════════════════════
    { key = "d", mods = super, action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    {
      key = "d",
      mods = super .. "|SHIFT",
      action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
    },
    { key = "z", mods = super, action = act.TogglePaneZoomState },
    { key = "x", mods = super, action = act.CloseCurrentPane({ confirm = true }) },

    -- Pane navigation
    { key = "LeftArrow", mods = super .. "|CTRL", action = act.ActivatePaneDirection("Left") },
    { key = "RightArrow", mods = super .. "|CTRL", action = act.ActivatePaneDirection("Right") },
    { key = "UpArrow", mods = super .. "|CTRL", action = act.ActivatePaneDirection("Up") },
    { key = "DownArrow", mods = super .. "|CTRL", action = act.ActivatePaneDirection("Down") },

    -- Pane resizing
    { key = "LeftArrow", mods = super .. "|SHIFT", action = act.AdjustPaneSize({ "Left", 2 }) },
    { key = "RightArrow", mods = super .. "|SHIFT", action = act.AdjustPaneSize({ "Right", 2 }) },
    { key = "UpArrow", mods = super .. "|SHIFT", action = act.AdjustPaneSize({ "Up", 2 }) },
    { key = "DownArrow", mods = super .. "|SHIFT", action = act.AdjustPaneSize({ "Down", 2 }) },

    -- ═══════════════════════════════════════════
    -- Clipboard
    -- ═══════════════════════════════════════════
    { key = "c", mods = super, action = act.CopyTo("Clipboard") },
    { key = "v", mods = super, action = act.PasteFrom("Clipboard") },

    -- ═══════════════════════════════════════════
    -- Scroll
    -- ═══════════════════════════════════════════
    { key = "k", mods = super, action = act.ScrollByLine(-1) },
    { key = "j", mods = super, action = act.ScrollByLine(1) },
    { key = "u", mods = super, action = act.ScrollByPage(-0.5) },
    { key = "f", mods = super, action = act.ScrollByPage(0.5) },

    -- ═══════════════════════════════════════════
    -- Search & utilities
    -- ═══════════════════════════════════════════
    { key = "/", mods = super, action = act.Search("CurrentSelectionOrEmptyString") },
    { key = "p", mods = super, action = act.ActivateCommandPalette },
    { key = "l", mods = super, action = act.ShowDebugOverlay },
    { key = "r", mods = super, action = act.ReloadConfiguration },

    -- ═══════════════════════════════════════════
    -- Font size
    -- ═══════════════════════════════════════════
    { key = "=", mods = super, action = act.IncreaseFontSize },
    { key = "-", mods = super, action = act.DecreaseFontSize },
    { key = "0", mods = super, action = act.ResetFontSize },

    -- ═══════════════════════════════════════════
    -- Workspaces
    -- ═══════════════════════════════════════════
    { key = "s", mods = super, action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
    { key = "n", mods = super, action = act.SwitchWorkspaceRelative(1) },

    -- ═══════════════════════════════════════════
    -- Custom events (LEADER key sequences)
    -- ═══════════════════════════════════════════
    { key = "o", mods = "LEADER", action = act.EmitEvent("toggle-opacity") },
    { key = "t", mods = "LEADER", action = act.EmitEvent("cycle-theme") },
    { key = "?", mods = "LEADER", action = act.EmitEvent("show-cheat-sheet") },
    { key = "?", mods = super, action = act.EmitEvent("show-cheat-sheet") },
  }

  -- Key tables for modal input
  local key_tables = {
    resize_pane = {
      { key = "h", action = act.AdjustPaneSize({ "Left", 2 }) },
      { key = "l", action = act.AdjustPaneSize({ "Right", 2 }) },
      { key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
      { key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
      { key = "Escape", action = "PopKeyTable" },
    },
  }

  local config = {
    leader = {
      key = leader_cfg.key,
      mods = leader_cfg.mods,
      timeout_milliseconds = leader_timeout,
    },
    disable_default_key_bindings = Settings.get("keys.disable_default_key_bindings", false),
    keys = keys,
    key_tables = key_tables,
  }

  get_log():info("Key bindings built", {
    binding_count = tostring(#keys),
    leader = leader_cfg.mods .. "+" .. leader_cfg.key,
    super_mod = super,
  })

  return config
end

return Keybindings

-- ═══════════════════════════════════════════════════════════════════════════════
-- @file config/wezterm/wezterm.lua
-- @description WezTerm — GPU-accelerated terminal emulator
-- @since 1.0.0
-- ═══════════════════════════════════════════════════════════════════════════════

local wezterm = require("wezterm")
local config = {}

-- ── Appearance ──
config.color_scheme = "Catppuccin Mocha"
config.color_scheme_dirs = { os.getenv("HOME") .. "/.config/wezterm/colors" }
config.window_background_opacity = 0.92
config.macos_window_background_blur = 30

-- ── Font ──
config.font = wezterm.font("JetBrains Mono", { weight = "Medium" })
config.font_size = 14.0
config.line_height = 1.2
config.harfbuzz_features = { "calt=1", "liga=1", "zero=1" } -- ligatures, slashed zero

-- ── Window ──
config.window_decorations = "RESIZE"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 4 }
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.tab_max_width = 32

-- Hide tab bar when only one tab
config.hide_tab_bar_if_only_one_tab = true

-- ── Cursor ──
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500
config.force_reverse_video_cursor = true

-- ── Keys ──
config.disable_default_key_bindings = false
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	-- Split panes
	{
		key = "d",
		mods = "LEADER",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{ key = "r", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = true }) },

	-- Navigate panes (vim-like)
	{ key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },

	-- Resize panes
	{ key = "h", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Left", 5 }) },
	{ key = "j", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Down", 5 }) },
	{ key = "k", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Up", 5 }) },
	{ key = "l", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Right", 5 }) },

	-- Toggle fullscreen
	{ key = "f", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },

	-- Tabs
	{ key = "n", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ key = "[", mods = "LEADER", action = wezterm.action.ActivateTabRelative(-1) },
	{ key = "]", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
	{ key = "1", mods = "LEADER", action = wezterm.action.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = wezterm.action.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = wezterm.action.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = wezterm.action.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = wezterm.action.ActivateTab(4) },
	{ key = "6", mods = "LEADER", action = wezterm.action.ActivateTab(5) },
	{ key = "7", mods = "LEADER", action = wezterm.action.ActivateTab(6) },
	{ key = "8", mods = "LEADER", action = wezterm.action.ActivateTab(7) },
	{ key = "9", mods = "LEADER", action = wezterm.action.ActivateTab(8) },

	-- Copy / paste
	{ key = "c", mods = "LEADER", action = wezterm.action.ActivateCopyMode },
	{ key = "v", mods = "LEADER", action = wezterm.action.PasteFrom("Clipboard") },

	-- Search
	{ key = "/", mods = "LEADER", action = wezterm.action.Search("CurrentSelectionOrEmptyString") },

	-- Quick reload config
	{ key = "R", mods = "LEADER|SHIFT", action = wezterm.action.ReloadConfiguration },
}

-- ── Mouse ──
config.mouse_bindings = {
	-- Right-click for context menu (default terminal behavior)
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action.PasteFrom("PrimarySelection"),
	},
	-- Ctrl-click to open URLs
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}

-- ── Hyperlinks ──
config.hyperlink_rules = {
	-- GitHub issues/PRs: #123 → github.com link
	{
		regex = [[\b(\d+)\b]],
		format = "https://github.com/ca971/dotfiles-v2/issues/$1",
	},
}

-- ── Scrollback ──
config.scrollback_lines = 10000
config.enable_scroll_bar = false

-- ── Bell ──
config.audible_bell = "Disabled"
config.visual_bell = {
	fade_in_duration_ms = 0,
	fade_out_duration_ms = 300,
	target = "CursorColor",
}

return config

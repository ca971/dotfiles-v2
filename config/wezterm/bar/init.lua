--- @module "bar""
--- @description Status bar orchestrator.
--- Assembles left and right status bar sections by rendering
--- configured segments and formatting them with the builder.
--- Acts as the "Information Center" — the main status display.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local BarBuilder = require("bar.builder")
local Colors = require("core.colors")
local LoggerModule = require("lib.logger")
local Segments = require("bar.segments")
local Separators = require("bar.separators")
local Settings = require("core.settings")

--- @class Bar
--- @field _VERSION string Module version
local Bar = {
  _VERSION = "1.0.0",
}

--- @type Logger
local _log = nil

--- Lazy logger.
--- @return Logger
local function get_log()
  if not _log then
    _log = LoggerModule.create("bar")
  end
  return _log
end

--- Build the render context from WezTerm window and pane objects.
--- @param window table WezTerm window object
--- @param pane table WezTerm pane object
--- @param platform_info table Platform detection info
--- @return table context The render context
local function build_context(window, pane, platform_info)
  return {
    window = window,
    pane = pane,
    platform_info = platform_info,
  }
end

-- --- Render the left status bar.
-- --- @param wezterm table The wezterm module
-- --- @param window table WezTerm window object
-- --- @param pane table WezTerm pane object
-- --- @param platform_info table Platform info
-- --- @return table format_items WezTerm FormatItem array
-- function Bar.render_left(wezterm, window, pane, platform_info)
-- 	if not Settings.get("bar.enabled", true) then
-- 		return {}
-- 	end
--
-- 	local context = build_context(window, pane, platform_info)
-- 	local segment_names = Settings.get("bar.left_segments", {
-- 		"mode",
-- 		"workspace",
-- 		"cwd",
-- 		"git",
-- 	})
--
-- 	local builder = BarBuilder({
-- 		side = "left",
-- 		bar_bg = Colors.ui("bar_bg"),
-- 	})
--
-- 	for _, name in ipairs(segment_names) do
-- 		local segment = Segments.render(name, wezterm, context)
-- 		if segment then
-- 			builder:add(segment)
-- 		end
-- 	end
--
-- 	return builder:build(wezterm)
-- end

--- Render the left status bar.
--- The native tab bar already occupies the left/top visual space in WezTerm.
--- To avoid rendering conflicts and visual overlap, the enterprise status
--- information is rendered on the right side only.
--- @param wezterm table The wezterm module
--- @param window table WezTerm window object
--- @param pane table WezTerm pane object
--- @param platform_info table Platform info
--- @return table format_items WezTerm FormatItem array
function Bar.render_left(wezterm, window, pane, platform_info)
  return {}
end

--- Render the right status bar.
--- @param wezterm table The wezterm module
--- @param window table WezTerm window object
--- @param pane table WezTerm pane object
--- @param platform_info table Platform info
--- @return table format_items WezTerm FormatItem array
function Bar.render_right(wezterm, window, pane, platform_info)
  if not Settings.get("bar.enabled", true) then
    return {}
  end

  local context = build_context(window, pane, platform_info)
  local segment_names = Settings.get("bar.right_segments", {
    "runtimes",
    "tools",
    "environment",
    "shell",
    "platform",
    "battery",
    "datetime",
  })

  local builder = BarBuilder({
    side = "right",
    bar_bg = Colors.ui("bar_bg"),
  })

  for _, name in ipairs(segment_names) do
    local segment = Segments.render(name, wezterm, context)
    if segment then
      builder:add(segment)
    end
  end

  return builder:build(wezterm)
end

--- Initialize the bar system (set separator style, etc.).
--- @return nil
function Bar.setup()
  local style = Settings.get("bar.separator_style", "powerline")
  Separators.set_style(style)
  get_log():info("Bar initialized", { style = style })
end

--- Register bar events with WezTerm (called from events).
--- @param wezterm table The wezterm module
--- @param platform_info table Platform info
function Bar.register(wezterm, platform_info)
  Bar.setup()

  wezterm.on("update-status", function(window, pane)
    local left = Bar.render_left(wezterm, window, pane, platform_info)
    local right = Bar.render_right(wezterm, window, pane, platform_info)

    window:set_left_status(wezterm.format(left))
    window:set_right_status(wezterm.format(right))
  end)

  get_log():info("Bar events registered")
end

return Bar

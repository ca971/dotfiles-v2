--- @module "bar.separators""
--- @description Powerline separator styles and segment formatting helpers.
--- Provides multiple separator styles (powerline, slant, round, block,
--- plain) and methods to wrap segments with proper foreground/background
--- color transitions for the status bar.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Guard = require("lib.guard")
local Icons = require("core.icons")

--- @class Separators
--- @field _VERSION string Module version
local Separators = {
  _VERSION = "1.0.0",
}

---------------------------------------------------------------------------
-- Separator style definitions
---------------------------------------------------------------------------

--- @type table<string, table>
--- Each style defines left/right hard and soft separator characters.
local STYLES = {
  powerline = {
    left_hard = "",
    left_soft = "",
    right_hard = "",
    right_soft = "",
  },
  slant = {
    left_hard = "",
    left_soft = "",
    right_hard = "",
    right_soft = "",
  },
  round = {
    left_hard = "",
    left_soft = "",
    right_hard = "",
    right_soft = "",
  },
  block = {
    left_hard = "█",
    left_soft = "▊",
    right_hard = "█",
    right_soft = "▊",
  },
  plain = {
    left_hard = "▌",
    left_soft = "│",
    right_hard = "▐",
    right_soft = "│",
  },
  none = {
    left_hard = "",
    left_soft = " ",
    right_hard = "",
    right_soft = " ",
  },
}

--- @type string
--- Currently active style name.
local _active_style = "powerline"

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Set the active separator style.
--- @param style string Style name: "powerline"|"slant"|"round"|"block"|"plain"|"none"
function Separators.set_style(style)
  Guard.is_non_empty_string(style, "style")
  if STYLES[style] then
    _active_style = style
  end
end

--- Get the current style name.
--- @return string style The active style name
function Separators.get_style()
  return _active_style
end

--- Get a separator character.
--- @param direction string "left" or "right"
--- @param kind string "hard" or "soft"
--- @return string separator The separator character
function Separators.get(direction, kind)
  local style = STYLES[_active_style] or STYLES.powerline
  local key = direction .. "_" .. kind
  return style[key] or ""
end

--- Build a left-side separator with color transition.
--- Used between segments on the left status bar.
--- @param wezterm table The wezterm module
--- @param bg string Background color of the current segment
--- @param prev_bg string Background color of the previous segment
--- @return table element WezTerm FormatItem for the separator
function Separators.left_transition(wezterm, bg, prev_bg)
  return {
    { Foreground = { Color = prev_bg } },
    { Background = { Color = bg } },
    { Text = Separators.get("left", "hard") },
  }
end

--- Build a right-side separator with color transition.
--- @param wezterm table The wezterm module
--- @param bg string Background color of the current segment
--- @param next_bg string Background color of the next segment (or bar bg)
--- @return table element WezTerm FormatItem for the separator
function Separators.right_transition(wezterm, bg, next_bg)
  return {
    { Foreground = { Color = bg } },
    { Background = { Color = next_bg } },
    { Text = Separators.get("right", "hard") },
  }
end

--- Build a soft separator (within same background).
--- @param fg string Foreground color for the separator
--- @param bg string Background color
--- @param direction? string "left" or "right" (default: "left")
--- @return table elements WezTerm FormatItems
function Separators.soft(fg, bg, direction)
  direction = direction or "left"
  return {
    { Foreground = { Color = fg } },
    { Background = { Color = bg } },
    { Text = Separators.get(direction, "soft") },
  }
end

--- List all available styles.
--- @return table<number, string> styles Array of style names
function Separators.list_styles()
  local names = {}
  for name, _ in pairs(STYLES) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

return Separators

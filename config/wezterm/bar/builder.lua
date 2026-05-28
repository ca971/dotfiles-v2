--- @module "bar.builder""
--- @description Status bar segment builder using OOP pattern.
--- Provides a fluent API for constructing WezTerm format items
--- with proper foreground/background color management, padding,
--- icon integration, and separator transitions.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Class = require("lib.class")
local Colors = require("core.colors")
local Guard = require("lib.guard")
local Separators = require("bar.separators")

--- @class BarSegment
--- @field text string Segment text content
--- @field fg string Foreground color
--- @field bg string Background color
--- @field icon string|nil Optional leading icon
--- @field visible boolean Whether the segment should be rendered
--- @field priority number Rendering priority (lower = more important)

--- @class BarBuilder
--- @field _segments table<number, BarSegment> Collected segments
--- @field _side string "left" or "right"
--- @field _bar_bg string Bar background color
local BarBuilder = Class.new("BarBuilder")

--- Initialize the bar builder.
--- @param opts? table Options
--- @field opts.side? string "left" or "right" (default: "left")
--- @field opts.bar_bg? string Bar background color
function BarBuilder:init(opts)
  opts = opts or {}
  self._segments = {}
  self._side = opts.side or "left"
  self._bar_bg = opts.bar_bg or Colors.ui("bar_bg")
end

--- Add a segment to the builder.
--- @param segment BarSegment Segment data
--- @return BarBuilder self For method chaining
function BarBuilder:add(segment)
  Guard.is_table(segment, "segment")

  -- Skip invisible segments
  if segment.visible == false then
    return self
  end

  -- Skip empty text segments
  if not segment.text or #segment.text == 0 then
    return self
  end

  self._segments[#self._segments + 1] = {
    text = segment.text,
    fg = segment.fg or Colors.ui("bar_fg"),
    bg = segment.bg or Colors.ui("bar_active_bg"),
    icon = segment.icon,
    visible = true,
    priority = segment.priority or 50,
  }

  return self
end

--- Build the WezTerm FormatItem array for the left side.
--- @param wezterm table The wezterm module
--- @return table format_items Array of WezTerm FormatItems
function BarBuilder:build_left(wezterm)
  local items = {}
  local segments = self._segments

  if #segments == 0 then
    return items
  end

  for i, seg in ipairs(segments) do
    -- Separator before segment (transition from previous bg)
    local prev_bg = (i == 1) and self._bar_bg or segments[i - 1].bg

    if prev_bg ~= seg.bg then
      items[#items + 1] = { Foreground = { Color = prev_bg } }
      items[#items + 1] = { Background = { Color = seg.bg } }
      items[#items + 1] = { Text = Separators.get("left", "hard") }
    end

    -- Segment content
    items[#items + 1] = { Foreground = { Color = seg.fg } }
    items[#items + 1] = { Background = { Color = seg.bg } }

    local content = " "
    if seg.icon then
      content = content .. seg.icon .. " "
    end
    content = content .. seg.text .. " "

    items[#items + 1] = { Text = content }
  end

  -- Final separator back to bar bg
  local last_bg = segments[#segments].bg
  if last_bg ~= self._bar_bg then
    items[#items + 1] = { Foreground = { Color = last_bg } }
    items[#items + 1] = { Background = { Color = self._bar_bg } }
    items[#items + 1] = { Text = Separators.get("left", "hard") }
  end

  return items
end

--- Build the WezTerm FormatItem array for the right side.
--- @param wezterm table The wezterm module
--- @return table format_items Array of WezTerm FormatItems
function BarBuilder:build_right(wezterm)
  local items = {}
  local segments = self._segments

  if #segments == 0 then
    return items
  end

  for i, seg in ipairs(segments) do
    -- Separator before segment (right side uses right-pointing arrows)
    local prev_bg = (i == 1) and self._bar_bg or segments[i - 1].bg

    items[#items + 1] = { Foreground = { Color = seg.bg } }
    items[#items + 1] = { Background = { Color = prev_bg } }
    items[#items + 1] = { Text = Separators.get("right", "hard") }

    -- Segment content
    items[#items + 1] = { Foreground = { Color = seg.fg } }
    items[#items + 1] = { Background = { Color = seg.bg } }

    local content = " "
    if seg.icon then
      content = content .. seg.icon .. " "
    end
    content = content .. seg.text .. " "

    items[#items + 1] = { Text = content }
  end

  return items
end

--- Build based on the configured side.
--- @param wezterm table The wezterm module
--- @return table format_items Array of WezTerm FormatItems
function BarBuilder:build(wezterm)
  if self._side == "right" then
    return self:build_right(wezterm)
  end
  return self:build_left(wezterm)
end

--- Get the number of segments.
--- @return number count Segment count
function BarBuilder:count()
  return #self._segments
end

--- Clear all segments.
--- @return BarBuilder self For method chaining
function BarBuilder:clear()
  self._segments = {}
  return self
end

return BarBuilder

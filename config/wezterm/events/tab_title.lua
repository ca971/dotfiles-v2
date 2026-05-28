--- @module "events.tab_title""
--- @description Tab title formatting event handler.
--- Adds a configurable powerline separator on the right side of each tab.
--- The separator style can be changed via settings or local/settings.lua.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")
local Settings = require("core.settings")
local Tabs = require("core.tabs")

local M = {}

--- Register the format-tab-title event.
--- @param wezterm table The wezterm module
function M.register(wezterm)
  wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local is_active = tab.is_active

    -- Pane info
    local pane = tab.active_pane or {}
    local process_name = pane.foreground_process_name or ""
    local title = tab.tab_title
    if not title or #title == 0 then
      title = pane.title or ""
    end
    if not title or #title == 0 then
      title = "shell"
    end

    -- Shorten title
    if #title > (max_width - 8) then
      title = title:sub(1, max_width - 9) .. "..."
    end

    -- Process icon
    local icon = Tabs.get_process_icon(process_name)

    -- Tab index (1-based)
    local index = (tab.tab_index or 0) + 1

    -- Tab colors
    local bg, fg
    if is_active then
      bg = Colors.ui("tab_active_bg")
      fg = Colors.ui("tab_active_fg")
    elseif hover then
      bg = Colors.ui("tab_hover_bg")
      fg = Colors.ui("tab_active_fg")
    else
      bg = Colors.ui("bar_inactive_bg")
      fg = Colors.ui("bar_inactive_fg")
    end

    -- Bar background for separator transition
    local bar_bg = Colors.ui("tab_bg")

    -- Configurable separator from settings
    local sep_style = Settings.get("tab_bar.separator", "right_hard")
    local sep_char = Icons.separator(sep_style)

    return {
      -- Tab content
      { Background = { Color = bg } },
      { Foreground = { Color = fg } },
      { Attribute = { Intensity = is_active and "Bold" or "Normal" } },
      { Text = string.format(" %s %d: %s ", icon, index, title) },
      -- Right separator
      { Background = { Color = bar_bg } },
      { Foreground = { Color = bg } },
      { Text = sep_char },
    }
  end)
end

return M

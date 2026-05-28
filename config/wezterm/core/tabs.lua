--- @module "core.tabs""
--- @description Tab bar configuration and tab formatting.
--- Configures the tab bar appearance, position, and styling.
--- Provides utilities for tab title formatting with icons and
--- process name detection.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Guard = require("lib.guard")
local Icons = require("core.icons")
local LoggerModule = require("lib.logger")
local Settings = require("core.settings")

--- @class Tabs
--- @field _VERSION string Module version
local Tabs = {
  _VERSION = "1.0.0",
}

--- @type Logger
local _log = nil

--- Lazy logger.
--- @return Logger
local function get_log()
  if not _log then
    _log = LoggerModule.create("tabs")
  end
  return _log
end

---------------------------------------------------------------------------
-- Process name to icon mapping
---------------------------------------------------------------------------

--- @type table<string, string>
--- Map of process names to icon category and icon name ("category.name").
local PROCESS_ICONS = {
  ["zsh"] = "shell.zsh",
  ["fish"] = "shell.fish",
  ["bash"] = "shell.bash",
  ["nu"] = "shell.nushell",
  ["pwsh"] = "shell.pwsh",
  ["powershell"] = "shell.pwsh",
  ["cmd"] = "shell.cmd",
  ["nvim"] = "tool.nvim",
  ["vim"] = "tool.nvim",
  ["git"] = "tool.git",
  ["node"] = "runtime.node",
  ["python"] = "runtime.python",
  ["python3"] = "runtime.python",
  ["ruby"] = "runtime.ruby",
  ["go"] = "runtime.go",
  ["cargo"] = "runtime.rust",
  ["rustc"] = "runtime.rust",
  ["lua"] = "runtime.lua",
  ["docker"] = "devops.docker",
  ["kubectl"] = "devops.kubernetes",
  ["ssh"] = "tool.ssh",
  ["tmux"] = "tool.tmux",
  ["htop"] = "ui.flame",
  ["btop"] = "ui.flame",
  ["top"] = "ui.flame",
}

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Get an icon for a process name.
--- @param process_name string The process name (e.g. "zsh", "nvim")
--- @return string icon The icon glyph
function Tabs.get_process_icon(process_name)
  if type(process_name) ~= "string" then
    return Icons.ui("gear")
  end

  local clean_name = process_name:match("([^/\\]+)$") or process_name
  clean_name = clean_name:gsub("%.exe$", ""):lower()

  local icon_path = PROCESS_ICONS[clean_name]
  if icon_path then
    local category, name = icon_path:match("^(%w+)%.(%w+)$")
    if category and name then
      return Icons.get(category, name)
    end
  end

  return Icons.shell("default")
end

--- Format a tab title for display.
--- @param tab table WezTerm tab info object
--- @param max_width? number Maximum title width (default from settings)
--- @return string title The formatted title
function Tabs.format_title(tab, max_width)
  max_width = max_width or Settings.get("tab_bar.max_width", 30)

  local title = tab.tab_title
  if not title or #title == 0 then
    local pane = tab.active_pane
    if pane then
      title = pane.title or ""
    end
  end

  if not title or #title == 0 then
    title = "shell"
  end

  -- Get process icon
  local pane = tab.active_pane
  local process_name = ""
  if pane and pane.foreground_process_name then
    process_name = pane.foreground_process_name
  end

  local icon = Tabs.get_process_icon(process_name)

  -- Tab index (1-based for display)
  local index = (tab.tab_index or 0) + 1

  -- Build title
  local formatted = string.format(" %s %d: %s ", icon, index, title)

  -- Truncate if needed
  if #formatted > max_width then
    formatted = formatted:sub(1, max_width - 1) .. "…"
  end

  return formatted
end

--- Build the tab bar configuration.
--- @return table config Tab bar config keys to merge
function Tabs.build()
  local tab_bar_settings = Settings.get("tab_bar", {})

  local config = {
    enable_tab_bar = tab_bar_settings.enabled ~= false,
    tab_bar_at_bottom = (tab_bar_settings.position or "Top") == "Bottom",
    use_fancy_tab_bar = false, -- We use custom formatting
    show_tab_index_in_tab_bar = false,
    show_new_tab_button_in_tab_bar = tab_bar_settings.show_new_tab_button ~= false,
    show_close_tab_button_in_tabs = tab_bar_settings.show_close_button ~= false,
    hide_tab_bar_if_only_one_tab = tab_bar_settings.hide_when_single or false,
    tab_max_width = tab_bar_settings.max_width or 30,

    -- Color configuration from centralized Colors
    colors = Colors.to_wezterm_scheme(),
  }

  get_log():info("Tab bar configuration built", {
    position = tab_bar_settings.position or "Top",
    fancy = "false",
  })

  return config
end

return Tabs

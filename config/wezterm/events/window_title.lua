--- @module "events.window_title""
--- @description Window title formatting event handler.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local M = {}

--- Register the format-window-title event.
--- @param wezterm table The wezterm module
function M.register(wezterm)
  wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
    local title = pane.title or "WezTerm"

    if #tabs > 1 then
      title = string.format("[%d/%d] %s", tab.tab_index + 1, #tabs, title)
    end

    local workspace = tab.active_pane and tab.active_pane.domain_name or ""
    if workspace and #workspace > 0 and workspace ~= "local" then
      title = title .. " — " .. workspace
    end

    return title
  end)
end

return M

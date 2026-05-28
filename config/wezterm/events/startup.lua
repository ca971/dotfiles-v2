--- @module "events.startup""
--- @description GUI startup event handler.
--- Configures initial window size, position, and workspace.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Settings = require("core.settings")

local M = {}

--- Register the gui-startup event.
--- @param wezterm table The wezterm module
function M.register(wezterm)
  wezterm.on("gui-startup", function(cmd)
    local mux = wezterm.mux

    local cols = Settings.get("window.initial_cols", 120)
    local rows = Settings.get("window.initial_rows", 35)

    local tab, pane, window = mux.spawn_window(cmd or {})

    -- Optionally set initial workspace name
    window:set_workspace("main")
  end)
end

return M

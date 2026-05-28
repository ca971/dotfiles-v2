--- @module "events.new_tab""
--- @description New tab button click event handler.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local M = {}

--- Register the new-tab-button-click event.
--- @param wezterm table The wezterm module
function M.register(wezterm)
  wezterm.on("new-tab-button-click", function(window, pane, button, default_action)
    if button == "Left" then
      -- Default behavior: spawn new tab
      return default_action
    end

    if button == "Right" then
      -- Right click: show launcher
      window:perform_action(
        wezterm.action.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS" }),
        pane
      )
    end
  end)
end

return M

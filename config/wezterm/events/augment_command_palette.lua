--- @module "events.augment_command_palette""
--- @description Extends the WezTerm command palette with custom entries.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Settings = require("core.settings")

local M = {}

--- Register the augment-command-palette event.
--- @param wezterm table The wezterm module
function M.register(wezterm)
  if not Settings.get("features.command_palette_extras", true) then
    return
  end

  wezterm.on("augment-command-palette", function(window, pane)
    local entries = {
      {
        brief = "Show Cheat Sheet",
        icon = "md_help_circle",
        action = wezterm.action.EmitEvent("show-cheat-sheet"),
      },
      {
        brief = "Toggle Opacity",
        icon = "md_circle_opacity",
        action = wezterm.action.EmitEvent("toggle-opacity"),
      },
      {
        brief = "Cycle Theme",
        icon = "md_palette",
        action = wezterm.action.EmitEvent("cycle-theme"),
      },
      {
        brief = "Show Debug Overlay",
        icon = "md_bug",
        action = wezterm.action.ShowDebugOverlay,
      },
      {
        brief = "Rename Tab",
        icon = "md_rename_box",
        action = wezterm.action.PromptInputLine({
          description = "Enter new tab name",
          action = wezterm.action_callback(function(win, _, line)
            if line then
              win:active_tab():set_title(line)
            end
          end),
        }),
      },
      {
        brief = "Rename Workspace",
        icon = "md_folder_edit",
        action = wezterm.action.PromptInputLine({
          description = "Enter new workspace name",
          action = wezterm.action_callback(function(win, _, line)
            if line then
              win:set_workspace(line)
            end
          end),
        }),
      },
    }

    return entries
  end)
end

return M

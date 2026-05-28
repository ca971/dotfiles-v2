--- @module "core.launch""
--- @description Launch menu and default program configuration.
--- Builds the launch menu with detected shells, custom entries,
--- and platform-specific programs. Configures the default shell
--- based on user preferences and platform detection.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Guard = require("lib.guard")
local Icons = require("core.icons")
local LoggerModule = require("lib.logger")
local Settings = require("core.settings")
local ShellModule = require("lib.shell")

--- @class Launch
--- @field _VERSION string Module version
local Launch = {
  _VERSION = "1.0.0",
}

--- @type Logger
local _log = nil

--- Lazy logger.
--- @return Logger
local function get_log()
  if not _log then
    _log = LoggerModule.create("launch")
  end
  return _log
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Build the launch configuration (default program + launch menu).
--- @param platform_info table Platform detection info from lib.platform
--- @return table config Launch-related config keys to merge
function Launch.build(platform_info)
  Guard.is_table(platform_info, "platform_info")

  local detector = ShellModule.get_detector(platform_info)
  detector:detect()

  -- Determine default program
  local default_program = nil
  local preferred = Settings.get("shell.preferred", { "zsh", "fish", "bash" })
  local login = Settings.get("shell.login_shell", true)

  for _, shell_name in ipairs(preferred) do
    local shell = detector:get(shell_name)
    if shell then
      default_program = { shell.path }
      if login and shell.is_login and shell.args then
        for _, arg in ipairs(shell.args) do
          default_program[#default_program + 1] = arg
        end
      end
      get_log():info("Default shell selected", {
        shell = shell_name,
        path = shell.path,
      })
      break
    end
  end

  -- Build launch menu
  local launch_menu = {}

  -- Add detected shells
  local shell_menu = detector:build_launch_menu()
  for _, entry in ipairs(shell_menu) do
    local icon = Icons.shell(entry.label:lower()) or ""
    entry.label = icon .. " " .. entry.label
    launch_menu[#launch_menu + 1] = entry
  end

  -- Add platform-specific entries
  if platform_info.os == "linux" or platform_info.os == "bsd" then
    launch_menu[#launch_menu + 1] = {
      label = Icons.ui("gear") .. " htop",
      args = { "htop" },
    }
    launch_menu[#launch_menu + 1] = {
      label = Icons.ui("gear") .. " btop",
      args = { "btop" },
    }
  end

  if platform_info.os == "macos" then
    launch_menu[#launch_menu + 1] = {
      label = Icons.ui("gear") .. " Activity Monitor (top)",
      args = { "top" },
    }
  end

  -- Add WSL distributions if on Windows
  if platform_info.os == "windows" then
    -- Attempt to list WSL distros
    local handle = io.popen("wsl --list --quiet 2>nul")
    if handle then
      local output = handle:read("*a")
      handle:close()
      if output then
        for raw_distro in output:gmatch("([^\r\n]+)") do
          local distro = raw_distro:gsub("%z", "") -- Remove null chars into new variable
          if #distro > 0 then
            launch_menu[#launch_menu + 1] = {
              label = Icons.get("env", "wsl") .. " WSL: " .. distro,
              args = { "wsl", "--distribution", distro },
            }
          end
        end
      end
    end
  end

  local config = {
    launch_menu = launch_menu,
  }

  if default_program then
    config.default_prog = default_program
  end

  get_log():info("Launch menu built", {
    entries = tostring(#launch_menu),
    default = default_program and default_program[1] or "system default",
  })

  return config
end

return Launch

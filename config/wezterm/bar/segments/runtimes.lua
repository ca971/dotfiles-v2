--- @module "bar.segments.runtimes""
--- @description Runtime detection segment.
--- Shows detected programming language runtimes (Node, Python, Ruby,
--- Go, Rust, Lua, Nix, Deno, Bun) with version info.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

local Colors = require("core.colors")
local Icons = require("core.icons")
local ProcessModule = require("lib.process")
local Settings = require("core.settings")

local M = {}

--- @type table<number, string>
--- Runtimes to check in display order.
local RUNTIME_ORDER = {
  "node",
  "python",
  "ruby",
  "go",
  "rust",
  "lua",
  "nix",
  "deno",
  "bun",
  "java",
}

--- Render the runtimes segment.
--- @param wezterm table The wezterm module
--- @param context table Render context
--- @return table|nil segment BarSegment data
function M.render(wezterm, context)
  if not Settings.get("features.runtime_detection", true) then
    return nil
  end

  local detector = ProcessModule.get_detector({
    platform_info = context.platform_info,
  })

  local parts = {}

  for _, name in ipairs(RUNTIME_ORDER) do
    local info = detector:detect(name)
    if info.available then
      local icon = Icons.runtime(name)
      local version_str = info.version and (" " .. info.version) or ""
      parts[#parts + 1] = icon .. version_str
    end
  end

  if #parts == 0 then
    return nil
  end

  -- Limit displayed runtimes to avoid overflow
  local max_display = 4
  local display_text
  if #parts > max_display then
    display_text = table.concat({ table.unpack(parts, 1, max_display) }, " ")
      .. " +"
      .. (#parts - max_display)
  else
    display_text = table.concat(parts, " ")
  end

  return {
    text = display_text,
    fg = Colors.base("text"),
    bg = Colors.base("surface0"),
    priority = 45,
  }
end

return M

--- @module "bar.segments""
--- @description Segments loader and registry.
--- Lazy-loads individual segment modules and provides a unified
--- interface for the bar orchestrator to collect segment data.
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026

--- @class SegmentsRegistry
--- @field _VERSION string Module version
local Segments = {
  _VERSION = "1.0.0",
}

--- @type table<string, string>
--- Map of segment name to module path.
local SEGMENT_MAP = {
  mode = "bar.segments.mode",
  hostname = "bar.segments.hostname",
  username = "bar.segments.username",
  workspace = "bar.segments.workspace",
  cwd = "bar.segments.cwd",
  git = "bar.segments.git",
  battery = "bar.segments.battery",
  datetime = "bar.segments.datetime",
  shell = "bar.segments.shell",
  platform = "bar.segments.platform",
  environment = "bar.segments.environment",
  runtimes = "bar.segments.runtimes",
  tools = "bar.segments.tools",
  network = "bar.segments.network",
  keymap = "bar.segments.keymap",
}

--- @type table<string, table>
--- Cache for loaded segment modules.
local _loaded = {}

--- Get a segment module by name (lazy loaded).
--- @param name string Segment name
--- @return table|nil module The segment module or nil
function Segments.get(name)
  if _loaded[name] then
    return _loaded[name]
  end

  local module_path = SEGMENT_MAP[name]
  if not module_path then
    return nil
  end

  local ok, mod = pcall(require, module_path)
  if ok and type(mod) == "table" then
    _loaded[name] = mod
    return mod
  end

  return nil
end

--- Invoke a segment's render function.
--- Each segment module must export a render(wezterm, context) function
--- that returns a BarSegment table or nil.
--- @param name string Segment name
--- @param wezterm table The wezterm module
--- @param context table Render context (window, pane, platform_info, etc.)
--- @return table|nil segment A BarSegment table or nil if invisible
function Segments.render(name, wezterm, context)
  local mod = Segments.get(name)
  if not mod or type(mod.render) ~= "function" then
    return nil
  end

  local ok, result = pcall(mod.render, wezterm, context)
  if ok then
    return result
  end

  return nil
end

--- List all available segment names.
--- @return table<number, string> names Array of segment names
function Segments.list()
  local names = {}
  for name, _ in pairs(SEGMENT_MAP) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

return Segments

--- @module "wezterm""
--- @description WezTerm Enterprise Configuration — Main Entry Point.
--- This is the single entry point loaded by WezTerm. It bootstraps
--- the entire modular configuration system by delegating to core/init.lua.
---
--- Architecture:
---   wezterm.lua → core/init.lua → (settings, colors, fonts, appearance,
---   tabs, keybindings, launch, multiplexer, themes, bar, events, highlights)
---
--- Local overrides: Place files in local/ directory (gitignored).
--- Secrets: Use environment variables with WEZTERM_ prefix or local/secrets.lua.
---
--- @author WezTerm Enterprise Config
--- @license MIT
--- @copyright 2025-2026
--- @see README.md for full documentation

local wezterm = require("wezterm")

-- Bootstrap the core configuration
local Core = require("core")

-- Build and return the complete configuration
return Core.build(wezterm)

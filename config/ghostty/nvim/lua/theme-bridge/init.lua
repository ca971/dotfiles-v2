-- ============================================================================
-- @module       theme-bridge
-- @description  Neovim integration module for the Ghostty shared palette.
--               Loads the active palette from theme/active.lua and applies
--               colors to Neovim through two modes:
--
--               MODE "plugin" (default, recommended):
--                 Configures a community colorscheme plugin (catppuccin.nvim,
--                 tokyonight.nvim) with the matching variant. The plugin
--                 handles all 500+ highlight groups. Terminal colors are
--                 synced from the palette.
--
--               MODE "standalone":
--                 Applies ~70 core highlight groups directly from the palette.
--                 No plugin dependency. Suitable for minimal setups.
--
--               Both modes synchronize vim.g.terminal_color_* so :terminal
--               inside Neovim matches the Ghostty palette exactly.
--
-- @usage        -- In ~/.config/nvim/init.lua (early, before plugin setup):
--               vim.opt.rtp:prepend(vim.fn.expand("~/.config/ghostty/nvim"))
--               require("theme-bridge").setup()
--
-- @since        1.0.0
-- @requires     Neovim >= 0.9.0
-- @see          theme/schema.lua — palette type definitions
-- @see          theme/init.lua   — palette loader API
-- ============================================================================

local M = {}

--- @type Palette|nil
M._palette = nil

--- @type table|nil
M._theme_api = nil

-- ── Private Helpers ─────────────────────────────────────────────────────────

--- @description  Resolve the Ghostty config root directory.
--- @param        opts? table  { ghostty_root?: string }
--- @return       string       Absolute path to ~/.config/ghostty (or override)
local function resolve_ghostty_root(opts)
	if opts and opts.ghostty_root then
		return vim.fn.expand(opts.ghostty_root)
	end
	local xdg = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")
	return xdg .. "/ghostty"
end

--- @description  Load the theme API module from the Ghostty config.
--- @param        ghostty_root string  Path to Ghostty config root
--- @return       table                The theme module table
local function load_theme_api(ghostty_root)
	local init_path = ghostty_root .. "/theme/init.lua"
	local chunk, err = loadfile(init_path)
	if not chunk then
		error(
			"[theme-bridge] Cannot load theme API from: "
				.. init_path
				.. "\n"
				.. tostring(err)
				.. "\n\nEnsure your Ghostty config is at: "
				.. ghostty_root
		)
	end
	return chunk()
end

--- @description  Ordered ANSI color names for terminal_color_* assignment.
--- @type         string[]
local ANSI_ORDER = { "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white" }

--- @description  Synchronize Neovim terminal colors with the palette's ANSI
---               values. Sets vim.g.terminal_color_0 through _15 so that
---               :terminal buffers match the Ghostty palette exactly.
--- @param        palette Palette
local function sync_terminal_colors(palette)
	for i, name in ipairs(ANSI_ORDER) do
		vim.g["terminal_color_" .. (i - 1)] = palette.ansi[name].normal
		vim.g["terminal_color_" .. (i + 7)] = palette.ansi[name].bright
	end
end

--- @description  Set a batch of highlight groups from a table.
--- @param        highlights table<string, vim.api.keyset.highlight>
local function set_highlights(highlights)
	for group, opts in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, opts)
	end
end

-- ── Plugin Mode ─────────────────────────────────────────────────────────────

--- @description  Configure catppuccin.nvim with the palette's variant.
--- @param        palette Palette
local function setup_catppuccin(palette)
	local ok, catppuccin = pcall(require, "catppuccin")
	if not ok then
		vim.notify(
			"[theme-bridge] catppuccin.nvim not installed. Install it or use mode='standalone'.",
			vim.log.levels.WARN
		)
		return false
	end

	catppuccin.setup({
		flavour = palette.meta.variant, -- "mocha", "latte", "frappe", "macchiato"
		transparent_background = false,
		term_colors = true,
	})

	vim.cmd.colorscheme("catppuccin")
	return true
end

--- @description  Configure tokyonight.nvim with the palette's variant.
--- @param        palette Palette
local function setup_tokyonight(palette)
	local ok, tokyonight = pcall(require, "tokyonight")
	if not ok then
		vim.notify(
			"[theme-bridge] tokyonight.nvim not installed. Install it or use mode='standalone'.",
			vim.log.levels.WARN
		)
		return false
	end

	tokyonight.setup({
		style = palette.meta.variant, -- "night", "storm", "day", "moon"
		terminal_colors = true,
	})

	vim.cmd.colorscheme("tokyonight")
	return true
end

--- @description  Dispatch to the appropriate plugin configurator based on
---               the palette's meta.neovim_plugin field.
--- @param        palette Palette
--- @return       boolean  true if plugin was loaded and configured
local function setup_plugin(palette)
	local plugin = palette.meta.neovim_plugin
	if plugin == "catppuccin" then
		return setup_catppuccin(palette)
	elseif plugin == "tokyonight" then
		return setup_tokyonight(palette)
	else
		vim.notify(
			"[theme-bridge] Unknown neovim_plugin: " .. tostring(plugin) .. ". Falling back to standalone mode.",
			vim.log.levels.WARN
		)
		return false
	end
end

-- ── Standalone Mode ─────────────────────────────────────────────────────────

--- @description  Apply core highlight groups directly from the palette's
---               semantic colors. Provides a complete, usable colorscheme
---               without any plugin dependency.
--- @param        palette Palette
local function apply_standalone(palette)
	local s = palette.semantic
	local fg = palette.foreground
	local bg = palette.background

	-- ── Editor UI ─────────────────────────────────────────────────────────
	set_highlights({
		-- Core
		Normal = { fg = fg, bg = bg },
		NormalFloat = { fg = fg, bg = s.bg_dark },
		NormalNC = { fg = fg, bg = bg },
		FloatBorder = { fg = s.blue, bg = s.bg_dark },
		FloatTitle = { fg = s.blue, bg = s.bg_dark, bold = true },

		-- Cursor
		Cursor = { fg = bg, bg = fg },
		CursorLine = { bg = s.bg_light },
		CursorColumn = { bg = s.bg_light },
		CursorLineNr = { fg = s.yellow, bold = true },
		LineNr = { fg = s.fg_dark },
		SignColumn = { fg = s.fg_dark, bg = bg },
		FoldColumn = { fg = s.fg_dim, bg = bg },
		Folded = { fg = s.fg_dim, bg = s.bg_light },

		-- Selection & Search
		Visual = { bg = s.bg_visual },
		VisualNOS = { bg = s.bg_visual },
		Search = { fg = bg, bg = s.bg_search },
		IncSearch = { fg = bg, bg = s.orange },
		CurSearch = { fg = bg, bg = s.orange, bold = true },
		Substitute = { fg = bg, bg = s.red },

		-- Popup menu
		Pmenu = { fg = fg, bg = s.bg_dark },
		PmenuSel = { fg = fg, bg = s.bg_visual },
		PmenuSbar = { bg = s.bg_light },
		PmenuThumb = { bg = s.fg_dark },

		-- Status & Tab lines
		StatusLine = { fg = fg, bg = s.bg_dark },
		StatusLineNC = { fg = s.fg_dim, bg = s.bg_dark },
		TabLine = { fg = s.fg_dim, bg = s.bg_dark },
		TabLineSel = { fg = fg, bg = bg, bold = true },
		TabLineFill = { bg = s.bg_dark },
		WinBar = { fg = fg, bg = bg, bold = true },
		WinBarNC = { fg = s.fg_dim, bg = bg },

		-- Separators
		WinSeparator = { fg = s.fg_dark },
		VertSplit = { fg = s.fg_dark },
		ColorColumn = { bg = s.bg_light },

		-- Messages
		MsgArea = { fg = fg },
		ModeMsg = { fg = s.blue, bold = true },
		MoreMsg = { fg = s.blue },
		WarningMsg = { fg = s.warning },
		ErrorMsg = { fg = s.error, bold = true },
		Question = { fg = s.blue },

		-- Misc UI
		Title = { fg = s.blue, bold = true },
		Directory = { fg = s.blue },
		MatchParen = { fg = s.orange, bold = true },
		NonText = { fg = s.fg_dark },
		Whitespace = { fg = s.fg_dark },
		SpecialKey = { fg = s.fg_dark },
		Conceal = { fg = s.fg_dim },
		WildMenu = { fg = bg, bg = s.blue },
	})

	-- ── Diagnostics ───────────────────────────────────────────────────────
	set_highlights({
		DiagnosticError = { fg = s.error },
		DiagnosticWarn = { fg = s.warning },
		DiagnosticInfo = { fg = s.info },
		DiagnosticHint = { fg = s.hint },
		DiagnosticOk = { fg = s.green },

		DiagnosticUnderlineError = { sp = s.error, undercurl = true },
		DiagnosticUnderlineWarn = { sp = s.warning, undercurl = true },
		DiagnosticUnderlineInfo = { sp = s.info, undercurl = true },
		DiagnosticUnderlineHint = { sp = s.hint, undercurl = true },

		DiagnosticVirtualTextError = { fg = s.error, bg = s.diff_delete },
		DiagnosticVirtualTextWarn = { fg = s.warning, bg = s.diff_change },
		DiagnosticVirtualTextInfo = { fg = s.info, bg = s.diff_change },
		DiagnosticVirtualTextHint = { fg = s.hint, bg = s.diff_add },
	})

	-- ── Diff ──────────────────────────────────────────────────────────────
	set_highlights({
		DiffAdd = { bg = s.diff_add },
		DiffChange = { bg = s.diff_change },
		DiffDelete = { bg = s.diff_delete },
		DiffText = { bg = s.bg_visual },
		Added = { fg = s.git_add },
		Changed = { fg = s.git_change },
		Removed = { fg = s.git_delete },
	})

	-- ── Git Signs ─────────────────────────────────────────────────────────
	set_highlights({
		GitSignsAdd = { fg = s.git_add },
		GitSignsChange = { fg = s.git_change },
		GitSignsDelete = { fg = s.git_delete },
	})

	-- ── Treesitter Syntax ─────────────────────────────────────────────────
	set_highlights({
		-- Comments
		["@comment"] = { fg = s.fg_dim, italic = true },

		-- Constants
		["@constant"] = { fg = s.orange },
		["@constant.builtin"] = { fg = s.orange, bold = true },
		["@constant.macro"] = { fg = s.orange },
		["@number"] = { fg = s.orange },
		["@number.float"] = { fg = s.orange },
		["@boolean"] = { fg = s.orange, bold = true },
		["@character"] = { fg = s.green },

		-- Strings
		["@string"] = { fg = s.green },
		["@string.escape"] = { fg = s.teal },
		["@string.regex"] = { fg = s.teal },
		["@string.special"] = { fg = s.teal },

		-- Functions
		["@function"] = { fg = s.blue },
		["@function.builtin"] = { fg = s.cyan, italic = true },
		["@function.call"] = { fg = s.blue },
		["@function.macro"] = { fg = s.blue },
		["@function.method"] = { fg = s.blue },
		["@function.method.call"] = { fg = s.blue },

		-- Keywords
		["@keyword"] = { fg = s.purple, bold = true },
		["@keyword.conditional"] = { fg = s.purple },
		["@keyword.coroutine"] = { fg = s.purple, italic = true },
		["@keyword.exception"] = { fg = s.purple },
		["@keyword.function"] = { fg = s.purple },
		["@keyword.import"] = { fg = s.cyan },
		["@keyword.operator"] = { fg = s.purple },
		["@keyword.repeat"] = { fg = s.purple },
		["@keyword.return"] = { fg = s.purple },

		-- Types
		["@type"] = { fg = s.yellow },
		["@type.builtin"] = { fg = s.yellow, italic = true },
		["@type.definition"] = { fg = s.yellow },
		["@type.qualifier"] = { fg = s.purple },

		-- Variables
		["@variable"] = { fg = fg },
		["@variable.builtin"] = { fg = s.red, italic = true },
		["@variable.member"] = { fg = s.teal },
		["@variable.parameter"] = { fg = s.yellow, italic = true },

		-- Punctuation
		["@punctuation.bracket"] = { fg = s.fg_dim },
		["@punctuation.delimiter"] = { fg = s.fg_dim },
		["@punctuation.special"] = { fg = s.cyan },

		-- Operators
		["@operator"] = { fg = s.cyan },

		-- Tags (HTML, JSX)
		["@tag"] = { fg = s.red },
		["@tag.attribute"] = { fg = s.yellow, italic = true },
		["@tag.delimiter"] = { fg = s.fg_dim },

		-- Markup (Markdown)
		["@markup.heading"] = { fg = s.blue, bold = true },
		["@markup.italic"] = { italic = true },
		["@markup.strong"] = { bold = true },
		["@markup.strikethrough"] = { strikethrough = true },
		["@markup.link"] = { fg = s.blue, underline = true },
		["@markup.link.url"] = { fg = s.cyan, underline = true },
		["@markup.raw"] = { fg = s.green },
		["@markup.list"] = { fg = s.purple },

		-- Misc
		["@module"] = { fg = s.yellow },
		["@property"] = { fg = s.teal },
		["@constructor"] = { fg = s.yellow },
		["@label"] = { fg = s.blue },

		-- LSP Semantic Tokens (Neovim 0.9+)
		["@lsp.type.class"] = { link = "@type" },
		["@lsp.type.decorator"] = { link = "@function" },
		["@lsp.type.enum"] = { link = "@type" },
		["@lsp.type.enumMember"] = { link = "@constant" },
		["@lsp.type.function"] = { link = "@function" },
		["@lsp.type.interface"] = { link = "@type" },
		["@lsp.type.macro"] = { link = "@function.macro" },
		["@lsp.type.method"] = { link = "@function.method" },
		["@lsp.type.namespace"] = { link = "@module" },
		["@lsp.type.parameter"] = { link = "@variable.parameter" },
		["@lsp.type.property"] = { link = "@property" },
		["@lsp.type.struct"] = { link = "@type" },
		["@lsp.type.type"] = { link = "@type" },
		["@lsp.type.variable"] = { link = "@variable" },
	})
end

-- ── Public API ──────────────────────────────────────────────────────────────

--- @class ThemeBridgeOpts
--- @field ghostty_root? string   Override path to Ghostty config (default: XDG)
--- @field mode?         "plugin"|"standalone"  Color application strategy (default: "plugin")
--- @field fallback?     boolean  Fall back to standalone if plugin unavailable (default: true)

--- @description  Initialize the theme bridge. Loads the active palette,
---               sets vim.o.background and termguicolors, syncs terminal
---               colors, and applies the colorscheme via the chosen mode.
---
--- @param        opts? ThemeBridgeOpts  Configuration options
--- @return       Palette               The loaded palette (for further use)
function M.setup(opts)
	opts = opts or {}
	local mode = opts.mode or "plugin"
	local fallback = (opts.fallback == nil) and true or opts.fallback

	-- Load theme API and active palette
	local ghostty_root = resolve_ghostty_root(opts)
	M._theme_api = load_theme_api(ghostty_root)
	M._palette = M._theme_api.get_active()

	local palette = M._palette

	-- Validate
	local valid, err = M._theme_api.validate(palette)
	if not valid then
		vim.notify("[theme-bridge] Invalid palette: " .. tostring(err), vim.log.levels.ERROR)
		return palette
	end

	-- Global options
	vim.o.termguicolors = true
	vim.o.background = (palette.meta.style == "light") and "light" or "dark"

	-- Terminal colors (always synced regardless of mode)
	sync_terminal_colors(palette)

	-- Apply colorscheme
	if mode == "plugin" then
		local ok = setup_plugin(palette)
		if not ok and fallback then
			vim.notify("[theme-bridge] Plugin unavailable, falling back to standalone.", vim.log.levels.INFO)
			apply_standalone(palette)
		end
	elseif mode == "standalone" then
		apply_standalone(palette)
	else
		vim.notify("[theme-bridge] Unknown mode: " .. mode, vim.log.levels.ERROR)
	end

	return palette
end

--- @description  Reload the palette and re-apply colors. Call this after
---               changing theme/active.lua to update Neovim without restart.
--- @param        opts? ThemeBridgeOpts  Same options as setup()
--- @return       Palette
function M.reload(opts)
	-- Clear cached palette module
	M._palette = nil
	M._theme_api = nil
	return M.setup(opts)
end

--- @description  Get the currently loaded palette. Returns nil if setup()
---               has not been called yet.
--- @return       Palette|nil
function M.get_palette()
	return M._palette
end

--- @description  Get a specific semantic color from the active palette.
---               Convenience accessor for use in statusline, custom highlights, etc.
--- @param        key string  Semantic color key (e.g. "blue", "error", "bg_dark")
--- @return       string|nil  Hex color string or nil if not found
function M.color(key)
	if not M._palette then
		return nil
	end
	return M._palette.semantic[key]
end

--- @description  Create a Neovim user command :ThemeBridgeReload and an
---               autocmd to auto-regenerate Ghostty colors when active.lua
---               is saved.
function M.setup_autocmds()
	-- User command for manual reload
	vim.api.nvim_create_user_command("ThemeBridgeReload", function()
		M.reload()
		vim.notify("[theme-bridge] Reloaded: " .. M._palette.meta.name, vim.log.levels.INFO)
	end, { desc = "Reload color theme from palette source" })

	-- Auto-sync Ghostty colors when active.lua is saved
	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = "*/theme/active.lua",
		desc = "Auto-sync Ghostty colors after palette change",
		callback = function()
			-- Regenerate Ghostty config
			local ghostty_root = resolve_ghostty_root()
			local sync_script = ghostty_root .. "/scripts/sync-theme.lua"
			local result = vim.fn.system("nvim -l " .. vim.fn.shellescape(sync_script))
			vim.notify("[theme-bridge] Ghostty sync:\n" .. result, vim.log.levels.INFO)

			-- Reload Neovim colors
			M.reload()
			vim.notify("[theme-bridge] Switched to: " .. M._palette.meta.name, vim.log.levels.INFO)
		end,
	})
end

return M

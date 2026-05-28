-- ═══════════════════════════════════════════════════════════════════════════════
-- @file config/nvim/init.lua
-- @description Neovim — hyperextensible Vim-based text editor
-- @since 1.0.0
-- ═══════════════════════════════════════════════════════════════════════════════

-- ── Bootstrap lazy.nvim ─────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- ── Leader ───────────────────────────────────────────────────────────────────
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ── Options ──────────────────────────────────────────────────────────────────
local opt = vim.opt

-- UI
opt.number = true -- line numbers
opt.relativenumber = true -- relative line numbers
opt.signcolumn = "yes:1" -- always show sign column
opt.cursorline = true -- highlight current line
opt.cursorlineopt = "number" -- only highlight the number
opt.scrolloff = 8 -- keep 8 lines visible when scrolling
opt.colorcolumn = "80,120" -- ruler at 80 and 120 cols
opt.termguicolors = true -- 24-bit color

-- Indentation
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true -- spaces, not tabs
opt.smartindent = true
opt.breakindent = true -- wrap lines with indent

-- Search
opt.ignorecase = true -- case-insensitive search
opt.smartcase = true -- ...unless uppercase in pattern
opt.hlsearch = false -- no highlight after search
opt.incsearch = true -- incremental search

-- Splits
opt.splitright = true -- vertical split → right
opt.splitbelow = true -- horizontal split → below

-- Undo & backup
opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undo"
opt.swapfile = false
opt.backup = false

-- Misc
opt.mouse = "a" -- mouse everywhere
opt.clipboard = "unnamedplus" -- system clipboard
opt.updatetime = 250 -- faster CursorHold
opt.timeoutlen = 400 -- faster key sequence timeout
opt.completeopt = "menu,menuone,noselect"
opt.inccommand = "split" -- live preview of :s
opt.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize"
opt.fillchars = { eob = " " } -- no ~ on empty lines
opt.wrap = false -- no line wrap
opt.list = true -- show whitespace
opt.listchars = { tab = "  ", trail = "·", nbsp = "⍽" }

-- ── Keymaps ──────────────────────────────────────────────────────────────────
local map = vim.keymap.set

-- Better escape
map("i", "jk", "<Esc>", { desc = "Escape" })
map("i", "kj", "<Esc>", { desc = "Escape" })

-- Move lines up/down
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Stay in visual mode when indenting
map("v", "<", "<gv", { desc = "Dedent" })
map("v", ">", ">gv", { desc = "Indent" })

-- Paste without yanking
map("v", "p", '"_dP', { desc = "Paste without yanking" })

-- Clear search highlight
map("n", "<Esc>", ":nohlsearch<CR>", { desc = "Clear highlight" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to down window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to up window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Resize windows
map("n", "<A-h>", ":vertical resize -2<CR>", { desc = "Resize left" })
map("n", "<A-l>", ":vertical resize +2<CR>", { desc = "Resize right" })
map("n", "<A-j>", ":resize -2<CR>", { desc = "Resize down" })
map("n", "<A-k>", ":resize +2<CR>", { desc = "Resize up" })

-- Quick save / quit
map("n", "<leader>w", ":w<CR>", { desc = "Write" })
map("n", "<leader>q", ":q<CR>", { desc = "Quit" })
map("n", "<leader>Q", ":qa!<CR>", { desc = "Force quit all" })

-- Buffer navigation
map("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<S-Tab>", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", ":bd<CR>", { desc = "Delete buffer" })

-- Toggle options
map("n", "<leader>tn", ":set number!<CR>", { desc = "Toggle line numbers" })
map("n", "<leader>tw", ":set wrap!<CR>", { desc = "Toggle line wrap" })
map("n", "<leader>ts", ":set spell!<CR>", { desc = "Toggle spell check" })

-- ── Auto-commands ────────────────────────────────────────────────────────────
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local general = augroup("general", { clear = true })

-- Highlight on yank
autocmd("TextYankPost", {
	group = general,
	callback = function()
		vim.highlight.on_yank({ higroup = "Visual", timeout = 200 })
	end,
})

-- Go to last location when opening a file
autocmd("BufReadPost", {
	group = general,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Strip trailing whitespace on save (except markdown)
autocmd("BufWritePre", {
	group = general,
	pattern = "*",
	callback = function()
		if vim.bo.filetype ~= "markdown" then
			vim.cmd([[%s/\s\+$//e]])
		end
	end,
})

-- Return to last edit position on open
autocmd("BufReadPost", {
	group = general,
	pattern = "*",
	callback = function()
		if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line("$") then
			vim.cmd("normal! g'\"")
		end
	end,
})

-- ── lazy.nvim Plugin Manager ─────────────────────────────────────────────────
require("lazy").setup({
	-- ── Colorscheme ──
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		opts = {
			flavour = "mocha",
			transparent_background = false,
			integrations = {
				aerial = true,
				alpha = true,
				cmp = true,
				gitsigns = true,
				indent_blankline = { enabled = true },
				lsp_trouble = true,
				mason = true,
				mini = true,
				native_lsp = { enabled = true },
				neotest = true,
				neotree = true,
				noice = true,
				notify = true,
				telescope = true,
				treesitter = true,
				which_key = true,
			},
		},
		config = function(_, opts)
			require("catppuccin").setup(opts)
			vim.cmd.colorscheme("catppuccin")
		end,
	},

	-- ── Treesitter ──
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		cmd = { "TSInstall", "TSUpdate" },
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"bash",
					"c",
					"css",
					"diff",
					"dockerfile",
					"go",
					"gomod",
					"html",
					"javascript",
					"json",
					"lua",
					"make",
					"markdown",
					"python",
					"regex",
					"rust",
					"toml",
					"tsx",
					"typescript",
					"vim",
					"vimdoc",
					"yaml",
					"zig",
				},
				auto_install = true,
				highlight = { enable = true },
				indent = { enable = true },
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<CR>",
						node_incremental = "<CR>",
						scope_incremental = "<S-CR>",
						node_decremental = "<BS>",
					},
				},
			})
		end,
	},

	-- ── Telescope ──
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = "Telescope",
		keys = {
			{ "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
			{ "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
			{ "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
			{ "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
			{ "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
			{ "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", desc = "Document symbols" },
			{ "<leader>fc", "<cmd>Telescope commands<CR>", desc = "Commands" },
			{ "<leader>fk", "<cmd>Telescope keymaps<CR>", desc = "Keymaps" },
			{ "<leader>f.", "<cmd>Telescope find_files cwd=~/.dotfiles<CR>", desc = "Dotfiles" },
		},
		opts = {
			defaults = {
				layout_strategy = "horizontal",
				layout_config = { prompt_position = "top", width = 0.9 },
				sorting_strategy = "ascending",
				mappings = {
					i = {
						["<C-j>"] = "move_selection_next",
						["<C-k>"] = "move_selection_previous",
					},
				},
			},
		},
	},

	-- ── LSP ──
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		cmd = "Mason",
		config = true,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"lua_ls",
				"pyright",
				"rust_analyzer",
				"gopls",
				"ts_ls",
				"bashls",
				"yamlls",
				"jsonls",
				"taplo",
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- LSP keymaps
			vim.api.nvim_create_autocmd("LspAttach", {
				group = augroup("lsp", { clear = true }),
				callback = function(ev)
					local opts = { buffer = ev.buf }
					map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition", buffer = ev.buf })
					map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration", buffer = ev.buf })
					map("n", "gr", vim.lsp.buf.references, { desc = "References", buffer = ev.buf })
					map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation", buffer = ev.buf })
					map("n", "K", vim.lsp.buf.hover, { desc = "Hover", buffer = ev.buf })
					map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename", buffer = ev.buf })
					map("n", "<leader>ca", vim.lsp.buf.code_action, {
						desc = "Code action",
						buffer = ev.buf,
					})
					map("n", "<leader>e", vim.diagnostic.open_float, {
						desc = "Diagnostics",
						buffer = ev.buf,
					})
					map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic", buffer = ev.buf })
					map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic", buffer = ev.buf })
				end,
			})
		end,
	},

	-- ── Completion ──
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lsp",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"rafamadriz/friendly-snippets",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
				}),
			})
		end,
	},

	-- ── Git ──
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "▎" },
				topdelete = { text = "▎" },
				changedelete = { text = "▎" },
			},
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns
				local function map_git(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end
				map_git("n", "]c", function()
					if vim.wo.diff then
						return "]c"
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Next hunk" })
				map_git("n", "[c", function()
					if vim.wo.diff then
						return "[c"
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return "<Ignore>"
				end, { expr = true, desc = "Previous hunk" })
				map_git("n", "<leader>gp", gs.preview_hunk, { desc = "Preview hunk" })
				map_git("n", "<leader>gb", gs.blame_line, { desc = "Blame line" })
				map_git("n", "<leader>gB", function()
					gs.blame_line({ full = true })
				end, { desc = "Blame line (full)" })
			end,
		},
	},

	-- ── Which-key ──
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "modern",
			delay = 400,
		},
	},

	-- ── Status line ──
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				theme = "catppuccin",
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { { "filename", path = 1 } },
				lualine_x = { "encoding", "fileformat", "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		},
	},

	-- ── File explorer ──
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		cmd = "Neotree",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		keys = {
			{ "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle file explorer" },
		},
		opts = {
			window = { width = 35 },
			filesystem = { filtered_items = { visible = true, hide_dotfiles = false } },
		},
	},

	-- ── Indent guides ──
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			indent = { char = "▏" },
			scope = { enabled = true, show_start = false },
		},
	},

	-- ── Auto-pairs ──
	{
		"echasnovski/mini.pairs",
		version = "*",
		event = "InsertEnter",
		config = true,
	},

	-- ── Comment ──
	{
		"echasnovski/mini.comment",
		version = "*",
		event = "VeryLazy",
		opts = {
			mappings = {
				comment = "<leader>c",
				comment_line = "<leader>cc",
				comment_visual = "<leader>c",
			},
		},
	},

	-- ── Surround ──
	{
		"echasnovski/mini.surround",
		version = "*",
		event = "VeryLazy",
		config = true,
	},

	-- ── Todo comments ──
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			signs = false,
			keywords = {
				FIX = { icon = "", color = "error", alt = { "FIXME", "BUG" } },
				TODO = { icon = "", color = "info" },
				HACK = { icon = "", color = "warning" },
				WARN = { icon = "", color = "warning" },
				PERF = { icon = "", color = "default" },
				NOTE = { icon = "", color = "hint" },
			},
		},
		keys = {
			{ "<leader>ft", "<cmd>TodoTelescope<CR>", desc = "Find todos" },
		},
	},

	-- ── Trouble (diagnostics list) ──
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (Trouble)" },
			{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer diagnostics" },
			{ "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Location list" },
			{ "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list" },
		},
		opts = {},
	},
})

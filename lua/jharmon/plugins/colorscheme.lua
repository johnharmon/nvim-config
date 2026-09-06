--- Colorschemes.
---
--- Only the active one (config.colorscheme, tokyonight by default) is a start
--- plugin. The rest are lazy: lazy.nvim loads a colorscheme plugin on
--- ColorSchemePre, so `:colorscheme eldritch` still works and `:Telescope
--- colorscheme` still lists them, without paying for 14 themes at startup.
---
--- The old config ran each theme's setup() from `init`, which force-loaded all
--- of them anyway. They use `opts` now so setup runs only when loaded.
local cfg = require("jharmon.config").get()

return {
	{
		"folke/tokyonight.nvim",
		main = "tokyonight",
		priority = 1000,
		lazy = false,
		opts = {
			transparent = true,
			styles = { sidebars = "transparent", floats = "dark" },
		},
		config = function(_, opts)
			require("tokyonight").setup(opts)
			-- Applied here rather than in core.ui so it lands after setup().
			-- jharmon.core.ui listens on ColorScheme and re-applies the float,
			-- Pmenu and terminal overrides that `transparent = true` erases.
			vim.cmd.colorscheme(cfg.colorscheme)
		end,
	},

	{ "EdenEast/nightfox.nvim", lazy = true },
	{ "neanias/everforest-nvim", lazy = true },
	{ "ianklapouch/wildberries.nvim", lazy = true },
	{ "craftzdog/solarized-osaka.nvim", lazy = true },
	{ "bluz71/vim-nightfly-colors", lazy = true },
	{ "srcery-colors/srcery-vim", lazy = true },
	{ "pineapplegiant/spaceduck", lazy = true },
	{ "challenger-deep-theme/vim", name = "challenger-deep", lazy = true },

	{
		"scottmckendry/cyberdream.nvim",
		main = "cyberdream",
		lazy = true,
		opts = {
			variant = "auto",
			italic_comments = true,
			transparent = true,
		},
	},

	{
		"DonJulve/NeoCyberVim",
		main = "NeoCyberVim",
		lazy = true,
		opts = {
			transparent = true,
		},
	},

	{
		"Shatur/neovim-ayu",
		main = "ayu",
		lazy = true,
		opts = {
			overrides = {
				Normal = { bg = "None" },
				NormalFloat = { bg = "none" },
				ColorColumn = { bg = "None" },
				SignColumn = { bg = "None" },
				Folded = { bg = "None" },
				FoldColumn = { bg = "None" },
				CursorLine = { bg = "None" },
				CursorColumn = { bg = "None" },
				VertSplit = { bg = "None" },
			},
		},
		config = function(_, opts)
			vim.o.background = "dark"
			require("ayu").setup(opts)
		end,
	},

	{
		"eldritch-theme/eldritch.nvim",
		main = "eldritch",
		lazy = true,
		opts = {
			transparent = true,
			dim_inactive = true,
		},
	},

	{
		"tiagovla/tokyodark.nvim",
		main = "tokyodark",
		lazy = true,
		opts = {
			transparent_background = true,
		},
	},

	{
		"ramojus/mellifluous.nvim",
		main = "mellifluous",
		lazy = true,
		opts = {},
	},
}

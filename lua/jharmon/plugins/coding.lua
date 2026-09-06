local cfg = require("jharmon.config").get()

local use_blink = cfg.completion == "both" or cfg.completion == "blink"
local use_cmp = cfg.completion == "both" or cfg.completion == "cmp"

return {
	-- Detect tabstop and shiftwidth automatically.
	"tpope/vim-sleuth",

	{
		"saghen/blink.cmp",
		enabled = use_blink,
		dependencies = { "rafamadriz/friendly-snippets" },
		-- Release tag so the prebuilt fuzzy-matcher binary is downloaded rather
		-- than compiled.
		version = "1.*",
		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			-- 'default': C-y accepts, C-space opens the menu / docs, C-n/C-p
			-- move, C-e hides, C-k toggles signature help.
			-- See :h blink-cmp-config-keymap.
			keymap = { preset = "default" },
			appearance = {
				nerd_font_variant = "mono",
			},
			completion = { documentation = { auto_show = false } },
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default" },
	},

	{
		"hrsh7th/nvim-cmp",
		enabled = use_cmp,
		event = "InsertEnter",
		dependencies = {
			{
				"L3MON4D3/LuaSnip",
				-- Build step gives regex support in snippets; unsupported on
				-- most Windows setups.
				build = (function()
					if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
						return
					end
					return "make install_jsregexp"
				end)(),
			},
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			luasnip.config.setup({})

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				completion = { completeopt = "menu,menuone,noinsert" },
				window = {
					completion = cmp.config.window.bordered({
						winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
					}),
					documentation = cmp.config.window.bordered({
						winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
					}),
				},
				mapping = cmp.mapping.preset.insert({
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					-- Accept. Auto-imports and expands snippets when the LSP
					-- sends one.
					["<C-y>"] = cmp.mapping.confirm({ select = true }),
					["<C-Space>"] = cmp.mapping.complete({}),
					-- <C-l>/<C-z> jump forward/back through snippet stops.
					["<C-l>"] = cmp.mapping(function()
						if luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						end
					end, { "i", "s" }),
					["<C-z>"] = cmp.mapping(function()
						if luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						end
					end, { "i", "s" }),
				}),
				sources = {
					-- group_index 0 skips loading LuaLS completions, as lazydev
					-- recommends.
					{ name = "lazydev", group_index = 0 },
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
				},
			})
		end,
	},

	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				-- No LSP fallback for languages without a standardised style.
				local disable_filetypes = { c = true, cpp = true }
				return {
					timeout_ms = 500,
					lsp_format = disable_filetypes[vim.bo[bufnr].filetype] and "never" or "fallback",
				}
			end,
			formatters_by_ft = {
				lua = { "stylua" },
			},
		},
	},

	{
		"chrisgrieser/nvim-origami",
		event = "VeryLazy",
		opts = {},
		-- Disable vim's own auto-folding. This is why core.options does not set
		-- foldlevelstart.
		init = function()
			vim.opt.foldlevel = 99
			vim.opt.foldlevelstart = 99
		end,
	},

	{
		-- The old config listed this twice, once under each org. `echasnovski`
		-- is the pre-move name of the same repo; lazy would flag the duplicate.
		"nvim-mini/mini.nvim",
		config = function()
			-- Better Around/Inside textobjects: va) vinq ci'
			require("mini.ai").setup({ n_lines = 500 })

			-- Add/delete/replace surroundings: saiw) sd' sr)'
			require("mini.surround").setup()

			local statusline = require("mini.statusline")
			statusline.setup({ use_icons = vim.g.have_nerd_font })

			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_location = function()
				return "%2l:%-2v"
			end
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter",
		-- The `master` branch is archived and breaks on Neovim 0.11+/0.12: core
		-- removed the `all` option from Query:iter_matches, so the old modules
		-- call :range() on a node *list* -> "attempt to call method 'range' (a
		-- nil value)". `main` is the supported rewrite. See :help
		-- nvim-treesitter.
		branch = "main",
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")

			-- install() is idempotent: only missing parsers are fetched.
			ts.install(require("jharmon.config").get().treesitter)

			-- `main` auto-enables nothing: start highlight + indent per buffer.
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("jharmon_treesitter", { clear = true }),
				callback = function(args)
					local buf = args.buf
					local ft = vim.bo[buf].filetype
					local lang = vim.treesitter.language.get_lang(ft) or ft

					-- vim.treesitter.start errors when no parser exists.
					if not pcall(vim.treesitter.start, buf, lang) then
						return
					end

					-- Ruby keeps its built-in indent.
					if ft ~= "ruby" then
						vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})
		end,
	},
}

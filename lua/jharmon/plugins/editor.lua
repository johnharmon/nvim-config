return {
	{
		"stevearc/oil.nvim",
		lazy = false,
		dependencies = { { "nvim-mini/mini.icons", opts = {} } },
		---@module 'oil'
		---@type oil.SetupOpts
		opts = {
			-- Take over directory buffers (`vim .`, `:e src/`).
			default_file_explorer = true,
			columns = { "icon" },
			buf_options = {
				buflisted = false,
			},
			win_options = {
				wrap = false,
				signcolumn = "no",
				cursorcolumn = false,
				foldcolumn = "0",
				spell = false,
				list = false,
				conceallevel = 3,
				concealcursor = "nvic",
			},
			delete_to_trash = false,
			skip_confirm_for_simple_edits = true,
			prompt_save_on_select_new_entry = true,
			cleanup_delay_ms = 2000,
			lsp_file_methods = {
				enabled = true,
				timeout_ms = 1000,
				autosave_changes = false,
			},
			constrain_cursor = "editable",
			watch_for_changes = true,
			-- Full replacement, not an overlay: use_default_keymaps = false.
			keymaps = {
				["g?"] = { "actions.show_help", mode = "n" },
				-- <CR> descends into directories but opens files in a vsplit,
				-- which is what makes the <leader>e sidebar usable.
				["<CR>"] = function()
					local oil = require("oil")
					local actions = require("oil.actions")
					local entry = oil.get_cursor_entry()
					if entry and entry.type == "directory" then
						return actions.select.callback()
					end
					return actions.select_vsplit.callback()
				end,
				["<S-v>"] = { "actions.select", opts = { vertical = true } },
				["<S-t>"] = { "actions.select", opts = { tab = true } },
				["<S-h>"] = { "actions.select", opts = { horizontal = true } },
				["<S-l>"] = "actions.refresh",
				["<C-p>"] = "actions.preview",
				["<C-q>"] = { "actions.close", mode = "n" },
				["-"] = { "actions.parent", mode = "n" },
				["_"] = { "actions.open_cwd", mode = "n" },
				["`"] = { "actions.cd", mode = "n" },
				["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
				["gs"] = { "actions.change_sort", mode = "n" },
				["gx"] = "actions.open_external",
				["g."] = { "actions.toggle_hidden", mode = "n" },
				["g\\"] = { "actions.toggle_trash", mode = "n" },
			},
			use_default_keymaps = false,
			view_options = {
				show_hidden = true,
				is_hidden_file = function(name)
					return name:match("^%.") ~= nil
				end,
				is_always_hidden = function()
					return false
				end,
				-- "fast" turns natural ordering off for large directories.
				natural_order = "fast",
				case_insensitive = false,
				sort = {
					{ "type", "asc" },
					{ "name", "asc" },
				},
			},
			float = {
				padding = 2,
				max_width = 0,
				max_height = 0,
				win_options = { winblend = 0 },
				preview_split = "auto",
			},
			preview_win = {
				update_on_cursor_moved = true,
				preview_method = "fast_scratch",
			},
			confirmation = {
				max_width = 0.9,
				min_width = { 40, 0.4 },
				max_height = 0.9,
				min_height = { 5, 0.1 },
				win_options = { winblend = 0 },
			},
			progress = {
				max_width = 0.9,
				min_width = { 40, 0.4 },
				max_height = { 10, 0.9 },
				min_height = { 5, 0.1 },
				minimized_border = "none",
				win_options = { winblend = 0 },
			},
		},
	},

	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		-- `master`, not `0.1.x`: the 0.1.x previewer calls removed
		-- nvim-treesitter APIs (parsers.ft_to_lang / nvim-treesitter.configs)
		-- that do not exist on the treesitter `main` branch, so opening a
		-- picker errors. master migrated the previewer to
		-- vim.treesitter.start().
		branch = "master",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },
			-- The old spec disabled this dep on have_nerd_font while also
			-- installing it unconditionally at top level. Kept enabled; see
			-- misc.lua.
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})

			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			local builtin = require("telescope.builtin")
			local map = vim.keymap.set
			map("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			map("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
			map("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
			map("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
			map("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
			map("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
			map("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			map("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
			map("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			map("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })
			map("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "[/] Fuzzily search in current buffer" })

			map("n", "<leader>s/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })

			map("n", "<leader>sn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim files" })
		end,
	},

	{
		"ThePrimeagen/harpoon",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
		keys = {
			{
				"<leader>ha",
				function()
					require("harpoon.mark").add_file()
				end,
				desc = "Harpoon: add file",
			},
			{
				"<leader>hq",
				function()
					require("harpoon.ui").toggle_quick_menu()
				end,
				desc = "Harpoon: quick menu",
			},
			{
				"<leader>hh",
				function()
					require("harpoon.ui").nav_prev()
				end,
				desc = "Harpoon: previous",
			},
			{
				"<leader>hl",
				function()
					require("harpoon.ui").nav_next()
				end,
				desc = "Harpoon: next",
			},
		},
		config = function()
			require("harpoon").setup({
				menu = {
					width = math.floor(vim.api.nvim_win_get_width(0) / 2),
				},
			})
			pcall(require("telescope").load_extension, "harpoon")
		end,
	},

	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			bigfile = { enabled = true },
			dashboard = { enabled = true },
			explorer = { enabled = true },
			indent = { enabled = true },
			input = { enabled = true },
			picker = { enabled = true },
			notifier = { enabled = true },
			quickfile = { enabled = true },
			scope = { enabled = true },
			scroll = { enabled = true },
			statuscolumn = { enabled = true },
			words = { enabled = true },
		},
	},

	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
		},
	},

	{
		"folke/which-key.nvim",
		event = "VimEnter",
		opts = {
			icons = {
				mappings = vim.g.have_nerd_font,
				keys = vim.g.have_nerd_font and {} or {
					Up = "<Up> ",
					Down = "<Down> ",
					Left = "<Left> ",
					Right = "<Right> ",
					C = "<C-…> ",
					M = "<M-…> ",
					D = "<D-…> ",
					S = "<S-…> ",
					CR = "<CR> ",
					Esc = "<Esc> ",
					ScrollWheelDown = "<ScrollWheelDown> ",
					ScrollWheelUp = "<ScrollWheelUp> ",
					NL = "<NL> ",
					BS = "<BS> ",
					Space = "<Space> ",
					Tab = "<Tab> ",
					F1 = "<F1>",
					F2 = "<F2>",
					F3 = "<F3>",
					F4 = "<F4>",
					F5 = "<F5>",
					F6 = "<F6>",
					F7 = "<F7>",
					F8 = "<F8>",
					F9 = "<F9>",
					F10 = "<F10>",
					F11 = "<F11>",
					F12 = "<F12>",
				},
			},
			spec = {
				{ "<leader>a", group = "[A]I / Claude Code" },
				{ "<leader>c", group = "[C]ode", mode = { "n", "x" } },
				{ "<leader>d", group = "[D]ocument" },
				{ "<leader>h", group = "[H]arpoon" },
				{ "<leader>r", group = "[R]ename" },
				{ "<leader>s", group = "[S]earch" },
				{ "<leader>w", group = "[W]orking set" },
				{ "<leader>t", group = "[T]oggle" },
				{ "<leader>gh", group = "Git [H]unk", mode = { "n", "v" } },
			},
		},
	},

	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	{
		-- grug-far defers all of its requires, so it is lazy without help.
		"MagicDuck/grug-far.nvim",
		cmd = { "GrugFar", "GrugFarWithin" },
		opts = {},
	},
}

return {
	{
		"simrat39/rust-tools.nvim",
		ft = "rust",
		config = function()
			local rt = require("rust-tools")
			rt.setup({
				server = {
					on_attach = function(_, bufnr)
						-- Buffer-local: <Leader>a is the Claude Code group
						-- everywhere else.
						vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
						vim.keymap.set(
							"n",
							"<Leader>a",
							rt.code_action_group.code_action_group,
							{ buffer = bufnr }
						)
						vim.bo.tabstop = 4
						vim.bo.shiftwidth = 4
						vim.bo.softtabstop = 4
						vim.bo.expandtab = true
					end,
				},
			})
		end,
	},

	{
		"Vigemus/iron.nvim",
		keys = {
			{
				"<leader>tc",
				function()
					vim.cmd("IronRepl terraform")
					vim.cmd("wincmd l")
					vim.cmd("startinsert")
				end,
				desc = "Terraform console REPL",
			},
			{ "<leader>sl", desc = "Iron: send line" },
			{ "<leader>sv", mode = "v", desc = "Iron: send selection" },
			{ "<leader>sc", desc = "Iron: send motion" },
		},
		cmd = {
			"IronAttach",
			"IronFocus",
			"IronHide",
			"IronRepl",
			"IronReplHere",
			"IronRestart",
			"IronSend",
			"IronWatch",
		},
		config = function()
			require("iron.core").setup({
				config = {
					repl_definition = {
						terraform = {
							command = { "terraform", "console" },
						},
					},
					repl_open_cmd = function(bufnr)
						vim.cmd("vertical botright 80 split")
						local win = vim.api.nvim_get_current_win()
						vim.api.nvim_win_set_buf(win, bufnr)
						-- IronBg / IronBgNC come from jharmon.core.ui.
						vim.wo[win].winhighlight =
							"Normal:IronBg,NormalNC:IronBgNC,EndOfBuffer:IronBg,SignColumn:IronBg"
						return win
					end,
				},
				keymaps = {
					send_line = "<leader>sl",
					visual_send = "<leader>sv",
					send_motion = "<leader>sc",
				},
			})
		end,
	},

	{
		"tigion/nvim-asciidoc-preview",
		ft = { "asciidoc" },
		build = "cd server && npm install --omit=dev",
		opts = {},
	},
}

local cfg = require("jharmon.config").get()

return {
	{
		-- The old config declared this twice: once at top level and once
		-- nested inside the snacks.nvim spec, with conflicting winhighlight
		-- values. Collapsed to one.
		"coder/claudecode.nvim",
		dependencies = { "folke/snacks.nvim" },
		opts = {
			terminal_cmd = cfg.claude_cmd,
			terminal = {
				snacks_win_opts = {
					wo = {
						-- ClaudeCodeBg / ClaudeCodeBorder are defined in
						-- jharmon.core.ui and re-applied on ColorScheme.
						winhighlight = "Normal:ClaudeCodeBg,NormalNC:ClaudeCodeBg,FloatBorder:ClaudeCodeBorder",
					},
				},
			},
		},
		config = true,
		keys = {
			{ "<leader>a", nil, desc = "AI/Claude Code" },
			{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
			{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
			{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
			{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
			{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
			{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
			{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
			{
				"<leader>as",
				"<cmd>ClaudeCodeTreeAdd<cr>",
				desc = "Add file",
				ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
			},
			-- Diff management
			{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
			{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
		},
	},

	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		cmd = { "CodeCompanion", "CodeCompanionActions", "CodeCompanionChat", "CodeCompanionCmd" },
		keys = {
			{ "<leader>ch", "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle CodeCompanion Chat" },
			{ "<leader>cca", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion actions" },
		},
		opts = {
			display = {
				chat = {
					show_settings = true,
				},
			},
			adapters = {
				-- Self-hosted ollama on the LAN; see config.codecompanion.
				ollama = function()
					return require("codecompanion.adapters").extend("ollama", {
						schema = {
							model = {
								default = cfg.codecompanion.model,
							},
						},
						env = {
							url = cfg.codecompanion.url,
						},
						headers = {
							["Content-Type"] = "application/json",
						},
						parameters = {
							sync = true,
						},
					})
				end,
				opts = {
					allow_insecure = cfg.codecompanion.allow_insecure,
					proxy = cfg.codecompanion.proxy,
				},
			},
			strategies = {
				chat = { adapter = "ollama" },
				inline = { adapter = "ollama" },
				cmd = { adapter = "ollama" },
			},
		},
	},
}

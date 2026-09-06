return {
	"ThePrimeagen/vim-be-good",

	{ "nvim-tree/nvim-web-devicons", opts = {} },

	{
		"uga-rosa/ccc.nvim",
		keys = {
			{ "<leader>cp", "<cmd>CccPick<cr>", desc = "Color picker" },
			{ "<leader>cc", "<cmd>CccConvert<cr>", desc = "Convert color format" },
		},
		opts = {
			highlighter = {
				auto_enable = true,
			},
		},
	},
}

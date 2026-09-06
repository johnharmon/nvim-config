local cfg = require("jharmon.config").get()
local uv = vim.uv or vim.loop

local specs = {
	{
		"ramilito/kubectl.nvim",
		-- Release tag so the prebuilt binary is downloaded rather than built.
		version = "2.*",
		dependencies = "saghen/blink.download",
		keys = {
			{
				"<leader>k",
				function()
					require("kubectl").toggle({ tab = true })
				end,
				desc = "kubectl",
			},
		},
		opts = {},
	},
}

-- Local, unpublished LSP for ACM/Helm YAML. Skipped entirely when the checkout
-- is missing, so this config still starts on another machine.
if uv.fs_stat(cfg.acm_ls.dir) then
	table.insert(specs, {
		dir = cfg.acm_ls.dir,
		name = "acm-ls",
		ft = { "yaml", "helm" },
		config = function()
			require("acm-ls").setup({
				cmd = { cfg.acm_ls.cmd },
				highlights = cfg.acm_ls.highlights,
			})
		end,
	})
end

return specs

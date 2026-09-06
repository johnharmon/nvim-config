local M = {}

function M.setup()
	local group = vim.api.nvim_create_augroup("jharmon_core", { clear = true })

	-- Highlight on yank. Try it with `yap`.
	vim.api.nvim_create_autocmd("TextYankPost", {
		group = group,
		desc = "Highlight when yanking (copying) text",
		callback = function()
			local hl = vim.hl or vim.highlight
			hl.on_yank()
		end,
	})

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = "netrw",
		callback = function()
			vim.opt_local.relativenumber = true
		end,
	})

	-- terraform-ls formats and validates on write.
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = group,
		pattern = { "*.tf", "*.tfvars" },
		callback = function()
			vim.lsp.buf.format()
		end,
	})

	vim.filetype.add({
		extension = {
			jinja = "jinja",
			jinja2 = "jinja",
			j2 = "jinja",
			py = "python",
		},
		-- Helm chart templates are yaml-with-{{...}}: the plain yaml parser
		-- bails on the template syntax, the `helm` parser injects yaml between
		-- the template blocks.
		pattern = {
			[".*/templates/.*%.ya?ml"] = "helm",
			[".*/templates/.*%.tpl"] = "helm",
			["helmfile.*%.ya?ml"] = "helm",
		},
	})
end

return M

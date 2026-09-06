--- Language servers configured with the built-in vim.lsp.config API (0.11+).
--- Servers that come from mason/lspconfig live in jharmon.plugins.lsp instead;
--- these three are started from binaries expected on $PATH.
local M = {}

function M.setup()
	local cfg = require("jharmon.config").get()

	vim.lsp.config("pyright", {
		cmd = { "pyright-langserver", "--stdio" },
		filetypes = { "python" },
		root_markers = {
			"pyproject.toml",
			"setup.py",
			"setup.cfg",
			"requirements.txt",
			"Pipfile",
			"pyrightconfig.json",
			".git",
		},
		settings = {
			python = {
				analysis = {
					autoSearchPaths = true,
					diagnosticMode = "openFilesOnly",
					useLibraryCodeForTypes = true,
				},
			},
		},
	})
	vim.lsp.enable("pyright")

	vim.lsp.config("zls", {
		cmd = { "zls" },
		filetypes = { "zig", "zon" },
		root_markers = { "build.zig", "build.zig.zon", ".git" },
		settings = {
			zls = {
				enable_build_on_save = true,
			},
		},
	})
	vim.lsp.enable("zls")

	-- terraform-ls must be on PATH: brew install hashicorp/tap/terraform-ls
	vim.lsp.config("terraformls", {
		settings = {
			terraform = {
				path = cfg.terraform_path,
			},
		},
	})
	vim.lsp.enable("terraformls")

	-- Borders on hover / signature popups. Without these the floats inherit the
	-- transparent background from the theme and become unreadable.
	vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "solid" })

	vim.lsp.handlers["textDocument/signatureHelp"] = function(_, result, ctx, config)
		config = config or {}
		config.border = "double"
		return vim.lsp.handlers.signature_help(_, result, ctx, config)
	end

	vim.diagnostic.config({
		virtual_text = true,
		underline = true,
		update_in_insert = true,
		float = { border = "single" },
	})
end

return M

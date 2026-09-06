return {
	{
		-- lazydev configures the Lua LSP for the Neovim config, runtime and
		-- plugins: completion, annotations and signatures for the vim.* API.
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		},
	},
	{ "Bilal2453/luvit-meta", lazy = true },

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			-- mason must load before anything that depends on it.
			{ "williamboman/mason.nvim", config = true },
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			-- Buffer-local LSP keymaps, attached per client.
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("jharmon-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc, mode)
						vim.keymap.set(mode or "n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					local builtin = require("telescope.builtin")
					map("gd", builtin.lsp_definitions, "[G]oto [D]efinition")
					map("gr", builtin.lsp_references, "[G]oto [R]eferences")
					map("gI", builtin.lsp_implementations, "[G]oto [I]mplementation")
					map("<leader>D", builtin.lsp_type_definitions, "Type [D]efinition")
					map("<leader>ds", builtin.lsp_document_symbols, "[D]ocument [S]ymbols")
					map("<leader>ws", builtin.lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
					-- Declaration, not definition: in C this is the header.
					map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if not client then
						return
					end

					-- client.supports_method was removed in 0.12 in favour of
					-- client:supports_method.
					local function supports(method)
						if client.supports_method then
							return client:supports_method(method)
						end
						return false
					end

					-- Highlight the word under the cursor once it rests there.
					if supports(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
						local highlight_augroup =
							vim.api.nvim_create_augroup("jharmon-lsp-highlight", { clear = false })

						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("jharmon-lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({
									group = "jharmon-lsp-highlight",
									buffer = event2.buf,
								})
							end,
						})
					end

					if supports(vim.lsp.protocol.Methods.textDocument_inlayHint) then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "[T]oggle Inlay [H]ints")
					end
				end,
			})

			-- Servers mason should keep installed. Everything started from a
			-- $PATH binary (pyright, zls, terraform-ls) is configured in
			-- jharmon.core.lsp instead.
			local servers = {
				lua_ls = {
					settings = {
						Lua = {
							completion = { callSnippet = "Replace" },
						},
					},
				},
			}

			require("mason").setup()

			local ensure_installed = vim.tbl_keys(servers)
			vim.list_extend(ensure_installed, {
				"stylua", -- formats Lua, used by conform
			})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			-- nvim-lspconfig 3.x drives everything through vim.lsp.config, so
			-- the old mason-lspconfig `handlers` table no longer applies.
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
			if ok_cmp then
				capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
			end
			local ok_blink, blink = pcall(require, "blink.cmp")
			if ok_blink then
				capabilities = blink.get_lsp_capabilities(capabilities)
			end

			for name, opts in pairs(servers) do
				vim.lsp.config(name, vim.tbl_deep_extend("force", { capabilities = capabilities }, opts))
				vim.lsp.enable(name)
			end
		end,
	},
}

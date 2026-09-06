--- User-facing configuration.
---
--- Override anything here by setting `vim.g.jharmon` in your init.lua *before*
--- `require("lazy").setup(...)`. That is the only override point that works for
--- values read inside plugin specs (paths, model names, `extras`), because lazy
--- imports the spec modules before it ever calls `require("jharmon").setup()`.
--- `opts` on the plugin spec is merged too, but only reaches the `core.*`
--- modules.
local M = {}

M.defaults = {
	-- Plugins that still call removed 0.10 APIs spam vim.deprecate() on every
	-- buffer. Set false to hear them again.
	silence_deprecations = true,

	-- Applied by core.ui after the theme plugin's setup() has run.
	colorscheme = "tokyonight-night",

	-- True when the terminal font is a Nerd Font. Drives icon choices in
	-- which-key, mini.statusline and lazy's own UI.
	nerd_font = false,

	-- Only applied when the binary actually exists, so the config still starts
	-- on a machine without fish.
	shell = "/opt/homebrew/bin/fish",
	undodir = vim.env.HOME .. "/.vim/undodir",

	-- Which completion engine to install: "both" | "blink" | "cmp".
	-- "both" reproduces the original config, which had blink.cmp and nvim-cmp
	-- installed side by side.
	completion = "both",

	claude_cmd = vim.env.HOME .. "/.local/bin/claude",
	terraform_path = "/usr/local/bin/terraform",

	-- Local, unpublished LSP for ACM/Helm YAML. The spec is skipped entirely
	-- when `dir` does not exist, so this is a no-op elsewhere.
	acm_ls = {
		dir = vim.env.HOME .. "/git-projects/nvim-acm",
		cmd = nil, -- defaults to <dir>/lsp-server/acm-ls
		highlights = {
			["@lsp.type.variable.yaml"] = { fg = "#ff9e64" },
			["@lsp.type.variable.helm"] = { fg = "#ff9e64" },
			["@lsp.type.function.yaml"] = { fg = "#7aa2f7", bold = true },
			["@lsp.type.property.defaultLibrary.readonly.helm"] = { fg = "#f7768e" },
			["@lsp.typemod.keyword.defaultLibrary.helm"] = { fg = "#005500" },
		},
	},

	-- extras.working: root that holds the `.working` symlink dir.
	-- nil -> $WORKING_ROOT, then ~/git/autoshiftv2.
	working = { root = nil },

	codecompanion = {
		url = "http://192.168.86.27:11434",
		proxy = "192.168.86.27:11434",
		model = "quen3-coder:30b-32k",
		allow_insecure = true,
	},

	-- Standalone feature modules that used to live in ~/.config/nvim/plugin/.
	extras = {
		floaterm = true,
		working = true,
		kubectl_kinds = true,
	},

	-- Treesitter parsers kept installed and updated.
	treesitter = {
		"bash",
		"c",
		"cpp",
		"css",
		"diff",
		"dockerfile",
		"go",
		"gomod",
		"gotmpl",
		"helm",
		"html",
		"javascript",
		"json",
		"lua",
		"luadoc",
		"make",
		"markdown",
		"markdown_inline",
		"python",
		"query",
		"regex",
		"rust",
		"toml",
		"tsx",
		"typescript",
		"vim",
		"vimdoc",
		"yaml",
	},
}

local cache = nil

local function resolve(c)
	if not c.acm_ls.cmd then
		c.acm_ls.cmd = c.acm_ls.dir .. "/lsp-server/acm-ls"
	end
	return c
end

--- Merged configuration. Safe to call at spec-import time.
function M.get()
	if not cache then
		cache = resolve(vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), vim.g.jharmon or {}))
	end
	return cache
end

--- Merge `opts` from the plugin spec on top of what `vim.g.jharmon` produced.
function M.extend(opts)
	if opts and not vim.tbl_isempty(opts) then
		cache = resolve(vim.tbl_deep_extend("force", M.get(), opts))
	end
	return M.get()
end

return M

--- Ordered loader for everything that is not a plugin spec.
---
--- Order matters: options set `mapleader`-adjacent globals that keymaps read,
--- ui registers the ColorScheme hook *before* the theme plugin's config runs
--- (this module is loaded at priority 10000), and extras assume the core
--- keymaps already exist so their own bindings win.
local M = {}

local order = {
	"jharmon.core.options",
	"jharmon.core.clipboard",
	"jharmon.core.lsp",
	"jharmon.core.ui",
	"jharmon.core.autocmds",
	"jharmon.core.commands",
	"jharmon.core.keymaps",
}

-- Fixed order so a failure is reproducible; pairs() over the config table is not.
local extras = { "floaterm", "working", "kubectl_kinds", "kubectl_secrets" }

function M.setup()
	local cfg = require("jharmon.config").get()

	if cfg.silence_deprecations then
		vim.deprecate = function() end
	end

	for _, mod in ipairs(order) do
		require(mod).setup()
	end

	for _, name in ipairs(extras) do
		if cfg.extras[name] then
			require("jharmon.extras." .. name).setup()
		end
	end
end

return M

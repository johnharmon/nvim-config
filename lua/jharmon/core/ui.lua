--- Highlight overrides and colorscheme application.
---
--- The theme is loaded with `transparent = true`, which forces NormalFloat /
--- Pmenu / friends to bg=none and makes nvim-cmp documentation popups vanish
--- into the buffer. These overrides put a surface colour back.
---
--- nvim-cmp's `bordered()` window routes Normal -> Pmenu via winhighlight, so
--- the doc body's background comes from Pmenu, not NormalFloat. Both are set.
--- #292e42 is tokyonight's "elevated surface" tone; drop to #24283b or #1f2335
--- if it reads too bright.
---
--- Registered on ColorScheme so a `:colorscheme` switch, or a plugin reapplying
--- its own highlights, does not wipe them.
local M = {}

function M.apply()
	local hl = vim.api.nvim_set_hl

	hl(0, "NormalFloat", { bg = "#292e42" })
	hl(0, "FloatBorder", { fg = "#7aa2f7", bg = "#292e42" })
	hl(0, "Pmenu", { bg = "#292e42" })
	hl(0, "PmenuSel", { bg = "#3d59a1", bold = true })

	-- Claude Code floating window: pure black, borderless-looking.
	hl(0, "ClaudeCodeBg", { bg = "#000000" })
	hl(0, "ClaudeCodeBorder", { fg = "#000000", bg = "#000000" })

	-- iron.nvim REPL split, slightly darker than the editor.
	hl(0, "IronBg", { bg = "#16161e" })
	hl(0, "IronBgNC", { bg = "#121218" })

	-- Floaterminal.
	hl(0, "FloatermBg", { bg = "#000000" })

	hl(0, "@lsp.type.variable.helm", { fg = "#bb9af7" })

	vim.cmd.hi("Comment gui=none")
end

function M.setup()
	M.apply()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("jharmon_highlights", { clear = true }),
		callback = M.apply,
		desc = "Re-apply float/Pmenu/terminal highlight overrides",
	})
end

return M

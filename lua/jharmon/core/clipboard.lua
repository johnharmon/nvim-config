--- OSC 52 clipboard with register-type preservation.
---
--- OSC 52 sends plain text, so the register type (charwise/linewise/blockwise)
--- is lost in transit. We remember it on copy; if the system clipboard still
--- holds our own copy at paste time, the exact regtype is restored.
local M = {}

function M.setup()
	local osc52 = require("vim.ui.clipboard.osc52")

	local last_copy = { text = nil, regtype = "v" }

	local function copy_tracked(reg)
		local base = osc52.copy(reg)
		return function(lines, regtype)
			last_copy.text = table.concat(lines, "\n")
			last_copy.regtype = regtype
			base(lines)
		end
	end

	local function paste_from_system()
		if vim.fn.executable("pbpaste") == 1 then
			local text = vim.fn.system("pbpaste")
			local trimmed = text:gsub("\n$", "")
			if trimmed == last_copy.text then
				return { vim.split(trimmed, "\n"), last_copy.regtype }
			end
			-- Copied outside nvim: newline-terminated means whole lines.
			local regtype = text:sub(-1) == "\n" and "V" or "v"
			return { vim.split(trimmed, "\n"), regtype }
		end
		-- No local clipboard tool (e.g. ssh session): fall back to the unnamed
		-- register so yank/put inside this nvim still round-trips.
		return { vim.fn.getreg('"', 1, 1), vim.fn.getregtype('"') }
	end

	vim.g.clipboard = {
		name = "OSC 52",
		copy = {
			["+"] = copy_tracked("+"),
			["*"] = copy_tracked("*"),
		},
		paste = {
			["+"] = paste_from_system,
			["*"] = paste_from_system,
		},
	}
end

return M

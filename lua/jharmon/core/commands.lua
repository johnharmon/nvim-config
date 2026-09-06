--- :SessionStart <path>
---
--- Writes a session file to <path> on exit. Once a session has been loaded,
--- SessionLoadPost re-arms itself against the same file, so `nvim -S foo.vim`
--- keeps updating foo.vim without another :SessionStart.
local M = {}

function M.setup()
	local group = vim.api.nvim_create_augroup("jharmon_session", { clear = true })
	local active_session_path = nil

	vim.api.nvim_create_user_command("SessionStart", function(opts)
		local path = opts.args
		if path == "" then
			vim.notify("SessionStart requires a path", vim.log.levels.ERROR)
			return
		end

		-- Expand ~ and relative paths now: cwd may change before we exit.
		path = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
		active_session_path = path

		vim.api.nvim_create_autocmd("VimLeavePre", {
			group = group,
			callback = function()
				if active_session_path then
					vim.cmd("mksession! " .. vim.fn.fnameescape(active_session_path))
				end
			end,
		})

		vim.notify("Session started at: " .. path)
	end, {
		nargs = 1,
		complete = "file",
		desc = "Save the session to <path> on exit",
	})

	local session_started = false
	vim.api.nvim_create_autocmd("SessionLoadPost", {
		group = group,
		callback = function()
			if vim.v.this_session ~= "" and not session_started then
				session_started = true
				vim.cmd("SessionStart " .. vim.fn.fnameescape(vim.v.this_session))
			end
		end,
	})
end

return M

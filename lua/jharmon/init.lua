--- Entry point. lazy.nvim calls this via `main = "jharmon"` + `opts`.
local M = {}

function M.setup(opts)
	require("jharmon.config").extend(opts)
	require("jharmon.core").setup()
end

return M

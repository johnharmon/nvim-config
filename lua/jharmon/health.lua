--- :checkhealth jharmon
local M = {}

local h = vim.health

local function check_exe(name, path, hint)
	if path and vim.fn.executable(path) == 1 then
		h.ok(name .. ": " .. path)
	else
		h.warn(name .. " not executable: " .. tostring(path), hint and { hint } or nil)
	end
end

function M.check()
	local uv = vim.uv or vim.loop
	local cfg = require("jharmon.config").get()

	h.start("jharmon: external tools")
	check_exe("shell", cfg.shell, "brew install fish, or set vim.g.jharmon.shell")
	check_exe("claude", cfg.claude_cmd, "set vim.g.jharmon.claude_cmd")
	check_exe("terraform", cfg.terraform_path, "set vim.g.jharmon.terraform_path")
	check_exe("terraform-ls", "terraform-ls", "brew install hashicorp/tap/terraform-ls")
	check_exe("pyright-langserver", "pyright-langserver", "npm i -g pyright")
	check_exe("zls", "zls")
	check_exe("make", "make", "needed by telescope-fzf-native")
	check_exe("pbpaste", "pbpaste", "clipboard paste falls back to the unnamed register without it")

	h.start("jharmon: local plugins")
	if uv.fs_stat(cfg.acm_ls.dir) then
		h.ok("acm-ls checkout: " .. cfg.acm_ls.dir)
		if uv.fs_stat(cfg.acm_ls.cmd) then
			h.ok("acm-ls binary: " .. cfg.acm_ls.cmd)
		else
			h.warn("acm-ls binary missing: " .. cfg.acm_ls.cmd, { "build it in " .. cfg.acm_ls.dir .. "/lsp-server" })
		end
	else
		h.info("acm-ls checkout absent, spec skipped: " .. cfg.acm_ls.dir)
	end

	h.start("jharmon: settings")
	h.info("completion engine: " .. cfg.completion)
	h.info("colorscheme: " .. cfg.colorscheme)
	local enabled = {}
	for name, on in pairs(cfg.extras) do
		if on then
			table.insert(enabled, name)
		end
	end
	table.sort(enabled)
	h.info("extras: " .. (#enabled > 0 and table.concat(enabled, ", ") or "none"))
end

return M

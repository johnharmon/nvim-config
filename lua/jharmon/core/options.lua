--- All global options.
---
--- The original init.lua set options in two passes (a personal block at the top
--- and kickstart's block further down). Where the two disagreed the *second*
--- one won at runtime, so those values are the ones kept here:
---   updatetime  50  -> 250
---   scrolloff   10  (only set once, kept)
--- `foldlevelstart` is deliberately absent: nvim-origami's `init` sets both
--- foldlevel and foldlevelstart to 99, and it ran after the old top-of-file
--- `foldlevelstart = 0`. Setting it here would run *later* than origami and
--- silently re-fold every buffer.
local M = {}

function M.setup()
	local cfg = require("jharmon.config").get()
	local o = vim.opt

	vim.g.mapleader = " "
	vim.g.maplocalleader = " "
	vim.g.have_nerd_font = cfg.nerd_font

	-- Interface
	o.number = true
	o.relativenumber = true
	o.signcolumn = "yes"
	o.cursorline = true
	o.colorcolumn = "80"
	o.scrolloff = 10
	o.showmode = false
	o.showcmd = true
	o.laststatus = 2
	o.showtabline = 1
	o.termguicolors = true
	o.list = true
	o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
	o.linebreak = true
	o.showbreak = "---->"

	-- Editing
	o.tabstop = 4
	o.softtabstop = 4
	o.shiftwidth = 4
	o.expandtab = true
	o.autoindent = true
	o.breakindent = true
	o.tildeop = true
	o.virtualedit = { "block", "onemore" }
	o.mouse = "a"

	-- Search
	o.incsearch = true
	o.ignorecase = true
	o.smartcase = true
	o.inccommand = "split"

	-- Splits
	o.splitright = true
	o.splitbelow = true

	-- Timing
	o.updatetime = 250
	o.timeoutlen = 300

	-- Undo
	o.undodir = cfg.undodir
	o.undofile = true

	-- A missing shell binary makes every :! and :terminal fail, so only switch
	-- when it is actually there.
	if cfg.shell and vim.fn.executable(cfg.shell) == 1 then
		o.shell = cfg.shell
	end

	-- Scheduled because reading the system clipboard on startup costs ~50ms.
	-- Works alongside the OSC 52 provider installed by core.clipboard.
	vim.schedule(function()
		vim.opt.clipboard = "unnamedplus"
	end)
end

return M

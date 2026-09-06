--- Global keymaps.
---
--- The original config defined these across four functions (Nnoremap, Xnoremap,
--- Inoremap, Vnoremap) plus a kickstart block ~300 lines later. Where the two
--- collided the later definition won; this file keeps only the winners, with
--- the losers noted where they were.
---
--- Plugin-specific bindings are NOT here. They live in the `keys = {}` of each
--- plugin's spec under jharmon/plugins/, so they keep lazy-loading their plugin.
local M = {}

local win = require("jharmon.util.window")

-- Page mode: swap j/k for a full-page jump. Toggled with <leader>P.
local page_mode = false
local function toggle_page_mode()
	local opts = { noremap = true, silent = true }
	if page_mode then
		vim.keymap.set("n", "j", "j", opts)
		vim.keymap.set("n", "k", "k", opts)
		page_mode = false
		vim.notify("Normal mode for j/k")
	else
		vim.keymap.set("n", "j", "<PageDown>", opts)
		vim.keymap.set("n", "k", "<PageUp>", opts)
		page_mode = true
		vim.notify("Page mode for j/k")
	end
end

function M.setup()
	local map = vim.keymap.set
	local opts = { noremap = true, silent = true }

	local function m(mode, lhs, rhs, desc, extra)
		local o = vim.tbl_extend("force", opts, extra or {})
		if desc then
			o.desc = desc
		end
		map(mode, lhs, rhs, o)
	end

	-- ── File explorer (oil) ────────────────────────────────────────────────
	m("n", "<leader>E", win.oil_sidebar_reset, "Open a fresh oil sidebar")
	m("n", "<leader>e", win.oil_sidebar, "Focus or open the oil sidebar")
	m("n", "<leader>pv", vim.cmd.Ex, "Netrw in the current window")

	-- ── Window navigation and sizing ───────────────────────────────────────
	-- These override the <C-j>/<C-k> quickfix bindings the old config also
	-- defined (as `<cmd>cnext<CD>zz`, itself a typo for <CR>); the quickfix
	-- ones were dead code and are not carried over.
	m("n", "<C-h>", "<C-w><C-h>", "Move focus to the left window")
	m("n", "<C-l>", "<C-w><C-l>", "Move focus to the right window")
	m("n", "<C-j>", "<C-w><C-j>", "Move focus to the lower window")
	m("n", "<C-k>", "<C-w><C-k>", "Move focus to the upper window")
	m("n", "<C-left>", function()
		win.resize_horizontal(-1)
	end, "Move the vertical split left")
	m("n", "<C-right>", function()
		win.resize_horizontal(1)
	end, "Move the vertical split right")

	-- ── Tabs ───────────────────────────────────────────────────────────────
	m("n", "t", "gt", "Next tab")
	m("n", "T", "gt", "Next tab")

	-- ── Movement, kept centred ─────────────────────────────────────────────
	m("n", "<C-u>", "<C-u>zz")
	m("n", "<C-d>", "<C-d>zz")
	m("n", "<C-]>", "<C-]>zz")
	m("n", "n", "nzzzv")
	m("n", "N", "Nzzzv")
	m("n", "J", "mzJ`z", "Join without moving the cursor")
	m("n", "<S-j>", "<pagedown>")
	m("n", "<S-k>", function()
		vim.lsp.buf.hover({ border = "single" })
	end, "Hover documentation")
	m("n", "<Leader>P", toggle_page_mode, "Toggle page mode for j/k")

	-- ── Line moving ────────────────────────────────────────────────────────
	m("n", "-", "ddp", "Move line down")
	m("n", "_", "ddkP", "Move line up")
	m("v", "-", ":m '>+1<CR>gv=gv", "Move selection down")
	m("v", "_", ":m '<-2<CR>gv=gv", "Move selection up")
	m("v", "J", ":m '>+1<CR>gv=gv", "Move selection down")
	m("v", "K", ":m '<-2<CR>gv=gv", "Move selection up")

	-- ── Editing shortcuts ──────────────────────────────────────────────────
	m("n", "dw", "lbdw", "Delete the word under the cursor")
	m("n", "dl", "0d$", "Delete the line contents")
	m("n", "Y", "yg$", "Yank to end of line")
	m("n", "Q", "<nop>")
	m("n", 'c"', 'ci"')
	m("n", "c'", "ci'")
	m("n", "c{", "ci{")
	m("n", "c(", "ci(")
	m("n", "c[", "ci[")
	m("n", '<leader>"', 'viw<esc>a"<esc>hbi"<esc>lel', "Quote the word under the cursor")
	m("n", "<leader>'", "viw<esc>a'<esc>hbi'<esc>lel", "Single-quote the word under the cursor")
	m("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>", "Replace the word under the cursor")
	m("i", "jk", "<ESC>")
	m("i", "<S-CR>", "<CR>", nil, { silent = false })
	m("i", "<C-p>", "<esc>pi", "Paste and stay in insert")

	-- ── Registers ──────────────────────────────────────────────────────────
	-- Normal-mode <leader>d is the diagnostic float below; the old `"_d`
	-- binding it shadowed survives only in visual mode.
	m("n", "<leader>y", '"+y', "Yank to system clipboard")
	m("n", "<leader>Y", '"+Y', "Yank line to system clipboard")
	m("v", "<leader>y", '"+y', "Yank selection to system clipboard")
	m("v", "<leader>d", '"_d', "Delete selection into the void register")
	m("x", "<leader>p", '"_dP', "Paste over selection, keeping the register")

	-- ── Search / diagnostics ───────────────────────────────────────────────
	m("n", "<Esc>", "<cmd>nohlsearch<CR>")
	m("n", "<leader>ic", ":set ignorecase! | echo 'set ic!'<CR>", "Toggle ignorecase")
	m("n", "<leader>d", function()
		vim.diagnostic.open_float()
	end, "Open the diagnostic float")
	m("n", "<leader>q", function()
		vim.diagnostic.setloclist()
		vim.cmd("wincmd j")
	end, "Open the diagnostic [Q]uickfix list")

	-- ── Terminal ───────────────────────────────────────────────────────────
	m("t", "<Esc><Esc>", "<C-\\><C-n>", "Exit terminal mode")
	m("t", "<C-\\>", "<C-\\><C-n>", "Exit terminal mode")

	-- ── External ───────────────────────────────────────────────────────────
	m("n", "<C-f>", "<cmd>silent !tmux ne tmux-sessionizer<CR>", "tmux sessionizer")
end

return M

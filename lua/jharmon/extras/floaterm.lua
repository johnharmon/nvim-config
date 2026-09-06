--- Five independent floating terminals, each on its own <C-x> style key.
---
--- Toggling any one of them while a window is open hides *all* of them, so the
--- keys behave like a single overlay you can switch channels on.
---
--- Fixed from the original plugin/Floaterminal.lua: `<leader>ot`, `<leader>tt`,
--- `<leader>fd` and `:Floaterminal` all called the toggle with a non-number
--- argument (nil from the keymap, an options table from the command), which
--- errored on `windows[nil]`. They now default to terminal 0.
local M = {}

local windows = {}

local function create_floating_window(opts)
	opts = opts or {}
	local width = opts.width or math.floor(vim.o.columns * 0.9)
	local height = opts.height or math.floor(vim.o.lines * 0.9)

	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	local buf
	if opts.buf and vim.api.nvim_buf_is_valid(opts.buf) then
		buf = opts.buf
	else
		buf = vim.api.nvim_create_buf(false, true) -- scratch, no file
	end

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
	})

	vim.api.nvim_set_option_value(
		"winhl",
		"Normal:FloatermBg,NormalFloat:FloatermBg,FloatBorder:FloatermBg",
		{ win = win }
	)

	return { buf = buf, win = win }
end

---@param idx integer|nil terminal slot, defaults to 0
function M.toggle(idx)
	idx = type(idx) == "number" and idx or 0

	local state = windows[idx] or { buf = -1, win = -1 }

	if not vim.api.nvim_win_is_valid(state.win) then
		state = create_floating_window({ buf = state.buf })
		if vim.bo[state.buf].buftype ~= "terminal" then
			vim.cmd.terminal()
		end
		windows[idx] = state
	else
		-- Any visible slot closes, so the overlay never stacks.
		for _, winbuf in pairs(windows) do
			if vim.api.nvim_win_is_valid(winbuf.win) then
				vim.api.nvim_win_hide(winbuf.win)
			end
		end
	end
end

function M.setup()
	vim.api.nvim_create_user_command("Floaterminal", function(opts)
		M.toggle(tonumber(opts.args))
	end, { nargs = "?", desc = "Toggle a floating terminal (0-4)" })

	local function slot(idx)
		return function()
			M.toggle(idx)
		end
	end

	local opts = { noremap = true, silent = true }
	vim.keymap.set("n", "<leader>ot", slot(0), vim.tbl_extend("force", opts, { desc = "Toggle floating terminal" }))
	vim.keymap.set("n", "<leader>tt", slot(0), vim.tbl_extend("force", opts, { desc = "Toggle floating terminal" }))
	vim.keymap.set("n", "<leader>fd", slot(0), vim.tbl_extend("force", opts, { desc = "Toggle floating terminal" }))
	vim.keymap.set("n", "<C-c>", slot(0), vim.tbl_extend("force", opts, { desc = "Floating terminal 0" }))
	vim.keymap.set("n", "<C-x>", slot(1), vim.tbl_extend("force", opts, { desc = "Floating terminal 1" }))
	vim.keymap.set("n", "<C-z>", slot(2), vim.tbl_extend("force", opts, { desc = "Floating terminal 2" }))
	vim.keymap.set("n", "<C-a>", slot(3), vim.tbl_extend("force", opts, { desc = "Floating terminal 3" }))
	vim.keymap.set("n", "<C-s>", slot(4), vim.tbl_extend("force", opts, { desc = "Floating terminal 4" }))
end

return M

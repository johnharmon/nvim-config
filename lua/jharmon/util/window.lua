--- Window helpers shared by the core keymaps.
local M = {}

local OIL_WIDTH = 30

local function focus_oil_sidebar()
	vim.cmd("wincmd H")
	vim.cmd("vertical resize " .. OIL_WIDTH)
end

--- <leader>E: force a fresh oil sidebar on the far left.
function M.oil_sidebar_reset()
	if vim.bo.filetype == "oil" then
		return
	end
	focus_oil_sidebar()
	require("oil").open(".")
end

--- <leader>e: focus the oil sidebar, reusing one if it is already open.
--- Walks left window by window; `wincmd h` is a no-op at the leftmost window,
--- which is how the loop terminates.
function M.oil_sidebar()
	if vim.bo.filetype == "oil" then
		focus_oil_sidebar()
		return
	end

	while true do
		local before = vim.api.nvim_get_current_win()
		vim.cmd("wincmd h")
		local after = vim.api.nvim_get_current_win()
		if before == after or vim.bo.filetype == "oil" then
			break
		end
	end

	if vim.bo.filetype ~= "oil" then
		vim.cmd("vsplit")
		focus_oil_sidebar()
		require("oil").open(".")
	else
		focus_oil_sidebar()
	end
end

--- Resize so the *vertical separator to the left of the cursor* moves.
---
--- Plain `vertical resize` always grows the current window to the right, which
--- feels backwards when you are in the rightmost window. `dir` is -1 for
--- <C-left> and 1 for <C-right>; we detect which edge we are on and flip the
--- sign so the visible border always travels the direction of the arrow.
---@param dir -1|1
function M.resize_horizontal(dir)
	local step = 10 * dir
	local cur = vim.api.nvim_get_current_win()

	vim.cmd("wincmd l")
	local right = vim.api.nvim_get_current_win()

	if right == cur then
		-- Rightmost window: the only movable border is our left one.
		vim.cmd("vertical resize " .. (-step))
		return
	end

	-- Not rightmost. Return, then step one further left to see whether a
	-- window exists on that side.
	vim.cmd("wincmd h")
	vim.cmd("wincmd h")
	local left = vim.api.nvim_get_current_win()

	if left ~= cur then
		vim.cmd("vertical resize " .. step)
		vim.cmd("wincmd l")
	else
		-- Leftmost window: resize in place.
		vim.cmd("vertical resize " .. step)
	end
end

return M

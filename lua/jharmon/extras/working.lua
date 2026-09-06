--- "Working set": a directory of symlinks you can cd between.
---
--- Links live in <root>/.working, where root is config.working.root, then
--- $WORKING_ROOT, then ~/git/autoshiftv2.
---
---   :Wa <path>   add a directory
---   :Wr <name>   remove one
---   :Ww          wipe the set
---   :Wl          pick one (telescope, quickfix fallback) and cd to it
---   :Wg <name>   cd to one by name
---   :Wn          cd to the next one
local M = {}

local uv = vim.uv or vim.loop

local function get_root()
	local cfg = require("jharmon.config").get()
	return cfg.working.root or vim.env.WORKING_ROOT or (vim.env.HOME .. "/git/autoshiftv2")
end

local function get_working_dir()
	return get_root() .. "/.working"
end

local function dir_exists(path)
	local stat = uv.fs_stat(path)
	return stat and stat.type == "directory"
end

local function is_symlink(path)
	local stat = uv.fs_lstat(path)
	return stat and stat.type == "link"
end

local function list_links()
	local wdir = get_working_dir()
	if not dir_exists(wdir) then
		return {}
	end

	local handle = uv.fs_scandir(wdir)
	if not handle then
		return {}
	end

	local entries = {}
	while true do
		local name = uv.fs_scandir_next(handle)
		if not name then
			break
		end
		local full = wdir .. "/" .. name
		if is_symlink(full) then
			table.insert(entries, { name = name, target = uv.fs_readlink(full) })
		end
	end

	table.sort(entries, function(a, b)
		return a.name < b.name
	end)
	return entries
end

local function add(opts)
	local path = opts.fargs[1]
	if not path then
		vim.notify("Usage: Wa <path>", vim.log.levels.ERROR)
		return
	end

	path = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
	if not dir_exists(path) then
		vim.notify("Not a directory: " .. path, vim.log.levels.ERROR)
		return
	end

	local wdir = get_working_dir()
	vim.fn.mkdir(wdir, "p")

	local name = vim.fn.fnamemodify(path, ":t")
	local link = wdir .. "/" .. name
	if uv.fs_lstat(link) then
		vim.notify("Already in working set: " .. name, vim.log.levels.WARN)
		return
	end

	uv.fs_symlink(path, link)
	vim.notify("Added " .. name .. " -> " .. path)
end

local function remove(opts)
	local name = opts.fargs[1]
	if not name then
		vim.notify("Usage: Wr <name>", vim.log.levels.ERROR)
		return
	end

	local link = get_working_dir() .. "/" .. name
	if not is_symlink(link) then
		vim.notify("Not in working set: " .. name, vim.log.levels.WARN)
		return
	end

	os.remove(link)
	vim.notify("Removed " .. name)
end

local function wipe()
	local wdir = get_working_dir()
	if dir_exists(wdir) then
		vim.fn.delete(wdir, "rf")
		vim.notify("Working set cleared")
	else
		vim.notify("Working set already empty")
	end
end

local function list()
	local entries = list_links()
	if #entries == 0 then
		vim.notify("Working set is empty")
		return
	end

	local has_telescope, pickers = pcall(require, "telescope.pickers")
	if not has_telescope then
		local items = {}
		for _, e in ipairs(entries) do
			table.insert(items, { filename = e.target .. "/", text = e.name .. " -> " .. e.target })
		end
		vim.fn.setqflist(items, "r")
		vim.cmd("copen")
		return
	end

	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = "Working Set",
			finder = finders.new_table({
				results = entries,
				entry_maker = function(e)
					return { value = e.target, display = e.name .. " -> " .. e.target, ordinal = e.name }
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					vim.cmd.cd(selection.value)
					vim.notify("cd " .. selection.value)
				end)
				return true
			end,
		})
		:find()
end

local function goto_name(opts)
	local name = opts.fargs[1]
	if not name then
		vim.notify("Usage: Wg <name>", vim.log.levels.ERROR)
		return
	end

	local link = get_working_dir() .. "/" .. name
	if not is_symlink(link) then
		vim.notify("Not in working set: " .. name, vim.log.levels.WARN)
		return
	end

	local target = uv.fs_readlink(link)
	vim.cmd.cd(target)
	vim.notify("cd " .. target)
end

local function next_dir()
	local entries = list_links()
	if #entries == 0 then
		vim.notify("Working set is empty", vim.log.levels.WARN)
		return
	end

	local cwd = vim.fn.getcwd()
	local idx = 0
	for i, e in ipairs(entries) do
		if e.target == cwd then
			idx = i
			break
		end
	end

	local nxt = entries[(idx % #entries) + 1]
	vim.cmd.cd(nxt.target)
	vim.notify(nxt.name)
end

local function complete_names()
	local names = {}
	for _, e in ipairs(list_links()) do
		table.insert(names, e.name)
	end
	return names
end

local function complete_dirs(arg_lead)
	return vim.fn.getcompletion(arg_lead, "dir")
end

function M.setup()
	local cmd = vim.api.nvim_create_user_command
	cmd("Wa", add, { nargs = 1, complete = complete_dirs, desc = "Add a directory to the working set" })
	cmd("Wr", remove, { nargs = 1, complete = complete_names, desc = "Remove from the working set" })
	cmd("Ww", wipe, { desc = "Wipe the working set" })
	cmd("Wl", list, { desc = "List and cd into the working set" })
	cmd("Wg", goto_name, { nargs = 1, complete = complete_names, desc = "cd to a working set entry" })
	cmd("Wn", next_dir, { desc = "cd to the next working set entry" })

	vim.keymap.set("n", "<leader>wa", ":Wa ", { desc = "Working set: add" })
	vim.keymap.set("n", "<leader>wr", ":Wr ", { desc = "Working set: remove" })
	vim.keymap.set("n", "<leader>ww", wipe, { desc = "Working set: wipe" })
	vim.keymap.set("n", "<leader>wl", list, { desc = "Working set: list" })
	vim.keymap.set("n", "<leader>wg", ":Wg ", { desc = "Working set: go to" })
	vim.keymap.set("n", "<leader>wn", next_dir, { desc = "Working set: next" })
end

return M

--- Floating kind picker for kubectl.nvim, built on telescope.
---
---   <C-r>  (inside any kubectl view) or :KubectlKinds   open the picker
---   <CR>   open the kind in the window the picker was launched from
---   <C-t>  open in a new tab
---   <C-v>  open in a vertical split
---   <C-x>  open in a horizontal split
---   <Esc>  dismiss, remembering the query for next time
local M = { last_query = nil }

--- Upstream bug shim: kubectl/resources/api-resources/mappings.lua still
--- requires "kubectl.views.overview", which moved to
--- "kubectl.resources.overview". The failure is swallowed by a pcall, which
--- silently kills every mapping in the built-in api-resources view.
package.preload["kubectl.views.overview"] = function()
	return require("kubectl.resources.overview")
end

--- Every kind the discovery cache knows about, sorted by qualified name.
local function api_resources()
	local ok, cache = pcall(require, "kubectl.cache")
	if not ok then
		return {}
	end

	local out = {}
	for key, r in pairs((cache.cached_api_resources or {}).values or {}) do
		if type(r) == "table" and r.gvk then
			out[#out + 1] = {
				key = key, -- "pods" for core, "plural.group" otherwise
				plural = r.plural,
				gvk = r.gvk,
				namespaced = r.namespaced,
				short_names = r.short_names or {},
			}
		end
	end

	table.sort(out, function(a, b)
		return a.key < b.key
	end)
	return out
end

--- Show a kind, preferring its first-class view when the GVK really matches,
--- so deployments keep grr/gss/gi, pods keep gl, nodes keep gR, etc.
local function show(rec)
	vim.schedule(function()
		local ok, mod = pcall(require, "kubectl.resources." .. rec.plural)
		local same_gvk = ok
			and mod.definition
			and mod.definition.gvk
			and (mod.definition.gvk.g or "") == (rec.gvk.g or "")
			and mod.definition.gvk.k == rec.gvk.k

		if vim.g.kubectl_kinds_debug then
			vim.notify(
				string.format(
					"kinds: key=%s plural=%s g=%q k=%q -> %s",
					rec.key,
					rec.plural,
					rec.gvk.g or "<nil>",
					rec.gvk.k,
					same_gvk and "builtin" or "fallback"
				)
			)
		end

		if same_gvk then
			local ok_view, err = xpcall(mod.View, debug.traceback)
			if not ok_view then
				vim.notify("kinds: " .. rec.key .. " view failed\n" .. err, vim.log.levels.ERROR)
			end
		else
			require("kubectl.views").resource_or_fallback(rec.key)
		end
	end)
end

---@param how "here"|"tab"|"vsplit"|"split"
local function open_kind(rec, how)
	if how == "tab" then
		vim.cmd("tabnew")
	elseif how == "vsplit" then
		vim.cmd("vsplit")
	elseif how == "split" then
		vim.cmd("split")
	end

	-- Same handshake ":Kubectl view <res>" uses: works cold or warm.
	require("kubectl").init(function(ok)
		if ok then
			show(rec)
		end
	end)
end

function M.pick()
	local ok_t, pickers = pcall(require, "telescope.pickers")
	if not ok_t then
		vim.notify("telescope not available", vim.log.levels.ERROR)
		return
	end

	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	local entries = api_resources()
	if #entries == 0 then
		vim.notify("kubectl: api-resources cache is empty - open kubectl once first", vim.log.levels.WARN)
		return
	end

	pickers
		.new({}, {
			prompt_title = "Kubernetes kinds",
			default_text = M.last_query or "",
			finder = finders.new_table({
				results = entries,
				entry_maker = function(rec)
					local sn = table.concat(rec.short_names, ",")
					return {
						value = rec,
						display = string.format(
							"%-46s %-24s %-8s%s",
							rec.key,
							rec.gvk.k,
							rec.namespaced and "ns" or "cluster",
							sn ~= "" and ("  [" .. sn .. "]") or ""
						),
						ordinal = rec.key .. " " .. rec.gvk.k .. " " .. sn,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				local function remember()
					M.last_query = action_state.get_current_line()
				end

				local function select(how)
					return function()
						local entry = action_state.get_selected_entry()
						remember()
						actions.close(prompt_bufnr)
						if entry then
							open_kind(entry.value, how)
						end
					end
				end

				actions.select_default:replace(select("here"))
				map({ "i", "n" }, "<C-t>", select("tab"))
				map({ "i", "n" }, "<C-v>", select("vsplit"))
				map({ "i", "n" }, "<C-x>", select("split"))
				map({ "i", "n" }, "<Esc>", function()
					remember()
					actions.close(prompt_bufnr)
				end)
				return true
			end,
		})
		:find()
end

function M.setup()
	vim.api.nvim_create_user_command("KubectlKinds", M.pick, { desc = "Pick a Kubernetes kind" })

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("jharmon_kubectl_kinds", { clear = true }),
		pattern = "k8s_*",
		callback = function(ev)
			vim.keymap.set("n", "<C-r>", M.pick, { buffer = ev.buf, desc = "Pick a Kubernetes kind" })
		end,
	})
end

return M

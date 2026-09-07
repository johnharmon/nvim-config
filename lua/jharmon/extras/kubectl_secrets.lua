--- Auto-decode base64 values in kubectl.nvim's Secret YAML view.
---
--- kubectl.nvim already ships a decoder, but it is one value at a time: in the
--- `k8s_secrets_yaml` view <CR> decodes the line under the cursor. This decodes
--- the whole `data:` block as soon as the view finishes loading.
---
--- Only the top-level `data:` block is touched. Annotations and labels are left
--- alone even when they happen to look like base64, and a value is only decoded
--- when it is valid base64 *and* decodes to text — so binary payloads
--- (keystores, .gz, docker config blobs) stay in their encoded form rather than
--- spraying control bytes into the buffer.
---
--- `gb` toggles between the decoded and the original view. `gr` (kubectl's
--- refresh) re-fetches and decodes again.
---
--- Note that this puts secret plaintext in a buffer. It is a scratch float that
--- is never written to disk, but it is still on screen and still yankable.
local M = {}

-- buf -> original lines, so the toggle can restore without re-fetching.
local originals = {}
-- buf -> true while we are the ones writing, so our own writes do not
-- re-trigger the on_lines handler that scheduled them.
local writing = {}
local attached = {}

local function opts()
	return require("jharmon.config").get().kubectl_secrets
end

--- Base64 needs a length that is a multiple of 4 and at most two trailing '='.
--- Rejecting on length alone throws out most look-alike annotation values.
local function looks_base64(s)
	if #s < 4 or #s % 4 ~= 0 then
		return false
	end
	return s:match("^[A-Za-z0-9+/]+=?=?$") ~= nil
end

--- Text, meaning: no NUL and no control bytes other than tab/newline/CR.
--- High bytes are allowed through so UTF-8 survives.
local function is_text(s)
	if s == "" then
		return false
	end
	for i = 1, #s do
		local b = s:byte(i)
		if b < 9 or (b > 13 and b < 32) or b == 127 then
			return false
		end
	end
	return true
end

--- Decode the `data:` block of a Secret rendered as YAML.
---@param lines string[]
---@return string[] lines, table stats
function M.decode(lines)
	local out = {}
	local stats = { decoded = 0, skipped = 0 }
	local i, n = 1, #lines

	while i <= n do
		local line = lines[i]
		out[#out + 1] = line
		i = i + 1

		if line:match("^data:%s*$") then
			while i <= n do
				local l = lines[i]
				-- The block ends at the first line that is not an indented key.
				if not l:match("^%s+%S") then
					break
				end

				local indent, key, value = l:match("^(%s+)([^:]+):%s*(%S*)%s*$")
				local ok, decoded = false, nil
				if value and value ~= "" and looks_base64(value) then
					ok, decoded = pcall(vim.base64.decode, value)
				end

				if ok and decoded and is_text(decoded) then
					local parts = vim.split((decoded:gsub("\n$", "")), "\n", { plain = true })
					if #parts == 1 then
						out[#out + 1] = indent .. key .. ": " .. parts[1]
					else
						-- A literal block keeps certs and .env payloads readable
						-- and keeps the buffer parseable as YAML.
						out[#out + 1] = indent .. key .. ": |"
						for _, p in ipairs(parts) do
							out[#out + 1] = indent .. "  " .. p
						end
					end
					stats.decoded = stats.decoded + 1
				else
					out[#out + 1] = l
					if indent then
						stats.skipped = stats.skipped + 1
					end
				end

				i = i + 1
			end
		end
	end

	return out, stats
end

local function set_lines(buf, lines)
	local modifiable = vim.bo[buf].modifiable
	writing[buf] = true
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = modifiable
	pcall(function()
		vim.bo[buf].modified = false
	end)
	writing[buf] = false
end

--- Decode the buffer in place. No-op unless the view has actually loaded and
--- something in it decoded.
---@return boolean decoded
function M.apply(buf)
	if not vim.api.nvim_buf_is_valid(buf) or vim.b[buf].jharmon_secret_decoded then
		return false
	end

	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	-- The view shows "Loading..." until the async fetch lands.
	local has_data = false
	for _, l in ipairs(lines) do
		if l:match("^data:%s*$") then
			has_data = true
			break
		end
	end
	if not has_data then
		return false
	end

	local new, stats = M.decode(lines)
	if stats.decoded == 0 then
		return false
	end

	originals[buf] = lines
	set_lines(buf, new)
	vim.b[buf].jharmon_secret_decoded = true

	if stats.skipped > 0 and opts().notify then
		vim.notify(
			string.format("secrets: decoded %d, left %d encoded (binary)", stats.decoded, stats.skipped),
			vim.log.levels.INFO
		)
	end
	return true
end

--- Put the encoded values back.
function M.restore(buf)
	local raw = originals[buf]
	if not raw then
		return false
	end
	set_lines(buf, raw)
	originals[buf] = nil
	vim.b[buf].jharmon_secret_decoded = false
	return true
end

function M.toggle(buf)
	buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
	if vim.b[buf].jharmon_secret_decoded then
		M.restore(buf)
	elseif not M.apply(buf) then
		vim.notify("No base64 data to decode in this buffer", vim.log.levels.WARN)
	end
end

--- The framed buffer is reused across opens, so FileType only fires once but
--- the content is replaced every time. Watch the buffer rather than the event.
local function watch(buf)
	if attached[buf] then
		return
	end
	attached[buf] = true

	vim.api.nvim_buf_attach(buf, false, {
		on_lines = function()
			if writing[buf] then
				return
			end
			-- Content was replaced by kubectl.nvim: this is a different secret,
			-- or a refresh of the same one.
			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(buf) then
					return
				end
				originals[buf] = nil
				vim.b[buf].jharmon_secret_decoded = false
				if opts().auto then
					M.apply(buf)
				end
			end)
		end,
		on_detach = function()
			attached[buf] = nil
			originals[buf] = nil
		end,
	})
end

function M.setup()
	local o = opts()

	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("jharmon_kubectl_secrets", { clear = true }),
		pattern = "k8s_secrets_yaml",
		callback = function(ev)
			watch(ev.buf)

			if o.key then
				vim.keymap.set("n", o.key, function()
					M.toggle(ev.buf)
				end, { buffer = ev.buf, desc = "Toggle base64 decode of the data block" })
			end

			-- The content may already be there when FileType fires.
			if o.auto then
				vim.schedule(function()
					M.apply(ev.buf)
				end)
			end
		end,
	})

	vim.api.nvim_create_user_command("KubectlSecretsDecode", function()
		M.toggle(0)
	end, { desc = "Toggle base64 decode of a kubectl Secret YAML view" })
end

return M

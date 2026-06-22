local Whaler = require'whaler'
local State = require'whaler.state'
local Snacks = require'snacks'

local defaults = {
	title = "Whaler",
	prompt = "Whaler >> ",
	preview = "file",
	format_entry = function(entry)
		if entry.alias then
			return {
				alias = "[" .. entry.alias .. "]",
				pathname = vim.fn.fnamemodify(entry.path, ":t"),
			}
		else
			return {
				alias = nil,
				pathname = entry.path
			}
		end
	end,
	keys = {
		["CR"] = "confirm",
		["<C-y>"] = { "confirm", mode = {"i", "n"}},
		["<C-n>"] = { "list_down", mode = {"i", "n"}},
		["<C-p>"] = { "list_up", mode = {"i", "n"}},
		["<C-d>"] = { "list_scroll_down", mode = {"i", "n"}},
		["<C-u>"] = { "list_scroll_up", mode = {"i", "n"}},
		["gg"] = { "list_scroll_top", mode = {"n"}},
		["G"] = { "list_scroll_bottom", mode = {"n"}},
		["<M-p>"] = { "toggle_preview", mode = {"i", "n"}},
	},
}

local format = function(entry, _)
	local ret = {}
	local fmt_entry = defaults.format_entry(entry)
	if fmt_entry.alias then
		table.insert(ret, { fmt_entry.alias .. " ", "SnacksPickerLabel"})
	end
	table.insert(ret, { fmt_entry.pathname, "SnacksPickerText"})
	return ret
end

-- This is a custom source picker in snacks
local picker = function(dirs, run_opts)

	local snacks_opts = vim.tbl_deep_extend('force', defaults, run_opts.snacks_opts or {})

	local snacks_dirs = {}

	for key,entry in pairs(dirs) do
		local fmtd = snacks_opts.format_entry(entry)
		local text = fmtd.pathname
		if fmtd.alias then
			text = fmtd.alias .. " " .. text
		end

		table.insert(snacks_dirs, {
			alias = entry.alias,
			path = entry.path,
			-- For Snacks sanity
			file = entry.path,
			text = text
		})
	end


	Snacks.picker({
		title = snacks_opts.title,
		prompt = snacks_opts.prompt,
		live = false,
		items = snacks_dirs,
		preview = snacks_opts.preview,
		format = format,
		win = {
			input = {
				keys = snacks_opts.keys
			},
		},
		confirm = function(picker, entry)
			picker:close()
			if entry then
				-- Update the state
				State:set({
					run_opts = snacks_opts
				})

				local fmt_entry = snacks_opts.format_entry(entry)
				local display = fmt_entry.pathname

				if fmt_entry.alias then
					display = fmt_entry.alias .. display
				end

				Whaler.select(entry.path, display)
			end
		end,
	})
end


return {
	picker = picker
}

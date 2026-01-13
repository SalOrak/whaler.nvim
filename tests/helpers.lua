local Helpers = {}

Helpers.directory_hierarchy = {
    personal = {
        dotfiles = {
            neovim = {},
            emacs = {},
            alacritty = {},
            aerc = {},
            tmux = {}
        },
        dot = {},
        whaler_nvim = {},
        whaler_el = {},
        libtmux_nvim = {},
        ansible_doc_nvim = {},
        note_nvim = {},
    },
    work = {
        project_one = {},
        delta_project = {},
        _ungiven = {},
        _uneven = {},
        myrustproject = {},
        hello = {}
    },
    data = {
        config = {
            nvim = {
                lazy = {}
            },
            dconf = {},
            gnome = {},
        },
    },
}


Helpers.create_directory_hierarchy = function(child, path, hierarchy)
    if not hierarchy then
        return 
    end
    for k,v in pairs(hierarchy) do
		local as_path = k:gsub("^_", ".") -- Replace _ at the beggining by .
        local parent_path = string.format("%s/%s", path, as_path)
        vim.uv.fs_mkdir(parent_path, tonumber('755',8))
        if v then 
            Helpers.create_directory_hierarchy(nil, parent_path, v)
        end
    end
end

Helpers.remove_directory_hierarchy = function(child, path, hierarchy)
    if not hierarchy then
        return 
    end
    for k,v in pairs(hierarchy) do
		local as_path = k:gsub("^_", ".") -- Replace _ at the beggining by .
        local parent_path = string.format("%s/%s", path, as_path)
        if v then
            Helpers.remove_directory_hierarchy(nil, parent_path, v)
        end

        vim.uv.fs_rmdir(parent_path)
    end
end


--- Converts a string defined function into a callable function
--- object. The string function is like this 
--- "function(a,b) print(a,b) end". This function then returns the
--- callable object of that function. It asserts
---@param str_fn string function definition in a string. See above.
---@return fn function?
Helpers.str_to_fn = function(str_fn)
	if not string.match("^return", str_fn) then
		--- Add the return keyword in case it is not added.
		str_fn = string.format("return %s", str_fn)
	end

	local callable = assert(loadstring(str_fn))()
	return callable
end

--- "Scan" a directory to retrieve all the directories. Instead of directories
--- they are keys in the table `tbl`
---@param path string Path to extract the directories.
---@param tbl table Table that represents the directories as keys.
---@param opts {hidden: boolean, follows: boolean, filter:string that defines a function): 
--- Same options as `Path:scan` function
Helpers.scan_dirs = function(path, tbl, opts)
    local split = vim.split(path, '/', { plain = true, trimempty = true})
    local res = vim.deepcopy(tbl)
    for _,key in ipairs(split) do
        local tmp = vim.tbl_get(res, key)
        if not tmp then
			return {}
        end
        res = tmp
    end

	local result = vim.tbl_keys(res)
	result = vim.tbl_map(function(directory) 
		--- Substitute '_' to '.' to create hidden directories
		return tostring(directory):gsub("^%_", ".")
	end, result)

	if not opts.hidden then
		result = vim.tbl_filter(function(dir)
			return string.match(dir, "^%.") == nil
		end, result)
	end

	--- opts.filter is a string that represents a function
	local filter_fn = function(_) return true end
	if opts.filter then
		filter_fn = Helpers.str_to_fn(opts.filter)
	end

	result = vim.tbl_filter(filter_fn, result)

	return result
end

return Helpers

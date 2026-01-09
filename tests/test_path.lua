local new_set = MiniTest.new_set

local expect = MiniTest.expect
local eq = expect.equality
local neq = expect.no_equality

local helpers = dofile('tests/helpers.lua')

local tmp_path = vim.uv.os_tmpdir()
local child = MiniTest.new_child_neovim()

local T = new_set({
	hooks = {
		pre_once = function() 
			-- Create the directories
			helpers.create_directory_hierarchy(child, tmp_path, helpers.directory_hierarchy)
		end,

		pre_case = function () 
			child.restart({'-u', 'scripts/minimal_init.lua'})
			child.lua([[ Path = require('whaler.path') ]])
		end,

		post_once = function()
			helpers.remove_directory_hierarchy(child, tmp_path, helpers.directory_hierarchy)
			child.stop()
		end
	}
})

T['parametrize'] = new_set({ parametrize = {
	{ "personal"}, 
	{ "work"}, 
	{ "personal/dotfiles"}, 
	{ "personal/dotfiles/neovim"}, 
	{ "work/project_one"}, 
	{ "data"},
	{ "data/config"},
	{ "nonexistent/config"},
}})

T['parametrize']['scan_dirs(hidden=false,follow=false, filter=nil'] = function(keypath)
	
	local opts = {
		hidden = false,
		follows = false,
		filter = "function(_) return true end",
	}

	local expected = helpers.scan_dirs(keypath, helpers.directory_hierarchy, opts)

	local str_path = string.format("%s/%s",tmp_path, keypath)
	local str_lua = string.format([[return Path:new("%s")]], str_path)
	local scan_dirs = {}
	local path = child.lua(str_lua)

	--- If the path is exists, we populate it.
	if path ~= vim.NIL then
		str_lua = string.format(
			[[return Path:new("%s"):scan(%s, %s, %s)]], 
			str_path, opts.hidden, opts.follows, opts.filter)
		scan_dirs = child.lua(str_lua)
	end

	for k,v in pairs(expected) do
		local expected_path = string.format("%s/%s/%s", tmp_path, keypath, v)
		eq(vim.tbl_contains(scan_dirs, expected_path),true)
	end
end

T['parametrize']['scan_dirs(hidden=true,follow=false, filter=nil)'] = function(keypath)

	local opts = {
		hidden = true,
		follows = false,
		filter = "function(_) return true end"
	}

	local expected = helpers.scan_dirs(keypath, helpers.directory_hierarchy, opts)

	local str_path = string.format("%s/%s",tmp_path, keypath)
	local str_lua = string.format([[return Path:new("%s")]], str_path)
	local scan_dirs = {}
	local path = child.lua(str_lua)

	--- If the path is exists, we populate it.
	if path ~= vim.NIL then
		str_lua = string.format(
			[[return Path:new("%s"):scan(%s, %s, %s)]], 
			str_path, opts.hidden, opts.follows, opts.filter)
		scan_dirs = child.lua(str_lua)
	end

	for k,v in pairs(expected) do
		local expected_path = string.format("%s/%s/%s", tmp_path, keypath, v)
		eq(vim.tbl_contains(scan_dirs, expected_path),true)
	end
end

T['parametrize']['scan_dirs(hidden=true,follow=false, filter="ends with nvim")'] = function(keypath)

	local opts = {
		hidden = true,
		follows = false,
		filter = "function(filename) return vim.endswith(filename, 'nvim') end"
	}

	local expected = helpers.scan_dirs(keypath, helpers.directory_hierarchy, opts)

	local str_path = string.format("%s/%s",tmp_path, keypath)
	local str_lua = string.format([[return Path:new("%s")]], str_path)
	local scan_dirs = {}
	local path = child.lua(str_lua)

	--- If the path is exists, we populate it.
	if path ~= vim.NIL then
		str_lua = string.format(
			[[return Path:new("%s"):scan(%s, %s, %s)]], 
			str_path, opts.hidden, opts.follows, opts.filter)
		scan_dirs = child.lua(str_lua)
	end

	for k,v in pairs(expected) do
		local expected_path = string.format("%s/%s/%s", tmp_path, keypath, v)
		eq(vim.tbl_contains(scan_dirs, expected_path),true)
	end
end

return T

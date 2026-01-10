local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality
local neq = MiniTest.expect.no_equality

local helpers = dofile('tests/helpers.lua')

local tmp_path = vim.uv.os_tmpdir()

local whaler_opts =  {
	-- Make sure the directories are represented in `helpers.directory_hierarchy`
	directories = {
		string.format("%s/personal", tmp_path),
		string.format("%s/personal/dotfiles", tmp_path),
		string.format("%s/work", tmp_path),
	},

	oneoff_directories = {
		string.format("%s/data/config/nvim/", tmp_path),
	},

	picker = "vanilla"
}

local child = MiniTest.new_child_neovim()

local T = new_set({
    hooks = {
		pre_once = function()
			helpers.create_directory_hierarchy(child, tmp_path, helpers.directory_hierarchy)
		end,
        --- For each case
        pre_case = function()
            child.restart({'-u', 'scripts/minimal_init.lua'})
            child.lua([[ M = require('whaler') ]])
			child.lua(string.format( [[ M.setup(%s) ]], vim.inspect(whaler_opts)))
            child.lua(string.format([[ vim.api.nvim_set_current_dir("%s") ]], tmp_path))
			child.lua([[ local augroup = vim.api.nvim_create_augroup('__whaler_testing', {clear = true}) ]] )

			eq(child.lua([[ return vim.loop.cwd() ]]), tmp_path)
        end,

        post_once = function() 
			helpers.remove_directory_hierarchy(child, tmp_path, helpers.directory_hierarchy)
			child.stop()
		end
    },

})


--- Generates the lua string code to create a new
--- Whaler autocommand
--- It sets two global variables: 
--- `vim.g._has_fired` on callback its set to true
--- `vim.g._whaler_data` on callback its set to the event data
--- @param userevent string User event to be put as the autocommand pattern. 
--- @return luacstr string LuaCode for generating Whaler Autocommand.
local generate_luac_aucmd = function(userevent)
	return string.format([[ 
			vim.g._has_fired = false
			vim.g._whaler_data = {}
			vim.api.nvim_create_autocmd('User', {
			  pattern = '%s',
			  callback = function(ev)
				  vim.g._has_fired = true
				  vim.g._whaler_data = ev.data
			  end
			}) ]], userevent)
end

T['all_directories'] = new_set({
	parametrize =  {
		{"personal"},
		{"work"},
		{"personal/dotfiles"},
		{"data"},
		{"data/config"},
	}
})

T['all_directories']['WhalerPreSwitch'] = function(dir)

	local create_aucmd_str = generate_luac_aucmd("WhalerPreSwitch")

	child.lua(create_aucmd_str)
	dir = string.format("%s/%s", tmp_path, dir)
	local select_any_dir = string.format([[ M.switch("%s", nil) ]], dir)
	child.lua(select_any_dir)

	--- It changes paths
	eq(child.lua([[ return vim.loop.cwd() ]]), dir)

	--- Fires correctly
	eq(child.lua([[ return vim.g._has_fired ]]), true)

	--- 
	local ev_data_str = child.lua([[ return vim.inspect(vim.g._whaler_data) ]])
	local ev_data = load("return "..ev_data_str)()
	neq(ev_data, nil)
	neq(ev_data.from, nil)
	neq(ev_data.to, nil)
	neq(ev_data.to.path, nil)
	eq(ev_data.to.path, dir)
end

T['all_directories']['WhalerPostSwitch'] = function(dir)

	local create_aucmd_str = generate_luac_aucmd("WhalerPostSwitch")

	child.lua(create_aucmd_str)
	local dir = string.format("%s/%s", tmp_path, dir)
	local select_any_dir = string.format([[ M.switch("%s", nil) ]], dir)
	child.lua(select_any_dir)

	--- It changes paths
	eq(child.lua([[ return vim.loop.cwd() ]]), dir)

	--- Fires correctly
	eq(child.lua([[ return vim.g._has_fired ]]), true)

	--- Check the UserEvent returned the correct data 
	local ev_data_str = child.lua([[ return vim.inspect(vim.g._whaler_data) ]])
	local ev_data = load("return "..ev_data_str)()
	neq(ev_data, nil)
	neq(ev_data.path, nil)
	eq(ev_data.path, dir)
end

T['WhalerPre'] = function()

	local create_aucmd_str = generate_luac_aucmd("WhalerPre")

	child.lua(create_aucmd_str)
	local dir = "personal/dotfiles/alacritty"
	dir = string.format("%s/%s", tmp_path, dir)

	local select_any_dir = [[ M.whaler() ]]
	child.lua_notify(select_any_dir)

	child.type_keys(2,"alacritty")
	child.type_keys("<C-i>")

	--- Fires correctly
	eq(child.g._has_fired, true)

	--- Check the UserEvent returned the correct data 
	local ev_data_str = child.lua_get([[ vim.inspect(vim.g._whaler_data) ]])
	local ev_data = load("return "..ev_data_str)()
	neq(ev_data, nil)
	neq(ev_data.projects, nil)
	local paths_list = vim.tbl_map(function(value)
		return value.path
	end, ev_data.projects)

	eq(vim.list_contains(paths_list, dir), true)

end

T['WhalerPost'] = function()

	local create_aucmd_str = generate_luac_aucmd("WhalerPost")

	child.lua(create_aucmd_str)
	local dir = "personal/dotfiles/alacritty"
	dir = string.format("%s/%s", tmp_path, dir)

	local select_any_dir = [[ M.whaler() ]]
	child.lua_notify(select_any_dir)

	child.type_keys(5,"alacritty")
	child.type_keys(5, "<C-i><C-i>")
	child.api.nvim_input("<CR>")

	--- Fires correctly
	eq(child.g._has_fired, true)

	--- Check the UserEvent returned the correct data 
	local ev_data_str = child.lua_get([[ vim.inspect(vim.g._whaler_data) ]])
	local ev_data = load("return "..ev_data_str)()
	neq(ev_data, nil)
	neq(ev_data.path, nil)
	eq(ev_data.path, dir)

end

return T

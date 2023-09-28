-- Telescope modules
local _pickers = require("telescope.pickers")
local _finders = require("telescope.finders")
local _actions = require("telescope.actions")
local _action_state = require("telescope.actions.state")
local _conf = require("telescope.config").values

-- Vim modules
local _fn = vim.fn

-- Whaler
local M = {}

-- Whaler variables (on setup)
local dirs

-- Whaler functions 

M.get_subdir = function(dir)
    local homedir = vim.loop.os_homedir() .. "/"
    dir = homedir .. dir

    if dir == nil then
        print('Directory is nil')
        return
    end

    if _fn.isdirectory(dir) == 0 then
        print('Directory '.. dir.. ' is not a real directory')
        return
    end

    local tbl_dir = {}
    local idx = 1

    for k,v in ipairs(_fn.readdir(dir)) do
        local entry = dir .. "/" .. v
        if _fn.isdirectory(entry) == 1 then
            tbl_dir[idx] = entry
            idx = idx + 1
        end
    end

    return tbl_dir
end

M.get_entries = function(tbl_dir)
    tbl_dir = tbl_dir or {}
    if tbl_dir == nil then
        print("Table must contain valid directories")
        return
    end

    local tbl_entries = {}
    local idx = 1 -- Tables start at 1
    for _,v1 in ipairs(tbl_dir) do
        local subdir = M.get_subdir(v1)
        for _,v2 in ipairs(subdir) do
            tbl_entries[idx] = v2
            idx = idx + 1
        end
    end

    return tbl_entries
end

M.dirs = function(dirs)
    local dirs = dirs or { ".config", "work", "personal"}
    local subdirs = M.get_entries(dirs) or {}
    return subdirs 
end

M.whaler = function(opts)
    opts = opts or {}
    local dirs = M.dirs(dirs) or {}
    _pickers.new(opts, {
        prompt_title = "Fuzzy Find directories",
        finder = _finders.new_table{
            results = dirs
        },
        sorter = _conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            _actions.select_default:replace(function()
                _actions.close(prompt_bufnr)
                local selection = _action_state.get_selected_entry()
                -- Change current directory
                vim.api.nvim_set_current_dir(selection[1])
                -- Command to open netrw
                local cmd = vim.api.nvim_parse_cmd("Explore" .. selection[1],{})
                -- Execute command
                vim.api.nvim_cmd(cmd, {})
            end)
            return true
        end
    }):find()
end

M.setup = function(setup_config)
    M.dirs = setup_config.dirs or { "work", "personal", ".config" }
end

return M

-- Telescope modules
local _pickers = require("telescope.pickers")
local _finders = require("telescope.finders")
local _actions = require("telescope.actions")
local _themes = require("telescope.themes")
local _action_state = require("telescope.actions.state")
local _conf = require("telescope.config").values

-- Logging
local log = require("plenary.log")

-- Vim modules
local _fn = vim.fn

-- Whaler modules
local _utils = require("telescope._extensions.whaler.utils")

-- Whaler
local M = {}

-- Whaler variables (on setup)
local directories -- Absolute directories where the path is absolute

-- Telescope variables
local theme_opts  = {} -- Theme Options table

-- Whaler Main functions ---

M.get_subdir = function(dir)
    -- Get all subdirectories from a directory
    dir = dir or {}

    if _fn.isdirectory(dir) == 0 then
        log.warn("Directory "..dir.. " is not a valid directory")
        return {} 
    end

    local tbl_dir = {}

    for _,v in pairs(_fn.readdir(dir)) do
        local entry = dir .. "/" .. v
        if _fn.isdirectory(entry) == 1 then
            local parsed_dir = _utils.parse_directory(entry)
            tbl_dir[parsed_dir] = parsed_dir
        end
    end

    return tbl_dir
end

M.get_entries = function(tbl_dir)

    -- Get all subdirectories from a table of valid directories
    tbl_dir = tbl_dir or {}
    if tbl_dir == nil then
        log.error("Table must contain valid directories")
        return
    end

    local tbl_entries = {}
    for _,v1 in ipairs(tbl_dir) do
        local subdirs = M.get_subdir(v1)
        for k,v in pairs(subdirs) do
            tbl_entries[k] = v
        end
    end

    return tbl_entries
end

M.dirs = function()

    local hd = directories or {}

    local shd = M.get_entries(hd) or {}

    local subdirs = shd --_utils.merge_tables_by_key(shd,ahd) or {}

    return subdirs
end

M.whaler = function(opts)
    opts = vim.tbl_deep_extend("force", theme_opts, opts or {})

    local dirs = M.dirs() or {root = "/"}
    if next(dirs) ~= nil then
        dirs = _fn.values(dirs)
    end

    local dd = "/Users/hector-nuwe"
    _pickers.new(opts, {
        prompt_title = "Whaler",
        finder = _finders.new_table{
            results = dirs
        },
        sorter = _conf.generic_sorter(opts),
        previewer = _conf.file_previewer(opts),
        attach_mappings = function(prompt_bufnr, map)
            _actions.select_default:replace(function()
                _actions.close(prompt_bufnr)
                local selection = _action_state.get_selected_entry()
                if selection then
                    -- Change current directory
                    vim.api.nvim_set_current_dir(selection[1])
                    -- Command to open netrw
                    local cmd = vim.api.nvim_parse_cmd("Explore" .. selection[1],{})
                    -- Execute command
                    vim.api.nvim_cmd(cmd, {})
                end
            end)
            return true
        end
    }):find()
end

M.setup = function(setup_config)

    if setup_config.theme and setup_config.theme ~= "" then
        theme_opts = _themes["get_" .. setup_config.theme]()
    end

    directories = setup_config.directories or {}
end


return M

--[
-- Current entries interface
-- ["/Users/hector-nuwe/personal/whaler"] 
-- { "/Users/hector-nuwe/personal/whaler"}
--]

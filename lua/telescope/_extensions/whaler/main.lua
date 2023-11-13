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
local _filex = require("telescope._extensions.whaler.file_explorer") 

-- Whaler
local M = {}

-- Whaler variables (on setup)
local directories -- Absolute path directories to search in (default {}) (map)
local oneoff_directories -- Absolute path to oneoff directories
local auto_file_explorer -- Whether to automatically open file explorer  (default true) (boolean)
local auto_cwd -- Whether to automatically change working directory (default true) (boolean)
local file_explorer -- Which file explorer to open (netrw, nvim-tree, neo-tree)
local file_explorer_config -- Map to configure the map explorer Keys: { plugin-name, command_to_toggle }  -- Does NOT accept netrw

-- Telescope variables
local theme_opts  = { -- Theme Options table
    results_title = false,
    layout_strategy = "center",
    previewer = false,
    layout_config = {
        --preview_cutoff = 1000,
        height =  0.3,
        width = 0.4
    },
    sorting_strategy = "ascending",
    border = true,
}


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
            tbl_dir[#tbl_dir + 1] = parsed_dir
        end
    end

    return tbl_dir
end

M.get_entries = function(tbl_dir, find_subdirectories)

    local subdirs
    -- Get all subdirectories from a table of valid directories
    tbl_dir = tbl_dir or {}
    if tbl_dir == nil then
        log.error("Table must contain valid directories")
        return {}
    end

    local tbl_entries = {}
    for _,dir in ipairs(tbl_dir) do
        local dir_tbl
        -- If we passed a string we assume there is no alias and turn it into a
        -- directory specification to make the code more uniform
        if type(dir) == "string" then
            dir_tbl = {path=dir, alias=nil}
        else
            dir_tbl = dir
        end

        if find_subdirectories then
            subdirs = M.get_subdir(dir_tbl.path)
        else
            subdirs = {dir_tbl.path}
        end

        for _,v in ipairs(subdirs) do
            tbl_entries[#tbl_entries + 1] = {path=v, alias=dir_tbl.alias}
        end
    end

    return tbl_entries
end

M.dirs = function()
    local hd = directories or {}
    local oneoff_hd = oneoff_directories or {}

    local subdirs = M.get_entries(hd, true) or {}
    local oneoff_dirs = M.get_entries(oneoff_hd, false) or {}

    -- merge oneoff into subdirs
    for _, oneoff in ipairs(oneoff_dirs) do
        subdirs[#subdirs+1] = oneoff
    end

    return subdirs
end

M.whaler = function(opts)
    opts = vim.tbl_deep_extend("force", theme_opts, opts or {})

    local dirs = M.dirs() or {}

    local format_entry = function(entry)
        if entry.alias then
            return ("[".. entry.alias.."] " .. _fn.fnamemodify(entry.path, ':t'))
        else
            return entry.path
        end
    end

    _pickers.new(opts, {
        prompt_title = "Whaler",
        finder = _finders.new_table{
            results = dirs,
            entry_maker = function(entry)
                return {
                    path = entry.path,
                    alias=entry.alias,
                    ordinal = format_entry(entry),
                    display = format_entry(entry),
                }
            end,
        },
        sorter = _conf.generic_sorter(opts),
        previewer = _conf.file_previewer(opts),
        attach_mappings = function(prompt_bufnr, map)
            _actions.select_default:replace(function()
                _actions.close(prompt_bufnr)
                local selection = _action_state.get_selected_entry()
                if selection then
                    -- Change current directory
                    if auto_cwd then
                        vim.api.nvim_set_current_dir(selection.path)
                    end

                    if auto_file_explorer then
                        -- Command to open netrw
                        local cmd = vim.api.nvim_parse_cmd(file_explorer_config["command"] .. file_explorer_config["prefix_dir"].. selection.path,{})
                        -- Execute command
                        vim.api.nvim_cmd(cmd, {})
                    end
                end
            end)
            return true
        end
    }):find()
end

M.setup = function(setup_config)

    if setup_config.theme and setup_config.theme ~= "" then
        -- theme_opts = _themes["get_" .. setup_config.theme]()
        theme_opts = vim.tbl_deep_extend("force", theme_opts, setup_config.theme or {})
    end

    directories = setup_config.directories or {} -- No directories by default
    oneoff_directories = setup_config.oneoff_directories or {} -- No directories by default

    -- Open file explorer is true by default
    if setup_config.auto_file_explorer == nil then
        auto_file_explorer = true
    else
        auto_file_explorer = setup_config.auto_file_explorer
    end

    -- Change directory is true by default
    if setup_config.auto_cwd == nil then
        auto_cwd = true
    else
        auto_cwd = setup_config.auto_cwd
    end

    file_explorer = setup_config.file_explorer or "netrw" -- netrw by default
    file_explorer_config = setup_config.file_explorer_config or _filex.create_config(file_explorer)

    -- If file_explorer_config is not valid use netrw as fallback
    if not _filex.check_config(file_explorer_config) then
        file_explorer_config = _filex.create_config("netrw")
    end

end


return M


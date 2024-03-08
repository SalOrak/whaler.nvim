-- Telescope modules
local _pickers = require "telescope.pickers"
local _finders = require "telescope.finders"
local _actions = require "telescope.actions"
local _themes = require "telescope.themes"
local _action_state = require "telescope.actions.state"
local _conf = require("telescope.config").values

-- Plenary helpers
local _path = require "plenary.path"
-- local _scan = require "plenary.scandir" -- Whilst in PR
local _scan = require "telescope._extensions.whaler.scandir"

-- Logging
local log = require "plenary.log"

-- Vim modules
local _fn = vim.fn

-- Whaler modules
local _utils = require "telescope._extensions.whaler.utils"
local _filex = require "telescope._extensions.whaler.file_explorer"

-- Whaler
local M = {}

-- Whaler variables (on setup)
local config = {
    directories = {}, -- Absolute path directories to search in (default {}) (map)
    oneoff_directories = {}, -- Absolute path to oneoff directories
    auto_file_explorer = true, -- Whether to automatically open file explorer  (default true) (boolean)
    auto_cwd = true, -- Whether to automatically change working directory (default true) (boolean)
    file_explorer = "netrw", -- Which file explorer to open (netrw, nvim-tree, neo-tree)
    file_explorer_config = {}, -- Map to configure the map explorer Keys: { plugin-name, command_to_toggle } , -- Does NOT accept netrw
    hidden = false, -- Append hidden directories or not. (default false)
    links = false, -- Append linked directories or not. (default false)

    -- Telescope variables
    -- Theme Options table
    theme = {
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
}



-- Whaler Main functions ---
M.get_subdir = function(dir)
    dir = _utils.parse_directory(dir)
    local d = _path.new(_path.expand(_path.new(dir)))

    if not _path.exists(d) then
        log.warn("Directory " .. dir .. " is not a valid directory")
        return {}
    end

    local tbl_sub = _scan.scan_dir(_path.expand(d), {
        hidden = config.hidden,
        depth = 1,
        only_dirs = true,
	links = config.links
    })

    local tbl_dir = {}
    for _,v in pairs(tbl_sub) do
        tbl_dir[#tbl_dir + 1] = v
    end

    return  tbl_dir
end

M.get_entries = function(tbl_dir, find_subdirectories)
    local subdirs
    -- Get all subdirectories from a table of valid directories
    tbl_dir = tbl_dir or {}
    if tbl_dir == nil then
        log.error "Table must contain valid directories"
        return {}
    end

    local tbl_entries = {}
    for _, dir in ipairs(tbl_dir) do
        local dir_tbl
        -- If we passed a string we assume there is no alias and turn it into a
        -- directory specification to make the code more uniform
        if type(dir) == "string" then
            dir_tbl = { path = dir, alias = nil }
        else
            dir_tbl = dir
        end

        if find_subdirectories then
            subdirs = M.get_subdir(dir_tbl.path)
        else
            subdirs = { dir_tbl.path }
        end

        for _, v in ipairs(subdirs) do
            tbl_entries[#tbl_entries + 1] = { path = v, alias = dir_tbl.alias }
        end
    end

    return tbl_entries
end

M.dirs = function(directories, oneoff_directories)
    local hd = directories or {}
    local oneoff_hd = oneoff_directories or {}

    local subdirs = M.get_entries(hd, true) or {}
    local oneoff_dirs = M.get_entries(oneoff_hd, false) or {}

    -- merge oneoff into subdirs
    for _, oneoff in ipairs(oneoff_dirs) do
        local parsed_oneoff = _utils.parse_directory(oneoff.path) -- Remove any / at the end.
        oneoff.path = parsed_oneoff
        subdirs[#subdirs + 1] = oneoff
    end

    return subdirs
end

M.whaler = function(conf)
    local run_config = vim.tbl_deep_extend("force", config, conf or {})
    local opts = run_config.theme or {}

    local dirs = M.dirs(run_config.directories, run_config.oneoff_directories) or {}

    local format_entry = function(entry)
        if entry.alias then
            return (
                "["
                .. entry.alias
                .. "] "
                .. _fn.fnamemodify(entry.path, ":t")
            )
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
                    path  = entry.path,
                    alias = entry.alias,
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
                    if run_config.auto_cwd then
                        vim.api.nvim_set_current_dir(selection.path)
                    end

                    if run_config.auto_file_explorer then
                        -- Command to open netrw
                        local cmd = vim.api.nvim_parse_cmd(
                                        run_config.file_explorer_config["command"]
                                        .. run_config.file_explorer_config["prefix_dir"]
                                        .. selection.path,{}
                                        )
                        -- Execute command
                        vim.api.nvim_cmd(cmd, {})
                    end
                end
            end)
            return true
            end,
        })
        :find()
end

M.setup = function(setup_config)
    if setup_config and setup_config ~= "" then
        config = vim.tbl_deep_extend("force", config, setup_config or {})
    end

    config.directories = setup_config.directories or {} -- No directories by default
    config.oneoff_directories = setup_config.oneoff_directories or {} -- No directories by default

    -- Open file explorer is true by default
    if setup_config.auto_file_explorer ~= nil then
        config.auto_file_explorer = setup_config.auto_file_explorer
    end

    -- Change directory is true by default
    if setup_config.auto_cwd ~= nil then
        config.auto_cwd = setup_config.auto_cwd
    end

    config.file_explorer = setup_config.file_explorer or "netrw" -- netrw by default
    config.file_explorer_config = setup_config.file_explorer_config or _filex.create_config(config.file_explorer)

    -- If file_explorer_config is not valid use netrw as fallback
    if not _filex.check_config(config.file_explorer_config) then
        config.file_explorer_config = _filex.create_config("netrw")
    end
end

return M

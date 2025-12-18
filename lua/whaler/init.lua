-- Telescope modules

-- Plenary helpers
local _path = require "plenary.path"
local _scan = require "plenary.scandir"

-- Logging
local log = require "plenary.log"

-- Whaler modules
local Utils = require "whaler.utils"
local Filex = require "whaler.file_explorer"
local Pickers = require "whaler.picker"
local State = require'whaler.state'

-- Whaler

---@field state table Represents the current state of Whaler. 
--- Use `M.switch()` function to change it. Don't change it manually. 
local M = {
    ---@field path string? Path representing the CWD and Whaler project.
    ---@field display string? Display string shown instead of path
    state = {
        path = "",
        display = "",
    }
}

-- Whaler variables (on setup)
local config = {
    directories = {}, -- Absolute path directories to search in (default {}) (map)
    oneoff_directories = {}, -- Absolute path to oneoff directories
    auto_file_explorer = true, -- Whether to automatically open file explorer  (default true) (boolean)
    auto_cwd = true, -- Whether to automatically change working directory (default true) (boolean)
    file_explorer = "netrw", -- Which file explorer to open (netrw, nvim-tree, neo-tree)
    file_explorer_config = {}, -- Map to configure the map explorer Keys: { plugin-name, command_to_toggle } , -- Does NOT accept netrw
    hidden = false, -- Append hidden directories or not. (default false)

    picker = "telescope", -- Which picker to use. One of 'telescope', 'fzf_lua' or 'vanilla'. Default to 'telescope'

    -- Telescope variables
    -- Theme Options table
    theme = {
        results_title = false,
        layout_strategy = "center",
        previewer = false,
        layout_config = {
            --preview_cutoff = 1000,
            height = 0.3,
            width = 0.4,
        },
        sorting_strategy = "ascending",
        border = true,
    },
}

-- Whaler Main functions ---
M.get_subdir = function(dir)
    dir = Utils.parse_directory(dir)
    local d = _path.new(_path.expand(_path.new(dir)))

    if not _path.exists(d) then
        log.warn("Directory " .. dir .. " is not a valid directory")
        return {}
    end

    local tbl_sub = _scan.scan_dir(_path.expand(d), {
        hidden = config.hidden,
        depth = 1,
        only_dirs = true,
    })

    local tbl_dir = {}
    for _, v in pairs(tbl_sub) do
        tbl_dir[#tbl_dir + 1] = v
    end

    return tbl_dir
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
        local parsed_oneoff = Utils.parse_directory(oneoff.path) -- Remove any / at the end.
        oneoff.path = parsed_oneoff
        subdirs[#subdirs + 1] = oneoff
    end

    return subdirs
end

--- Switches to another path, changing the current whaler state
--- It fires user events.
--- First event just before changing to the new path it fires the `WhalerPreSwitch` 
--- event whose data include the current state and the new one.
--- After changing to the new path it fires `WhalerPostSwitch` event.
---@param path string? String path representing the new path to switch to
---@param display string? Display string to show instead of the path. If nil it
---generates it from the `path`
M.switch = function(path, display) 
    vim.api.nvim_exec_autocmds('User', {
        pattern = 'WhalerPreSwitch',
        data = {
            from = M.state,
            to = {
                path = path,
                display = display,
            }
        }
    })

    -- TODO: Manage errors in case path does not exist.
    vim.api.nvim_set_current_dir(path)

    M.state.path = path
    -- TODO: Create a display based on the path in case it is nil. Maybe accept
    -- a user input function to create the display based on the path.
    M.state.display = display

    vim.api.nvim_exec_autocmds("User", {
        pattern = "WhalerPostSwitch",
        data = {
            path = path,
            display = display,
        }
    })

end

--- Returns the current state values of Whaler. That is, the 
--- path selected as well as the display name. It may be nil
---@return {path: string?, display:string?} table Current state
M.current = function()
    return M.state
end


--- Core functionality used after selecting a project.
--- Common to all pickers. It fires `WhalerPost` user event.
---@param path string Path to change to.
---@param display string? Display name of the path.
M.select = function(path, display)

    local opts = State:get().run_opts or {}

    if opts.auto_cwd then
        M.switch(path, display)
    end

    -- File explorer / Command to be executed
    local cmd = vim.api.nvim_parse_cmd(
        opts.file_explorer_config["command"]
        .. opts.file_explorer_config["prefix_dir"]
        .. path,
        {}
    )

    if opts.auto_file_explorer then
        -- Execute command
        vim.api.nvim_cmd(cmd, {})
    end

    vim.api.nvim_exec_autocmds("User", {
        pattern = "WhalerPost",
        data = {
            cmd = cmd,
            path = path,
            display = display,
        }
    })
end

--- Main function. Generates the directories and subdirectories comprising the
--- projects and executes a command on it. By default the command is a file
--- explorer but it can be changed to any command.
--- It fires the `WhalerPre` event just after generating the directories
--- containing the table of projects.
--- After selecting a project, it fires the `WhalerPost` event which contains
--- the command executed after selecting the entry as well as the entry path and
--- entry display name
M.whaler = function(run_opts)
    local run_opts = vim.tbl_deep_extend("force", config, run_opts or {})

    local dirs = M.dirs(run_opts.directories, run_opts.oneoff_directories)
    or {}

    vim.api.nvim_exec_autocmds("User", {
        pattern = "WhalerPre",
        data = {
            projects = dirs
        }
    })

    local picker = Pickers.get_picker(run_opts.picker)

    if picker == nil then
        --- TODO: Notify an error to the user
        return
    end

    picker.picker(dirs, run_opts)

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
    config.file_explorer_config = setup_config.file_explorer_config
    or Filex.create_config(config.file_explorer)

    -- If file_explorer_config is not valid use netrw as fallback
    if not Filex.check_config(config.file_explorer_config) then
        config.file_explorer_config = Filex.create_config "netrw"
    end
end

return {
    setup = M.setup,
    whaler = M.whaler,
    current = M.current,
    switch = M.switch,
    select = M.select
}

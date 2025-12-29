-- Path
local Path = require "whaler.path"

-- Logging
local Logger = require "whaler.logger"

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
    verbosity = vim.log.levels.WARN, --- Minimum level of verbosity. See `vim.log.levels`. Default to WARN.

    --- Whether to follow symlinks when scanning for subdirectories.
    follow = true,

    --- Function to filter projects based on their name when scanning.
    filter_project = function(path_name) return true end,

    picker = "telescope", -- Which picker to use. One of 'telescope', 'fzf_lua' or 'vanilla'. Default to 'telescope'

    -- Picker optiosn
    -- Options to pass to Telescope.
    telescope_opts = { },

    -- For compatiblity you can use `theme` directly
    -- to modify Telescope theme options. 
    theme = { },

    -- Options to pass to FzfLua directly. See
    -- https://github.com/ibhagwan/fzf-lua?tab=readme-ov-file#customization for
    -- options
    fzflua_opts= {},
}

-- Whaler Main functions ---

--- Ensambles all the projects directory into a table containing the path and
--- alias.
--- @param tbl_dir table|string[] Contains the directories to search in or to
--- convert into a table of path and its alias (display name).
--- @param opts { is_oneoff: boolean?, hidden: boolean?, follow: boolean?, project_filter: function }
--- @return projects {{path: string, alias: string?}}
M.get_entries = function(tbl_dir, opts)
    local subdirs
    -- Get all subdirectories from a table of valid directories
    tbl_dir = tbl_dir or {}
    if tbl_dir == nil then
        Logger:err("Table must contain valid directories")
        return {}
    end

    local tbl_entries = {}
    for _, dir in ipairs(tbl_dir) do
        local dir_tbl = dir

        -- If we passed a string we assume there is no alias and turn it into a
        -- directory specification to make the code more uniform
        if type(dir) == "string" then
            dir_tbl = { path = dir, alias = nil }
        end

        local path = Path:new(dir_tbl.path)

        if not path then
            local path_type = (opts.is_oneoff and "Oneoff") or "Parent"
            local msg = string.format("%s directory %s is not a valid path.", path_type, dir_tbl.path)
            Logger:warn(msg)
        else 
            if opts.is_oneoff then
                --- oneoff means the directory itself is the project.
                subdirs = { dir_tbl.path }
            else
                --- else we generate the directory list
                subdirs = path:scan(opts.hidden, opts.follow, opts.filter_project) 
            end

            for _, v in ipairs(subdirs) do
                tbl_entries[#tbl_entries + 1] = { path = v, alias = dir_tbl.alias }
            end
        end

    end

    return tbl_entries
end

--- Calls the generation of project directory list and merges
--- the returning result.
--- @param run_opts table Runtime options. Same as config options.
--- @return project_dirs table Table containing all the projects directories and
--- its alias names.
M.gen_projects = function(run_opts)
    local parent_dirs = run_opts.directories or {}
    local oneoff_projects = run_opts.oneoff_directories or {}

    local opts = {
        is_oneoff = false,
        hidden = run_opts.hidden,
        follow = run_opts.follow,
        filter_project = run_opts.filter_project
    }

    local projects_dirs = M.get_entries(parent_dirs, opts) or {}

    opts.is_oneoff = true
    local oneoff_dirs = M.get_entries(oneoff_projects, opts) or {}

    -- merge oneoff into subdirs
    for _, oneoff in ipairs(oneoff_dirs) do
        local parsed_oneoff = Utils.parse_directory(oneoff.path) -- Remove any / at the end.
        oneoff.path = parsed_oneoff
        projects_dirs[#projects_dirs + 1] = oneoff
    end

    return projects_dirs
end

--- Switches to another path, changing the current whaler state
--- It fires user events.
--- First event just before changing to the new path it fires the `WhalerPreSwitch` 
--- event whose data include the current state and the new one.
--- After changing to the new path it fires `WhalerPostSwitch` event.
---@param str_path string? String path representing the new path to switch to
---@param display string? Display string to show instead of the path. If nil it
---generates it from the `path`
M.switch = function(str_path, display) 
    vim.api.nvim_exec_autocmds('User', {
        pattern = 'WhalerPreSwitch',
        data = {
            from = M.state,
            to = {
                path = str_path,
                display = display,
            }
        }
    })

    local ok = Path:new(str_path)
    if not ok then
        Logger:error(string.format("Can't switch to path %s because it is not a valid path.", str_path))
        return nil
    end

    vim.api.nvim_set_current_dir(str_path)

    M.state.path = str_path
    -- TODO: Create a display based on the path in case it is nil. Maybe accept
    -- a user input function to create the display based on the path.
    M.state.display = display

    vim.api.nvim_exec_autocmds("User", {
        pattern = "WhalerPostSwitch",
        data = {
            path = str_path,
            display = display,
        }
    })

    return true

end

--- Returns the current state values of Whaler. That is, the 
--- path selected as well as the display name. It may be nil
---@return {path: string?, display:string?} table Current state
M.current = function()
    return M.state
end


--- Core functionality used after choosing a project from a picker.
--- Common to all pickers. It fires `WhalerPost` user event.
---@param path string Path to change to.
---@param display string? Display name of the path.
M.select = function(path, display)

    local opts = State:get().run_opts or {}

    if opts.auto_cwd then
        if not M.switch(path, display) then
            return
        end
    end

    local cmd = nil

    if opts.auto_file_explorer then
        -- File explorer / Command to be executed
        cmd = vim.api.nvim_parse_cmd(
            opts.file_explorer_config["command"]
            .. opts.file_explorer_config["prefix_dir"]
            .. path,
            {}
        )
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
    run_opts = vim.tbl_deep_extend("keep", run_opts, State:get().run_opts or {})

    local dirs = M.gen_projects(run_opts) or {}

    vim.api.nvim_exec_autocmds("User", {
        pattern = "WhalerPre",
        data = {
            projects = dirs
        }
    })

    local picker = Pickers.get_picker(run_opts.picker)

    if picker == nil then
        --- TODO: Notify an error to the user
        picker = Pickers.get_picker("vanilla") -- Fallback picker
    end

    picker.picker(dirs, run_opts)

end

M.setup = function(setup_config)
    if setup_config and setup_config ~= "" then
        config = vim.tbl_deep_extend("force", config, setup_config or {})
    end


    --- Log level by default is WARN.
    config.verbosity = setup_config.verbosity or vim.log.levels.WARN
    Logger:set_verbosity(config.verbosity)


    --- Filter project. Accept everything by default
    config.filter_project = setup_config.filter_project or function(path_name) return true end

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

    --- Set the config value as 'run_opts'
    State:set({run_opts = config})
end

return {
    setup = M.setup,
    whaler = M.whaler,
    current = M.current,
    switch = M.switch,
    select = M.select
}

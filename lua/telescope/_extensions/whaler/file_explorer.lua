-- Vim API
local _api = vim.api

-- Logging
local log = require("plenary.log")

-- Whaler File explorer module
local M = {}

-- Accepted current configurations
local FILEX_ENUM = {
    netrw = {
        plugin_name = "netrw",
        command = "Explore",
    },
    --[[ TODO: Does not work very well as it gets out of nvim?? 
    nnn = {
        plugin_name = "nnn",
        command = "NnnPicker",
    },
    --]]
    nvimtree = {
        -- RECOMMENDATION sync_root_with_cwd = true for Whaler to work properly
        plugin_name = "nvim-tree",
        command = "NvimTreeOpen",
    },
    neotree= {
        -- Works out of the box.
        plugin_name = "neo-tree",
        command = "Neotree",
    },
}

M.check_config = function(config)
    config = config or {}

    -- Check if keys exist [ plugin_name, command ]
    if config["plugin_name"] == nil then
        log.warn("Plugin name is not present in file_explorer_config")
        return false
    end

    if config["plugin_name"] ~= "netrw" then
        local has_plug,_ = pcall(require, config["plugin_name"])
        if not has_plug then
            log.warn(config["plugin_name"].." is not installed. Please install it before using it.")
            return false
        end
    end

    if config["command"] == nil then
        log.warn("Command is not present in file_explorer_config. It is used to toggle or activate the file explorer")
        return false
    end
    -- TODO: Check why Explore is not by default in the nvim_get_commands() function. Is it because of Lazy?
    local nvim_cmds = _api.nvim_get_commands({})
    if nvim_cmds[config["command"]] == nil  and false then
        log.warn("Command ".. config["command"] .. " is not a valid nvim command")
        return true
    end

    return true
end

M.create_config = function(file_explorer)
    
    if FILEX_ENUM[file_explorer] == nil then
        log.error("Option " .. file_explorer .. " not valid. Choose one 'netrw' | 'nvimtree' | 'neotree'\n")
        return {}
    end

    return FILEX_ENUM[file_explorer]
end

return M

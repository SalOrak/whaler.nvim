---@class Logger
local Logger = {}
Logger.__index = Logger

Logger.verbosity = vim.log.levels.WARN


--- Singleton instance of Logger class
local logger = {}

--- Creates / gets a the logger instance. Singleton.
--- @param verbosity vim.log.levels Minimum verbosity
function Logger:_get_instance(verbosity)
    if getmetatable(logger) == nil then
        logger = setmetatable({
            verbosity = verbosity
        }, self)
    end
    return logger
end

--- Logging using `vim.notify` and `vim.log.levels` but all logs
--- are tied to the Whaler instance. 
--- It only executes when the level param is higher or equal than
--- then verbosity set to the logger.
--- @param msg string? The message to display
--- @param level vim.log.levels The level of the message. 
--- See `vim.log.levels`.
function Logger:log(msg, level)
    --- Don't execute if level is below expected
    if self.verbosity > level then
        return
    end

    local prefix = "[Whaler]: "
    local message = string.format("%s%s", prefix, msg)

    --- TODO: Should it be `vim.notify_once` instead?
    vim.notify(message, level)
end


--- Execute log() with level set to TRACE
--- @param msg string? The message to display
function Logger:trace(msg)
    self:log(msg, vim.log.levels.TRACE)
end

--- Execute log() with level set to DEBUG
--- @param msg string? The message to display
function Logger:debug(msg)
    self:log(msg, vim.log.levels.DEBUG)
end

--- Execute log() with level set to INFO
--- @param msg string? The message to display
function Logger:info(msg)
    self:log(msg, vim.log.levels.INFO)
end

--- Execute log() with level set to WARN
--- @param msg string? The message to display
function Logger:warn(msg)
    self:log(msg, vim.log.levels.WARN)
end

--- Execute log() with level set to ERROR
--- @param msg string? The message to display
function Logger:error(msg)
    self:log(msg, vim.log.levels.ERROR)
end

--- Changes the verbosity of the logger instance. 
---@param level vim.log.levels The new verbosity level
function Logger:set_verbosity(level)
    if not vim.tbl_contains(vim.log.levels, level) then
        self:err(string.format(
            "Could not change verbosity."
            .. "Level %s is not a valid level"
            .. "See `vim.log.levels`.", level))
        return
    end

    self.verbosity = level
end

logger = Logger:_get_instance(vim.log.levels.WARN)

return logger

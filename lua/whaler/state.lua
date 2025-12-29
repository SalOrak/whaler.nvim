---@class State
local State = {}
State.__index = State
State.data = {}

local state = {}

--- Singleton class. Meant to be used internally.
--- @return state State State instance
function State:_get_instance()
    if getmetatable(state) == nil then
        self = setmetatable({ data = {
            dirs_map = {}, run_opts = {}
        }
    }, State)
    end
    return self
end

function State:get()
    return self.data
end

function State:set(new_state)
    if getmetatable(self) ~= nil then
        self.data = vim.tbl_deep_extend('force', self.data, new_state or {})
    end
end

state = State:_get_instance()

return state

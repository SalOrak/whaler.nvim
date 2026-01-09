--- Define helper aliases
local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

--- Create (but not start) child Neovim object

local child = MiniTest.new_child_neovim()


--- define main tests set of this file
local T = new_set({
    --- Register hook
    hooks = {
        -- Executed before every (even nested) case
        pre_case = function()
            child.restart({'-u', 'scripts/minimal_init.lua'})
            child.lua([[M = require('whaler.file_explorer')]])
        end,

        -- Executed one after all tests from this set are finished
        post_once = child.stop
    }
})

-- Test set fields define nested structure
T['compute()'] = new_set()

-- Define test action as callable field of test set
--- If it procudes an error the test fails

T['compute()']['works'] = function()
    eq(child.lua('return M.create_config("netrw")'), {
        plugin_name = "netrw",
        command = "Explore",
        prefix_dir = " ",
    })
end

return T



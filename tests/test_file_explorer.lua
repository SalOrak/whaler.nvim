local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality


local child = MiniTest.new_child_neovim()


local T = new_set({
    hooks = {
        --- For each case
        pre_case = function()
            child.restart({'-u', 'scripts/minimal_init.lua'})
            child.lua([[ M = require('whaler.file_explorer') ]])
        end,
        post_once = child.stop()
    }
})


--- Test all file_explorers return the expected result
T['filex_combinations'] = new_set({parametrize = {
    { "netrw", {
            plugin_name = "netrw",
            command = "Explore",
            prefix_dir = " ",
    } },
    { "nvimtree", {
        plugin_name = "nvim-tree",
        command = "NvimTreeOpen",
        prefix_dir = " ",
    } },
    { "neotree", {
        plugin_name = "neo-tree",
        command = "Neotree",
        prefix_dir = " ",
    } },
    { "oil", {
        plugin_name = "oil",
        command = "Oil",
        prefix_dir = " ",
    } },
    { "telescope_file_browser", {
        plugin_name = "telescope",
        command = "Telescope file_browser",
        prefix_dir = " path=",
    } },
    { "rnvimr", {
            plugin_name = "rnvimr",
            command = "RnvimrOpen",
            prefix_dir = " ",
    } },
    { "should fail", { } },
}})


T['filex_combinations']['check config'] = function(conf, expected)
    local str_lua = string.format([[return M.create_config(%s)]], vim.inspect(conf))
    eq(child.lua(str_lua), expected)
end

return T

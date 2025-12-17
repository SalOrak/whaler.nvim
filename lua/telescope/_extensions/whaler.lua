local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
    error "This plugin requires nvim-telescope/telescope.nvim"
end

local whaler = require'whaler'

return telescope.register_extension {
    setup = whaler.setup,
    exports = {
        whaler = whaler.whaler,
        get_state = whaler.get_state,
        switch = whaler.switch,
    },
}

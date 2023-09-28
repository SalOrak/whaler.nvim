local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
    error('This plugin requires nvim-telescope/telescope.nvim')
end

local whaler = require('telescope._extensions.whaler')

return telescope.register_extension {
    setup = whaler.setup,
    exports = { whaler = whaler.whaler }
}

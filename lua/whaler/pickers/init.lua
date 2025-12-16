local telescope = require'whaler.pickers.telescope'
local vanilla = require'whaler.pickers.vanilla'
local fzf_lua = require'whaler.pickers.fzf_lua'

local M = {}

local pickers = {
    telescope = telescope,
    vanilla = vanilla,
    fzf_lua = fzf_lua,
}


--- Returns the picker function based on a name
---@param picker string Picker function to use
---@return picker function Picker function. Signature is function(dirs,opts).
    ---@param dirs table Projects and its aliases
    ---@param opts table Configuration options
M.get_picker = function(picker)
    local p = pickers[picker]
    if p == nil then
        --- TODO: notify an error to the user
        return nil
    end

    return p
end


return M

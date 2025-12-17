local M = {}



--- Returns the picker function based on a name
---@param picker string Picker function to use
---@return picker function Picker function. Signature is function(dirs,opts).
    ---@param dirs table Projects and its aliases
    ---@param opts table Configuration options
M.get_picker = function(picker)
    local pickers = {
        telescope = require'whaler.pickers._telescope',
        vanilla = require'whaler.pickers.vanilla',
        fzf_lua = nil,
    }
    local p = pickers[picker]
    if p == nil then
        --- TODO: notify an error to the user
        return nil
    end

    return p
end


return {
    get_picker = M.get_picker
}

local M = {}

local Logger = require'whaler.logger'

--- Safe version of require. Returns nil instead of an error when module does not exist.
--- This is useful for example when telescope is not installed.
local safe_require = function(module)
    local success, mod = pcall(require, module)

    if not success then return nil end
    return mod
end

--- Returns the picker function based on a name
---@param picker string Picker function to use
---@return picker function Picker function. Signature is function(dirs,opts).
    ---@param dirs table Projects and its aliases
    ---@param opts table Configuration options
M.get_picker = function(picker)

    local pickers = {
        telescope = safe_require('whaler.pickers._telescope'),
        vanilla = safe_require('whaler.pickers.vanilla'),
        fzf_lua = safe_require('whaler.pickers._fzflua'),
        snacks = nil,
        mini = nil,
    }

    local p = pickers[picker]
    if p == nil then
        local available_pickers = vim.fn.join(vim.tbl_keys(pickers), ', ')
        Logger:warn(string.format(
            "Picker %s is not an option. Choose one from %s.", 
            picker, available_pickers ))
        return nil
    end

    return p
end


return {
    get_picker = M.get_picker
}

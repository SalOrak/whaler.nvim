local whaler = require'whaler'

local M = {
    dirs_map = {}
}

local format_entry = function(entry)
    if entry.alias then
        return (
            "["
            .. entry.alias
            .. "] "
            .. vim.fn.fnamemodify(entry.path, ":t")
        )
    else
        return entry.path
    end
end

--- Completion function used for `vim.ui.input`.
--- Fuzzy finds using vim `matchfuzzy` function to autocomplete.
M.pickerCompletion = function(arglead, cmdline, cursorpos) 
    return vim.fn.matchfuzzy(vim.tbl_keys(M.dirs_map), arglead or "")
end

--- Vanilla picker function using `vim.ui.input`
---@param dirs [{ alias: string?, path: string}] Project definition
---@param opts table Options table to be passed to the picker
local picker = function(dirs, opts)
    -- The relationship between the display and the actual path
    M.dirs_map = {} 

    for k,v in pairs(dirs) do
        local key = format_entry(v)

        -- Path should never be null
        assert(dirs[k].path ~= nil, "Directory path is never null")
        local value = dirs[k].path 
        M.dirs_map[key] = value
    end


    vim.ui.input({
        prompt = "Whaler >> ",
        completion = "customlist,v:lua.require'whaler.pickers.vanilla'.completion",
    },
    function(input)
        if input == nil or input == "" then
            print("Input is nil: ",input)
            return
        end
        if vim.tbl_contains(vim.tbl_keys(M.dirs_map), input) then
            local path = M.dirs_map[input]
            assert(path ~= nil, "Path should not be null")
            whaler.select(path, input,opts)
        end
    end
)
end

return {
    picker = picker,
    completion = M.pickerCompletion, -- Name is linked to `vim.ui.input`
    dirs_map = M.dirs_map,

}

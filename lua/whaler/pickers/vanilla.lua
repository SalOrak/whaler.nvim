local Whaler = require'whaler'
local State = require'whaler.state'

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
local pickerCompletion = function(arglead, cmdline, cursorpos) 
    local dirs_map = State:get().dirs_map
    return vim.fn.matchfuzzy(vim.tbl_keys(dirs_map), arglead or "")
end

--- Vanilla picker function using `vim.ui.input`
---@param dirs [{ alias: string?, path: string}] Project definition
---@param opts table Options table to be passed to the picker
local picker = function(dirs, opts)
    local dirs_map = {}

    for k,v in pairs(dirs) do
        local key = format_entry(v)

        -- Path should never be null
        assert(dirs[k].path ~= nil, "Directory path is never null")
        local value = dirs[k].path 
        dirs_map[key] = value
    end

    -- Update the global state
    State:set({
        dirs_map = dirs_map,
        run_opts = opts
    })


    vim.ui.input({
        prompt = "Whaler >> ",
        completion = "customlist,v:lua.require'whaler.pickers.vanilla'.completion",
    },
    function(input)
        local dirs_map = State:get().dirs_map or {}
        if input == nil or input == "" then
            print("Input is nil: ",input)
            return
        end
        if vim.tbl_contains(vim.tbl_keys(dirs_map), input) then
            local path = dirs_map[input]
            assert(path ~= nil, "Path should not be null")
            Whaler.select(path, input)
        end
    end
)
end

return {
    picker = picker,
    completion = pickerCompletion, -- For `vim.ui.input` completion
}

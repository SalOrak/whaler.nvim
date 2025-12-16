local whaler = require'whaler'


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

--- Vanilla picker function using `vim.ui.input`
---@param dirs [{ alias: string?, path: string}] Project definition
---@param opts table Options table to be passed to the picker
local picker = function(dirs, opts)
    -- The relationship between the display and the actual path
    local dirs_map = {} 

    for k,v in pairs(dirs) do
        local key = format_entry(v)

        -- Path should never be null
        assert(dirs[k].path ~= nil, "Directory path is never null")
        local value = dirs[k].path 
        dirs_map[key] = value
    end

    -- Completion function to be passed to `vim.ui.input`
    local pickerCompletion = function(arglead, cmdline, cursorpos) 
        return vim.fn.matchfuzzy(vim.tbl_keys(dirs_map), arglead or "")
    end

    vim.ui.input({
        prompt = "Whaler >> ",
        completion = "customlist,v:lua.pickerCompletion",
        function(input)
            if string.gsub(input, " ", "") == "" then
                return
            end
            if (vim.tbl_keys(dirs_map), input) then
                local path = dirs_map[input]
                assert(path ~= nil, "Path should not be null")
                whaler.select(path, input,opts)
            end
        end
    })
end

return {
    picker = picker
}

local Whaler = require'whaler'
local State = require'whaler.state'
local Fzf = require'fzf-lua'

-- TODO: Sane config defaults for fzf-lua 

local defaults = {
    prompt = "Whaler >> ",
    actions = {
        ["default"] = function(selected)
                local dirs_map = State:get().dirs_map

                local display = selected[1] 
                local path = dirs_map[selected[1]]

                Whaler.select(path, display)
            end
        
    },
    fn_format_entry = function(entry)
        if entry.alias then
            return (
                "["
                .. entry.alias
                .. "] "
                .. vim.fn.fnamemodify(entry.path, ":t")
            )
        end

        return entry.path
    end
}


local picker = function(dirs, run_opts)

    local fzf_opts = vim.tbl_deep_extend('force', defaults, run_opts.fzflua_opts or {})
    local dirs_map = {}

    for k,v in pairs(dirs) do
        local key = defaults.fn_format_entry(v)

        -- Path should never be null
        assert(dirs[k].path ~= nil, "Directory path is never null")
        local value = dirs[k].path 

        dirs_map[key] = value
    end

    --- Update the global state
    State:set({
        dirs_map = dirs_map,
        run_opts = run_opts,
    })

    Fzf.fzf_exec(vim.tbl_keys(dirs_map), fzf_opts)
end


return {
        picker = picker
    }

local _pickers = require "telescope.pickers"
local _finders = require "telescope.finders"
local _actions = require "telescope.actions"
local _themes = require "telescope.themes"
local _action_state = require "telescope.actions.state"
local _conf = require("telescope.config").values

local defaults = {
    results_title = false,
    layout_strategy = "center",
    previewer = false,
    layout_config = {
        --preview_cutoff = 1000,
        height = 0.3,
        width = 0.4,
    },
    sorting_strategy = "ascending",
    border = true,
}

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

local picker = function(dirs, opts)
    local telescope_opts = vim.tbl_deep_extend('force', defaults, opts.telescope_opts or {})

    -- For compatiblity reasons
    telescope_opts = vim.tbl_deep_extend('force', telescope_opts, opts.theme or {})

    _pickers.new(telescope_opts, {
        prompt_title = "Whaler",
        finder = _finders.new_table {
            results = dirs,
            entry_maker = function(entry)
                return {
                    path = entry.path,
                    alias = entry.alias,
                    ordinal = format_entry(entry),
                    display = format_entry(entry),
                }
            end,
        },
        sorter = _conf.generic_sorter(telescope_opts),
        previewer = _conf.file_previewer(telescope_opts),
        attach_mappings = function(prompt_bufnr, map)
            _actions.select_default:replace(function()
                _actions.close(prompt_bufnr)
                local selection = _action_state.get_selected_entry()
                if selection then

                    -- Update the state
                    State:set({
                        run_opts = opts
                    })

                    Whaler.select(selection.path, selection.display)
                end

            end)
            return true
        end,
    }):find()
end


return {
    picker = picker
}

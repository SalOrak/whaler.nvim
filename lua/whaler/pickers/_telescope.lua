local _pickers = require "telescope.pickers"
local _finders = require "telescope.finders"
local _actions = require "telescope.actions"
local _themes = require "telescope.themes"
local _action_state = require "telescope.actions.state"
local _conf = require("telescope.config").values

local ok, whaler = pcall(require, 'whaler')
if not ok then
    vim.notify("Loop? Error importing whaler")
    return {picker = nil}
end

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
    local telescope_opts = opts.theme or {}

    _pickers .new(telescope_opts, {
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
                    whaler.select(selection.path, selection.display,opts)
                end

            end)
            return true
        end,
    }):find()
end


return {
    picker = picker
}

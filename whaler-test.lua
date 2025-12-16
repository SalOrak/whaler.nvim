local data = {
    dirs = { 
        {
            alias = "Personal",
            path = "/home/hector/personal/Books"
        }, {
            alias = "Personal",
            path = "/home/hector/personal/Miau"
        }, {
            alias = "Work",
            path = "/home/hector/work/ansible-doc.nvim"
        }, {
            alias = "Personal",
            path = "/home/hector/personal/aoc"
        }, {
            alias = "Personal",
            path = "/home/hector/personal/awesome-neovim"
        }, {
            alias = "Microbit",
            path = "/home/hector/personal/microbit"
        }, {
            alias = "Personal",
            path = "/home/hector/personal/codecrafters-shell-zig"
        }, {
            alias = "Personal",
            path = "/home/hector/personal/cursed-matrix"
        }
    },
    format_entry = function(entry)
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
    end,
}

local f = {}
for k,v in pairs(data.dirs) do
    local key = data.format_entry(v)
    local value = data.dirs[k].path 
    f[key] = value
end

data.dirs = f


function genDirs(arglead, cmdline, cursorpos) 
    return vim.fn.matchfuzzy(vim.tbl_keys(data.dirs), arglead or "")
end

local w = require'telescope'.extensions.whaler

vim.ui.input({prompt = "Whaler > ", completion="customlist,v:lua.genDirs"}, function(input)
    if string.gsub(input, " ","") == "" then
        return
    end
    if vim.tbl_contains(vim.tbl_keys(data.dirs), input) then
        P(data.dirs[input])
    end
end)

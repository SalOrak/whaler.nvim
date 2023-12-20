local _fn = vim.fn

-- Whaler
local M = {}

-- Whaler utility functions

M.merge_tables_by_index = function(t1, t2)
    local out = {}
    local idx = 1
    for _, v in ipairs(t1) do
        out[idx] = v
        idx = idx + 1
    end

    for _, v in ipairs(t2) do
        out[idx] = v
        idx = idx + 1
    end
    return out
end

M.merge_tables_by_key = function(t1, t2)
    local out = {}

    for k, v in pairs(t2) do
        out[k] = v
    end

    for k, v in pairs(t1) do
        out[k] = v
    end

    return out
end

M.parse_directory = function(dir)
    dir = dir or ""
    local tmp = ""
    for i = 1, _fn.strlen(dir) do
        local c1 = dir:sub(i, i)
        local c2 = dir:sub(i + 1, i + 1)
        if not ((c1 == c2 or i == _fn.strlen(dir)) and c1 == "/") then
            tmp = tmp .. c1
        end
    end
    return tmp
end

return M


---@class Path
local Path = {}
Path.__index = Path
Path._stat = nil
Path._str = ""


--- Creates a new Path object based on a string path.
--- The path is normalized with `vim.fs.normalize`.
--- @param str_path string? String path to build the Path.
--- @return path Path? The Path pointing to a str_path or nil if it does not
--- exist.
function Path:new(str_path)
    local norm_path = vim.fs.normalize(str_path)
    local path_stat = vim.uv.fs_stat(norm_path)
    if not path_stat then
        return nil
    end

    return setmetatable({
        _str =  norm_path,
        _stat = path_stat,
    }, self)
end


---@param hidden boolean Whether to add hidden directories or not.
---@param follow boolean Whehter to follow symlinks or not.
---@param filter function(path_name) -> boolean Function to filter based on the
    --- directory name. Return true to add the directory, false otherwise
function Path:scan(hidden, follow, cb_filter)

    local iter = vim.fs.dir(self._str, {
        depth = 1,
        follow = follow
    })

    local dirs = {}
    for path,ptype in iter do
        local abs_path = string.format("%s/%s", self._str, path)
        local should_insert = false
        if ptype == "directory" then
            should_insert = true
        elseif ptype == "link" then
            local link_stat = vim.uv.fs_stat(abs_path) or { type = "none"}
            local ltype = link_stat.type

            --- Check whether the link is a directory.
            if ltype == "directory" then
                should_insert = true
            end
        end

        if should_insert and cb_filter(path) then
            table.insert(dirs, abs_path) 
        end
    end

    return dirs
end


return Path


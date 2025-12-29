local Logger = require'whaler.logger'

---@class Path
local Path = {}
Path.__index = Path
Path._stat = nil
Path._str = ""


--- Creates a new Path object based on a string path.
--- The path is normalized with `vim.fs.normalize`.
--- If the path points to a file, it uses the parent directory instead.
---
--- If the path points to a link, it uses the file/directory that points to.
--- For example, if I have dir A in /tmp/bin/A, and a symlink in /home/ada/c
--- that points to A. If I pass the path to c it will return the directories
--- inside the path of A, i.e. all directories inside /tmp/bin/A/ 
---
--- @param str_path string? String path to build the Path.
--- @return path Path? The Path pointing to a str_path or nil if it does not
--- exist.
function Path:new(str_path)

    local norm_path = vim.fs.normalize(str_path)
    local real_path = vim.uv.fs_realpath(norm_path) -- Always resolve symlinks

    --- `real_path` is nil means the path does not exist.
    if not real_path then 
        return nil 
    end

    local path_stat = vim.uv.fs_stat(real_path)

    --- Whitelist node types
    local accepted_types = { "file", "directory"}

    --- `path_stat` is nil means the path does not exist 
    ---   AND 
    --- Path `type` should point to a valid type (file or dir)
    if not path_stat or 
        (path_stat and not vim.tbl_contains(accepted_types, path_stat.type))
        then
            return nil
    end

    --- In case the path is a file, get the parent directory.
    if path_stat.type == "file" then
        real_path = vim.fs.dirname(real_path)
    end


    return setmetatable({
        _str =  real_path,
        _stat = path_stat,
    }, self)
end


---@param hidden boolean Whether to add hidden directories or not.
---@param follow boolean Whehter to follow symlinks or not.
---@param filter_project function(path_name) -> boolean Function to filter based on the
    --- directory name. Return true to add the directory, false otherwise
function Path:scan(hidden, follow, filter_project)

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

        if should_insert and filter_project(path) then
            table.insert(dirs, abs_path) 
        end
    end

    return dirs
end


return Path


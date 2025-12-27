# Whaler

![Whaler Logo](whaler-logo.png)

Lost in the ocean of your unordered and unorganized file-explorer looking for that project? Whaler has you covered.

## What is Whaler?

**Whaler** is a minimalist project / directory navigator. It provides a clean interface to work with projects.

It is based on the concept of [tmux-windowizer](https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-windowizer) from [ThePrimeagen](https://github.com/ThePrimeagen) which uses a set of directories and [fzf](https://github.com/junegunn/fzf) to move to another directory in a new tmux session.

**Whaler** offers a fast experience to move between projects without having much hassle, while giving users the ability to customize their experience as much as possible.

![whaler-example](whaler-example.gif)

The gist of `whaler.nvim` is simple:
1. Set the parent directories where projects live. All the subdirectories will be considered projects for Whaler (`directories`).
2. If there are single directories you need as projects you can also define them (`oneoff_directories`)
3. Execute `Whaler` to move between projects!
4. You can customize Whaler to make it your own project navigator. See [Options](#options) and [API](#api) for advanced usage.

## Whaler: Table of Contents

- [Getting started](#getting-started)
- [Installation](#minimal-installation-setup)
- [Usage](#usage-example)
- [Options](#options)
- [User Events](#user-events)
- [API](#api)
- [Supported Pickers](#supported-pickers)
- [Supported File Explorers](#supported-file-explorers)
- [Related Projects](#related-projects)

## Getting Started

**Whaler** is a neovim project / directory navigator.

#### Dependencies

- [Neovim >= v0.9.0)](https://github.com/neovim/neovim/releases/tag/v0.9.0)

Optional pickers:
- [Telescope](https://github.com/nvim-telescope/telescope.nvim)
- [FzfLua](https://github.com/nvim-telescope/telescope.nvim)

#### Minimal installation setup

Using `lazy.nvim`:

```lua
return {
    "SalOrak/whaler",
    dependencies = {
        "nvim-lua/plenary.nvim"
    },
    opts = {
        -- Directories to be used as parent directories. Their subdirectories 
        -- are considered projects for Whaler.
        directories = {
            "path/to/parent/project", 
            { path = "path/to/another/parent/project", alias = "An alias!"}
        },
        -- Directories to be directly used as projects. No subdirectory lookup.
        oneoff_directories = {
            { path = "~/.local/share/nvim/lazy", alias = "Neovim Installation"}
            { path = "~/.config/", alias = "Config directory"}
        },

        -- Picker to use. By default uses `telescope` for compatibility reasons.
        -- Options are 'telescope', 'fzf_lua' and 'vanilla' (uses `vim.ui.input`).
        picker = "telescope"
    },
}
```


Or you can also set up `whaler.nvim` as a `Telescope` extension.
```lua
return {
	{
        "nvim-telescope/telescope.nvim",
		dependencies = {
            "salorak/whaler.nvim", -- Make sure to add `whaler` as a dependency.
			"nvim-lua/plenary.nvim"
        }, 
        config = function()
            local t = require("telescope")

            t.setup({
                --- ... your telescope configuration .. ---
                extensions = {
                    whaler = {
                        -- Directories to be used as parent directories. Their subdirectories 
                        -- are considered projects for Whaler.
                        directories = {
                            "path/to/parent/project", 
                            { path = "path/to/another/parent/project", alias = "An alias!"}
                        },
                        -- Directories to be directly used as projects. No subdirectory lookup.
                        oneoff_directories = {
                            { path = "~/.local/share/nvim/lazy", alias = "Neovim Installation"}
                            { path = "~/.config/", alias = "Config directory"}
                        },

                        -- Picker to use. By default uses `telescope` for compatibility reasons.
                        -- Options are 'telescope', 'fzf_lua' and 'vanilla' (uses `vim.ui.input`).
                        picker = "telescope"

                    },
                }
            })

            -- Don't forget to load Whaler as an extension!
            t.load_extension("whaler")
        end
```

## Usage example

Whaler does not have any **mappings** by default. It is up to you to create any mappings.

You can also call the `Whaler` and `WhalerSwitch` user commands.

In the Telescope configuration file:
```lua
-- Telescope setup()
local telescope = require('telescope')

telescope.setup({
    -- Your telescope setup here...
    extensions = {
        whaler = {
            -- Whaler configuration
            directories = { "path/to/dir", "path/to/another/dir", { path = "path/to/yet/another/dir", alias = "yet" } },
            -- You may also add directories that will not be searched for subdirectories
            oneoff_directories = { "path/to/project/folder",  { path = "path/to/another/project", alias = "Project Z" } },
        }
    }
})
-- More config here
telescope.load_extension("whaler")
--

-- Open whaler using <leader>fw
vim.keymap.set("n", "<leader>fw", function()
    local w = telescope.extensions.whaler.whaler
    w({
        -- Settings can also be called here.
        -- These would use but not change the setup configuration.
    })
 end,)

-- Or directly
vim.keymap.set("n", "<leader>fw", telescope.extensions.whaler.whaler)
```

In addition to passing strings into the `directories` and `oneoff_directories`
parameters above one may also choose to use tables such as
`{path="/path/to/dir", alias="Personal Projects"}`, this will modify the text
presented in the selection UI to show `[Personal Projects] theproject` instead
of the full path to each of the project folders.

Now, pressing `<leader>fw` will open a Telescope picker with the subdirectories of the specified directories for you to select.

## Options

`Whaler.nvim` shines the most when your personal touch is added. Below is the default and complete list of configuration options.
Here is the list of a default configuration:
```lua
whaler = {
    -- Path directories to search. By default the list is empty.
    directories = { "/home/user/projects", { path = "/home/user/work", alias = "work" } }, 

    -- Path directories to append directly to list of projects. By default is empty. 
    oneoff_directories = { "/home/user/.config/nvim" }, 

    -- Whether to automatically open file explorer. By default is `true`
    auto_file_explorer = true,

    -- Whether to automatically change current working directory. By default is `true`
    auto_cwd = true, 

    -- Automagically creates a configuration for the file explorer of your choice. 
    -- Options are "netrw"(default), "nvimtree", "neotree", "oil", "telescope_file_browser", "rnvimr"
    file_explorer = "netrw", 

     -- (OPTIONAL) If you want to fully customize the file explorer configuration,
     -- below are all the possible options and its default values.
    file_explorer_config = {
        -- Show hidden directories or not (default false)
        hidden = false,

        -- Plugin. Should be installed.
        plugin_name = "netrw", 

        -- The plugin command to open.
        -- Command must accept a path as parameter
        -- Prefix string to be appended after the command and before the directory path. 
        command = "Explorer", 
                              
        -- Example: In the `telescope_file_browser` the value is ` path=`.
        --          The final command is `Telescope file_browser path=/path/to/dir`.
        -- By default is " " (space)
        prefix_dir = " ",     
    },

    -- Which picker to use. One of 'telescope', 'fzf_lua' or 'vanilla'. Default to 'telescope'
    picker = "telescope", 

    -- Picker options
    -- Options to pass to Telescope. Below is the default.
    telescope_opts = {
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
    },
    -- For compatiblity you can also use `theme` directly to modify Telescope. 
    theme = {},
 
    -- Options to pass to FzfLua directly. See
    -- https://github.com/ibhagwan/fzf-lua?tab=readme-ov-file#customization for
    -- options. Below is the defaults.
    fzflua_opts= {
        prompt = "Whaler >> ",
        --- You can modify the actions! Go ahead!
        actions = {
            ["default"] = function(selected)
                    local Whaler = require'whaler'
                    local dirs_map = State:get().dirs_map

                    local display = selected[1] 
                    local path = dirs_map[selected[1]]

                    -- For changing projects and
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
            end,
    },
}
```
By default `Whaler.nvim` changes the current working directory (*cwd*) to the
selected directory AND opens the file explorer (`netrw` by default). 

Changing `auto_cwd` to `false` will make Whaler to only open the file explorer
in the selected directory while maintaining the previous current working
directory.

Changing `auto_file_explorer` to `false` while keeping `auto_cwd` enabled will
make Whaler to change the current working directory to the selected one but
without losing the current file. 

The `file_explorer` is a shortcut that automatically creates a
`file_explorer_config` with some basics commands. You can, for example, use the
default `netrw` but instead of using `Explore` you can use `VExplore`. Below the
configuration changes to use `VExplore` instead of `Explore`.
```lua
whaler = {
    -- Some config here
    file_explorer_config = {
        plugin_name = "netrw", -- Plugin name.
        command = "Vexplore", -- Vertical file explorer command
        prefix_dir = " ", -- (Optional) By default is space.  
    },
}
```


## User Events

`whaler.nvim` automatically fires user events on certain moments. These are the following:

- `WhalerPre`: Before executing the picker. It contains the dictionary of
  projects. It always fires when executing `whaler`.
- `WhalerPost`: After executing the picker. Contains the current state (path and display). 
  It only fires when the picker calls `select`. Beware of it if you customize the actions.
- `WhalerPreSwitch`: Before actually switching projects. Contains the previous
  and next states (path and display). Fired when calling the `switch` function.
- `WhalerPostSwitch`: After switching to another project. Fired when calling the
  `switch` function.

See [API](#api) to know more about using the `Whaler.nvim` API.

## API

The exposed API interface is quite small. There are only 4 functions to use.

1. `whaler(run_opts)`

```lua
---@param run_opts table General options for runtime mods.
function whaler(run_opts) end
```
Generates the project list and executes a command on the
project, usually a file explorer like `netrw` or `oil`. The `run_opts` are
runtime options. These options are the same ones used during the `setup` section
and they overwrite them. Allows for fine grain control of `whaler`. You can
create multiple `whaler` functions that act on different projects lists, execute
different commands or have different themes. Fires `WhalerPre` after generating
the projects list. The data object contains a key called `projects` with the
projects.

2. `switch(path, display)`

```lua
---@param path string Path to project to switch to.
---@param display string? Name of the project to switch to. 
function switch(path, display) end
```

Switches to another path, changing the current whaler project state. It fires
the `WhalerPreSwitch` before switching and `WhalerPostSwitch` after switching.
Use it whenever you want to change to another project directly.


3. `select(path, display)`

```lua
---@param path string Path to project to switch to.
---@param display string? Name of the project to switch to. 
function select(path, display) end
```
Core functionality for all Pickers. It uses the configuration to perform differents tasks: 
- Calling `switch` if `auto_cwd` is set to true.
- Executing the file explorer command whenever `auto_file_explorer` is set to
  true.
- Finally, firing the `WhalerPost` user event.


4. `current()`
```lua
---@return {path: string?, display?} table Current state
function current() end
```

Returns the current state of Whaler. That is, the project (path) selected as
well as the display name. They both can be nil. Useful when you want to act on
the current project.


## Supported Pickers

Currently there are only 3 supported pickers:
- `vanilla`: Does not require any external plugin. It uses `vim.ui.input`. 
- `telescope`: Uses `Telescope`.
- `fzf_lua`: Uses `FzfLua`.


## Supported File Explorers

Currently the following file explorers are supported out of the box:
- [netrw](): Default and fallback option.
- [Neo-Tree](https://github.com/nvim-neo-tree/neo-tree.nvim). Does not require any configuration.
- [Oil](https://github.com/stevearc/oil.nvim). Does not require any configuration.
- [Nvim-Tree](https://github.com/nvim-tree/nvim-tree.lua). To work as intended add `sync_root_with_cwd = true` in the `nvim-tree` setup function.
- [Telescope-file-browser](https://github.com/nvim-telescope/telescope-file-browser.nvim). Does not require any configuration.
- [rnvimr](https://github.com/kevinhwang91/rnvimr). To work as intended add the following code to the `rnvimr` settings file and add the `file_explorer = "rnvimr"` in the `whaler` configuration block. If the ranger window seems "buggy" get into insert mode `i` and it should work as usual.

```lua
-- Setup rnvimr
vim.api.nvim_create_user_command("RnvimrOpen", function(args)
    if #args.fargs == 1 then
       local arg = vim.fn.expand(args.fargs[1])
       vim.api.nvim_call_function("rnvimr#open", { arg })
    else
       vim.api.nvim_command("RnvimrToggle")
    end
end, { nargs = "?" })

vim.api.nvim_set_keymap( "n", "<leader>e", ":RnvimrOpen<CR>", { noremap = true, desc = "Ranger File Explorer" })
```

## Related projects

There are MANY file explorers in the neovim communniity, check them out! 

But there are many extensions and projects that do relatively the same thing. 

Check them out:
- [telescope-pathogen](https://github.com/brookhong/telescope-pathogen.nvim)
- [telescope-project](https://github.com/nvim-telescope/telescope-project.nvim)
- [telescope-repo](https://github.com/cljoly/telescope-repo.nvim)

You can find more telescope extensions in the [Telescope Extensions Wiki](https://github.com/nvim-telescope/telescope.nvim/wiki/Extensions).

If you use or prefer any other let me know and I'll add them here.

## Credits
Shoutouts to all the great contributrs actively working on `Whaler.nvim` that helped shape the plugin.
- [GCBallesteros](https://github.com/GCBallesteros) - for constantly suggesting and developing Whaler. 



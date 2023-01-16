--[[ TODOS

TODO: Pin versions for as many projects that support it.
TODO: For repositories that don't use release tagging with semver - open an issue in their repo to request that they add it (so that it works well with folke/lazy.nvim)
TODO: Check out mini.nvim: https://github.com/echasnovski/mini.nvim

--]]

-- Top-level Imports

require("main.opts")
require("main.autocmds")
require("main.remap")
require("main.lazy") -- plugins here

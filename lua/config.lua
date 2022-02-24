---@diagnostic disable: different-requires
-- High-Level
require("globals")
require("mappings")
require("settings")
require("plugins")
require("plugin.which-key")
require("appearance")

vim.g.python3_host_prog = "~/.pyenv/versions/nvim/bin/python3"

-- Plugin configs (in lua/plugin) -- TODO: Figure out how to source everything at once in a runtime dir
require("plugin.lsp")
require("plugin.treesitter")
require("plugin.nvim-hlslens")
require("plugin.lualine")
require("plugin.numb")
require("plugin.nvim-tree")
require("plugin.nvim-cmp")
require("plugin.nvim-autopairs")
require("plugin.nvim-ts-autotag")
require("plugin.aerial")
require("plugin.null-ls")
require("plugin.vim-easy-align")
require("plugin.vim-matchup")
require("plugin.vim-cutlass")
require("plugin.lightspeed")
require("plugin.Comment")
require("plugin.telescope")
require("plugin.nvim-gps")
require("plugin.neogit")
require("plugin.bufferline")
require("plugin.vim-doge")
require("plugin.colorizer")
require("plugin.indent-blankline")
require("plugin.supertab")
require("plugin.vim-rooter")
require("plugin.gutentag")
require("plugin.trouble")
require("plugin.cheatsheet")
require("plugin.mkdx")
require("plugin.spectre")
require("plugin.todo-comments")
require("plugin.gitsigns")
require("plugin.vim-smartq")
require("plugin.vim-LineJuggler")
require("plugin.neogit")
require("plugin.diffview")
require("plugin.tabout")
require("plugin.lua-dev")
require("plugin.specs")

-- Language-specific
require("plugin.vim-go")
require("plugin.glow")

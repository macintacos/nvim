-- High-Level
require("globals")
require("settings")
require("plugins")
require("appearance")

-- Plugin configs (in lua/)
require("plug.telescope")
require("plug.treesitter")
require("plug.vimspector")
require("plug.vim-doge")
require("plug.colorizer")
require("plug.galaxyline")
require("plug.indent-blankline")
-- require("plug.nvim-bufferline")
require("plug.barbar")
require("plug.dashboard")

-- CoC.nvim
require("coc.python")

-- Language-specific
require("plug.vim-go")
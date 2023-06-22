-- "Orchestrator" of all things LSP. Gets loaded in after/plugin/lsp.lua
-- In general, if a "setup" becomes a bit to unweildy, it will be refactored out into its own file(s)
-- This project relies on lsp-zero to work properly: https://github.com/VonHeikemen/lsp-zero.nvim
require("neodev").setup()

local lsp = require("main.lsp.zero").lsp

require("main.lsp.mason")
require("main.lsp.cmp")

lsp.setup()

-- Needs to happen after LSPs are setup
require("main.lsp.null-ls")

-- github.com/andymass/vim-matchup
-- Enhanced % matching with treesitter support
vim.pack.add({ "https://github.com/andymass/vim-matchup" })
vim.g.matchup_treesitter_stopline = 500
-- Config and TreesitterConfig require every key, but setup() only sets the keys given as vim.g variables.
---@diagnostic disable-next-line: param-type-mismatch
require("match-up").setup({
  ---@diagnostic disable-next-line: missing-fields
  treesitter = { stopline = 500 },
})

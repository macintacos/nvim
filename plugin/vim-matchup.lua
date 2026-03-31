-- github.com/andymass/vim-matchup
-- Enhanced % matching with treesitter support
vim.pack.add({ "https://github.com/andymass/vim-matchup" })
vim.g.matchup_treesitter_stopline = 500
require("match-up").setup({
  treesitter = { stopline = 500 },
})

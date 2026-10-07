-- github.com/lewis6991/gitsigns.nvim
-- Git change indicators in the sign column
vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })
require("gitsigns").setup({
  -- Hunks as git and GitHub cut them: a hunk's removed lines, then its added ones.
  -- Neovim's default 'diffopt', which gitsigns otherwise follows, has linematch:40,
  -- which splits a hunk into pairs of similar lines, so changeset's unified diff
  -- interleaved removed and added lines.
  diff_opts = { linematch = 0 },
})

-- github.com/macintacos/changeset.nvim
-- A read-only sidebar mapping what this branch changed, nested by the symbols each hunk touched
-- No release tag yet — tracks an unmerged branch.
vim.pack.add({ { src = "https://github.com/macintacos/changeset.nvim", version = "incorporating-feedback" } })
require("changeset").setup({
  keymaps = { next = "]h", prev = "[h" },
  -- Off the default branch, diffs gitsigns against the fork point; `:Changeset review` (<leader>gP, <leader>Tp) errors without it.
  pr_review = { enabled = true },
  -- The statuscolumn draws the comment bubble in its fold slot instead.
  review_comment = { sign = false },
})

-- Mapped here rather than in plugin/which-key.lua so it travels with the plugin.
-- A plain keymap with a `desc` is all which-key needs to label it; `add()` is for
-- groups and description-only entries, and the <leader>g group already exists.
vim.keymap.set("n", "<leader>gp", "<Plug>(changeset-toggle)", { desc = "Changeset (changed files & symbols)" })

-- github.com/macintacos/changeset.nvim
-- A read-only sidebar mapping what this branch changed, nested by the symbols each hunk touched
-- No release tag yet — tracks an unmerged branch.
vim.pack.add({ "https://github.com/macintacos/changeset.nvim" })
require("changeset").setup({
  review = {
    header = "/superpowers:receiving-code-review Use /dispatch-subagent to implement the suggested changes as needed.",
  },
  -- sign: the statuscolumn draws the comment bubble in its fold slot instead.
  -- blocks: each review comment's whole text in a box under its line; <C-g>ct hides them.
  review_comment = { sign = false, blocks = true },
})

-- Mapped here rather than in plugin/which-key.lua so it travels with the plugin.
-- A plain keymap with a `desc` is all which-key needs to label it; `add()` is for
-- groups and description-only entries, and the <leader>g group already exists.
vim.keymap.set("n", "<leader>gp", "<Plug>(changeset-toggle)", { desc = "Changeset (changed files & symbols)" })
vim.keymap.set("n", "]h", "<Plug>(changeset-preview-next)", { desc = "Next changeset row" })
vim.keymap.set("n", "[h", "<Plug>(changeset-preview-prev)", { desc = "Previous changeset row" })

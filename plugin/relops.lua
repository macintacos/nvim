-- github.com/kvnduff/relops.nvim
-- Delete, yank, change, or move a line or range away from the cursor without jumping to it.

-- Local working copy: putting it on the runtimepath means edits to the clone
-- show up on the next restart. Swap this line for the remote when it ships:
--   vim.pack.add({ "https://github.com/kvnduff/relops.nvim" })
vim.opt.runtimepath:prepend(vim.fn.expand("~/GitLocal/Play/relops.nvim/main"))

require("relops").setup({
  -- cutlass owns `m` as its cut operator; relops' default `mr` claims all of
  -- `m` through a dispatcher, so move gets its own leader mapping instead.
  mappings = { move = "<leader>m" },
  preview = { enabled = true },
})

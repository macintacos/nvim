-- github.com/obsidian-nvim/obsidian.nvim
-- Obsidian vault integration (links, tags, search, etc.)
vim.pack.add({ "https://github.com/obsidian-nvim/obsidian.nvim" }, { load = false })

-- Only load when opening a markdown file inside the vault directory
vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
  pattern = vim.fn.expand("~/Dropbox/Brain") .. "/*.md",
  once = true,
  callback = function()
    vim.cmd.packadd("obsidian.nvim")
    require("obsidian").setup({
      legacy_commands = false,
      workspaces = {
        { name = "Brain", path = "~/Dropbox/Brain" },
      },
    })
  end,
})

return {
  {
    "epwalsh/obsidian.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    lazy = true,
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    event = {
      "BufReadPre " .. vim.fn.expand("~") .. "/Library/CloudStorage/Dropbox/Brain/*.md",
      "BufNewFile " .. vim.fn.expand("~") .. "/Library/CloudStorage/Dropbox/Brain/*.md",
    },
    opts = {
      workspaces = {
        {
          name = "Brain",
          path = "~/Library/CloudStorage/Dropbox/Brain",
        },
      },
    },
  },
  {
    "saghen/blink.cmp",
    dependencies = {
      { "saghen/blink.compat", lazy = true, version = false },
    },
    opts = {
      sources = {
        default = { "obsidian", "obsidian_new", "obsidian_tags" },
        providers = {
          obsidian = {
            name = "obsidian",
            module = "blink.compat.source",
          },
          obsidian_new = {
            name = "obsidian_new",
            module = "blink.compat.source",
          },
          obsidian_tags = {
            name = "obsidian_tags",
            module = "blink.compat.source",
          },
        },
      },
    },
  },
}

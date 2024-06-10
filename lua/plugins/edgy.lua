-- Use this to control window layouts and the like.
-- In particular, this controls where things like Neotree, the terminal, etc. are located and how they behave.
return {
  "folke/edgy.nvim",
  opts = {
    animate = { enabled = false },
    left = {
      {
        title = "Neo-Tree Git",
        ft = "neo-tree",
        filter = function(buf)
          return vim.b[buf].neo_tree_source == "git_status"
        end,
        pinned = true,
        open = "Neotree position=right git_status",
      },
      { title = "Neotest Summary", ft = "neotest-summary" },
    },
    right = {
      {
        title = "Neo-Tree",
        ft = "neo-tree",
        filter = function(buf)
          return vim.b[buf].neo_tree_source == "filesystem"
        end,
        pinned = true,
        open = function()
          require("neo-tree.command").execute({ dir = LazyVim.root() })
        end,
        size = { height = 0.5 },
      },
      {
        title = "Neo-Tree Buffers",
        ft = "neo-tree",
        filter = function(buf)
          return vim.b[buf].neo_tree_source == "buffers"
        end,
        pinned = true,
        open = "Neotree position=top buffers",
      },
      "neo-tree",
    },
  },
}

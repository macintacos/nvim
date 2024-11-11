return {
  {
    "nvimdev/dashboard-nvim",
    opts = function(_, opts)
      -- Add new actions to the list
      opts.config.center = vim.tbl_extend("force", {
        { action = "Neotree", desc = "  Show Explorer", icon = "󰙅", key = "e" },
      }, opts.config.center)

      return opts
    end,
  },
}

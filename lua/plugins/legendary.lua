-- github.com/mrjones2014/legendary.nvim
-- Search through all available commands

local Cmd = require("config.helpers").Cmd

---@module "lazy"
---@type LazySpec
return {
  "mrjones2014/legendary.nvim",
  -- since legendary.nvim handles all your keymaps/commands,
  -- its recommended to load legendary.nvim before other plugins
  priority = 10000,
  lazy = false,
  -- To use frecency sorting
  dependencies = { "kkharji/sqlite.lua" },
  opts = {
    extensions = {
      which_key = { auto_register = true },
      lazy_nvim = { auto_register = true },
    },
    sort = {
      frecency = {
        -- the directory to store the database in
        db_root = string.format("%s/legendary/", vim.fn.stdpath("data")),
        -- the maximum number of timestamps for a single item
        -- to store in the database
        max_timestamps = 10,
      },
    },
  },
  keys = {
    { "<leader><leader>", Cmd("Legendary"), desc = "Search All Commands" },
  },
}

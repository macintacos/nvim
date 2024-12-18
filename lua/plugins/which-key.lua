--[[
The best keymapping system in the land.

'which-key' keymaps are defined in a variety of places, not in this file. Those places are:

- `lua/config/keymaps.lua`
- Respective plugin definitions (in `lua/plugins`)
--]]

local Cmd = require("config.helpers").Cmd
local Snacks = require("snacks")

return {
  "folke/which-key.nvim",
  opts = {
    spec = {
      -- Buffers
      { "<leader>bz", Cmd("ZenMode"), desc = "Zen Mode" },
      { "<leader>by", Cmd("%y"), desc = "Copy Buffer Text" },

      -- Files
      { "<leader>fs", Cmd("w"), desc = "Save Current File" },
      { "<leader>fS", Cmd("wa"), desc = "Save All Open Files" },
      { "<leader>fu", Cmd("Neotree reveal"), desc = "Unveil in Neotree" },
      { "<leader>f=", Cmd("Format"), desc = "Format Current File" },
      { "<leader>fd", Cmd("DeleteFile"), desc = "Delete Current File", icon = "" },
      {
        "<leader>fr",
        function()
          Snacks.rename.rename_file()
        end,
        desc = "Rename File",
        icon = "󰑕",
      },
      {
        "<leader>ft",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = LazyVim.root() })
        end,
        desc = "Explorer NeoTree (Root Dir)",
        icon = "",
      },

      -- Help
      { "<leader>h", group = "help", icon = "?" },
      { "<leader>hc", Cmd("Legendary"), desc = "Search Legendary" },
      { "<leader>hh", Cmd("FzfLua help_tags"), desc = "Search All Help Docs" },
      { "<leader>hm", Cmd("FzfLua keymaps"), desc = "Search All Keymaps" },
      { "<leader>hM", Cmd("FzfLua man_pages"), desc = "Search All Manpages" },
      { "<leader>hH", Cmd("FzfLua highlights"), desc = "Search All Highlights" },

      -- Windows
      { "<leader>w-", Cmd("rightbelow sb"), desc = "Split Window Horizontal" },
      { "<leader>w/", Cmd("vertical rightbelow sb"), desc = "Split Window Vertical" },

      { "<leader>wf", group = "file new window" },
      {
        "<leader>wfv",
        "<Cmd>vertical rightbelow sb<CR><Cmd>FzfLua files<CR>",
        desc = "New File Split Right",
      },
      {
        "<leader>wf/",
        "<Cmd>vertical rightbelow sb<CR><Cmd>FzfLua files<CR>",
        desc = "New File Split Right",
      },
      {
        "<leader>wfl",
        "<Cmd>vertical rightbelow sb<CR><Cmd>FzfLua files<CR>",
        desc = "New File Split Right",
      },
      {
        "<leader>wfh",
        "<Cmd>vertical sb<CR><Cmd>FzfLua files<CR>",
        desc = "New File Split Left",
      },
      {
        "<leader>wfs",
        "<Cmd>rightbelow sb<CR><Cmd>FzfLua files<CR>",
        desc = "New File Split Below",
      },
      {
        "<leader>wf-",
        "<Cmd>rightbelow sb<CR><Cmd>FzfLua files<CR>",
        desc = "New File Split Below",
      },
      {
        "<leader>wfj",
        "<Cmd>rightbelow sb<CR><Cmd>FzfLua files<CR>",
        desc = "New File Split Below",
      },
    },
  },
}

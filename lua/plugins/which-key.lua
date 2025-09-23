-- github.com/folke/which-key.nvim
-- The best keymapping tool

local Cmd = require("config.helpers").Cmd
local Snacks = require("snacks")

---@module "lazy"
---@type LazySpec
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    -- stylua: ignore
    spec = {
      { "<leader>?", function() require("which-key").show({ global = false }) end,
        desc = "Buffer Local Keymaps (which-key)" },

      -- Buffers
      { "<leader>b", group = "buffers" },
      { "<leader>bn", Cmd("bnext"), desc = "Next Buffer" },
      { "<leader>bp", Cmd("bprevious"), desc = "Prev Buffer" },
      { "<leader>bb", function() Snacks.picker.buffers() end, desc = "Show Open Buffers" },
      { "<leader>bd", function() Snacks.bufdelete() end, { desc = "Delete Buffer" } },
      { "<leader>bD", function() Snacks.bufdelete.other() end, desc = "Delete Other Buffers" },
      { "<leader>by", Cmd("%y"), desc = "Copy Buffer Text" },
      { "<leader>bz", function() Snacks.zen() end, desc = "Zen Mode" },

      -- Files
      { "<leader>f", group = "files" },
      ---@diagnostic disable-next-line: undefined-field
      { "<leader>ff", function() require("fff").find_files() end, desc = "FFFind Files" },
      { "<leader>fn", Cmd("enew"), desc = "New File" },
      { "<leader>fe", Cmd("Neotree reveal right"), desc = "Show Explorer" },
      { "<leader>fu", Cmd("Neotree focus right"), desc = "Unveil in Neotree" },
      { "<leader>fR", function() Snacks.rename.rename_file() end, desc = "Rename File" },

      -- Git
      { "<leader>g", group = "git" },
      { "<leader>gs", function() Snacks.lazygit.open() end, desc = "Open Lazygit" },
      { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git Log" },
      { "<leader>gb", function() Snacks.picker.git_log_line() end, desc = "Git Blame Line" },
      { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Git Log File" },
      { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse (open)" },

      -- Help
      { "<leader>H", group = "help", icon = "?" },
      { "<leader>Hk", Cmd("norm! K"), desc = "Lookup Keyword Under Cursor" },
      { "<leader>Hc", Cmd("Legendary"), desc = "Search Legendary" },
      { "<leader>Hh", function() Snacks.picker.help() end, desc = "Search All Help Docs" },
      { "<leader>Hm", function() Snacks.picker.keymaps() end, desc = "Search All Keymaps" },
      { "<leader>HM", function() Snacks.picker.man() end, desc = "Search All Manpages" },
      { "<leader>HH", function() Snacks.picker.highlights() end, desc = "Search All Highlights" },

      -- Open various UIs
      { "<leader>o", group = "open..." },
      { "<leader>ol",
        function()
          local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
          if not success and err then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end,
        desc = "Location List" },
      { "<leader>oq",
        function()
          local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
          if not success and err then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end, desc = "Quickfix List" },

      -- Search
      { "<leader>sr",
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.open({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end,
        mode = { "n", "v" },
        desc = "Search and Replace" },
      -- Tabs
      {"<leader><tab><tab>", Cmd("tabnew"), { desc = "New Tab" }},
      {"<leader><tab>[", Cmd("tabprevious"), { desc = "Previous Tab" }},
      {"<leader><tab>]", Cmd("tabnext"), { desc = "Next Tab" }},
      {"<leader><tab>d", Cmd("tabclose"), { desc = "Close Tab" }},
      {"<leader><tab>f", Cmd("tabfirst"), { desc = "First Tab" }},
      {"<leader><tab>l", Cmd("tablast"), { desc = "Last Tab" }},
      {"<leader><tab>n", Cmd("tabnew"), { desc = "New Tab" }},
      {"<leader><tab>o", Cmd("tabonly"), { desc = "Close Other Tabs" }},

      -- Toggles
      { "<leader>T", group = "ui/toggles" },
      { "<leader>TL", function() Snacks.toggle.option("relativenumber", { name = "Relative Number" }) end, desc = "Relative Number" },
      { "<leader>TT", function() Snacks.toggle.treesitter() end, desc = "Treesitter" },
      { "<leader>Tb", function() Snacks.toggle.option("background", {off = "light", on = "dark", name = "Dark Background"}) end, desc = "Dark Background" },
      { "<leader>Tc", function() Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" }) end, desc = "Conceal Level" },
      { "<leader>Th", function() Snacks.toggle.inlay_hints() end, desc = "Inlay Hints" },
      { "<leader>Tl", function() Snacks.toggle.line_number() end, desc = "Line Number" },
      { "<leader>Td", function() Snacks.toggle.dim() end, desc = "Dim" },
      { "<leader>Ta", function() Snacks.toggle.animate() end, desc = "Animations" },
      { "<leader>Ts", function() Snacks.toggle.option("spell", { name = "Spelling" }) end, desc = "Spelling" },
      { "<leader>Tt", function() Snacks.toggle.option("showtabline", { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline" }) end, desc = "Tabline" },
      { "<leader>Tw", function() Snacks.toggle.option("wrap", { name = "Wrap" }) end, desc = "Word Wrap" },
      { "<leader>Ti", function() Snacks.toggle.indent() end, desc = "Indentation" },
      { "<leader>Tz", function() Snacks.zen() end, desc = "Zen Mode" },

      -- Windows
      { "<leader>w", group = "window", proxy = "<C-w>" },
      { "<leader>w-", Cmd("rightbelow sb"), desc = "Split Window Horizontal" },
      { "<leader>w/", Cmd("vertical rightbelow sb"), desc = "Split Window Vertical" },
      { "<leader>wd", "<C-w>c", desc = "Delete Window" },
      { "<leader>wz", function() Snacks.zen() end, desc = "Zen Mode" },
    },
  },
}

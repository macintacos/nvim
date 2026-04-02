-- github.com/folke/which-key.nvim
-- Displays available keybindings in a popup as you type
vim.pack.add({ "https://github.com/folke/which-key.nvim" }, { load = false })

vim.schedule(function()
  vim.cmd.packadd("which-key.nvim")

  local Cmd = require("config.helpers").Cmd
  local Snacks = require("snacks")

  require("which-key").setup({
    -- stylua: ignore
    spec = {
      -- Top-level Things
      { "<leader>?", function() require("which-key").show({ global = false }) end,
        desc = "Buffer Local Keymaps (which-key)" },
      { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep Project" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader><leader>", function() Snacks.picker.commands() end, desc = "Search All Commands" },

      -- Buffers
      { "<leader>b", group = "buffers" },
      { "<leader>bn", Cmd("bnext"), desc = "Next Buffer" },
      { "<leader>bp", Cmd("bprevious"), desc = "Prev Buffer" },
      { "<leader>bb", function() Snacks.picker.buffers() end, desc = "Show Open Buffers" },
      { "<leader>bd", function() Snacks.bufdelete() end, { desc = "Delete Buffer" } },
      { "<leader>bD", function() Snacks.bufdelete.other() end, desc = "Delete Other Buffers" },
      { "<leader>by", Cmd("%y"), desc = "Copy Buffer Text" },
      { "<leader>bs", function () Snacks.picker.lines() end, desc = "Search Buffer Lines"},
      { "<leader>bz", function() Snacks.zen() end, desc = "Zen Mode" },

      -- Files
      { "<leader>f", group = "files" },
      ---@diagnostic disable-next-line: undefined-field
      { "<leader>ff", function() require("fff").find_files() end, desc = "FFFind Files" },
      { "<leader>fn", Cmd("enew"), desc = "New File" },
      { "<leader>fe", function() MiniFiles.open() end, desc = "Show Explorer" },
      { "<leader>fu",
        function()
          MiniFiles.open(vim.api.nvim_buf_get_name(0), true)
        end,
        desc = "Unveil in Explorer" },
      { "<leader>fR", function() Snacks.rename.rename_file() end, desc = "Rename File" },
      { "<leader>f=", function() require("conform").format({ async = true }) end, desc = "Format File" },
      { "<leader>fs", Cmd("w"), desc = "Save File" },
      { "<leader>fS", Cmd("noautocmd w"), desc = "Save File (no format)" },

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
      { "<leader>on", group = "Noice" },
      { "<leader>onl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
      { "<leader>onh", function() require("noice").cmd("history") end, desc = "Noice History" },
      { "<leader>ona", function() require("noice").cmd("all") end, desc = "Noice All" },
      { "<leader>ond", function() require("noice").cmd("dismiss") end, desc = "Dismiss All" },
      { "<leader>ont", function() require("noice").cmd("pick") end, desc = "Noice Picker" },

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
      { "<leader>ss", function () Snacks.picker.lines() end, desc = "Buffer Lines"},
      { "<leader>sp", function () Snacks.picker.grep() end, desc = "Grep Project"},
      { "<leader>sb", function () Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers"},

      -- Jump to
      { "<leader>j", group = "jump to..." },
      { "<leader>ji", function() Snacks.picker.lsp_symbols() end, desc = "Symbols in File" },
      { "<leader>jI", function() Snacks.picker.lsp_workspace_symbols() end, desc = "Symbols in Workspace" },

      -- Tabs
      {"<leader><tab><tab>", Cmd("tabnew"), desc = "New Tab" },
      {"<leader><tab>[", Cmd("tabprevious"), desc = "Previous Tab" },
      {"<leader><tab>]", Cmd("tabnext"), desc = "Next Tab" },
      {"<leader><tab>d", Cmd("tabclose"), desc = "Close Tab" },
      {"<leader><tab>f", Cmd("tabfirst"), desc = "First Tab" },
      {"<leader><tab>l", Cmd("tablast"), desc = "Last Tab" },
      {"<leader><tab>n", Cmd("tabnew"), desc = "New Tab" },
      {"<leader><tab>o", Cmd("tabonly"), desc = "Close Other Tabs" },

      -- Toggles
      { "<leader>T", group = "ui/toggles" },
      { "<leader>TL", function() Snacks.toggle.option("relativenumber", { name = "Relative Number" }):toggle() end, desc = "Relative Number" },
      { "<leader>TT", function() Snacks.toggle.treesitter():toggle() end, desc = "Treesitter" },
      { "<leader>Tb", function() Snacks.toggle.option("background", {off = "light", on = "dark", name = "Dark Background"}):toggle() end, desc = "Dark Background" },
      { "<leader>Tc", function() Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" }):toggle() end, desc = "Conceal Level" },
      { "<leader>Th", function() Snacks.toggle.inlay_hints():toggle() end, desc = "Inlay Hints" },
      { "<leader>Tl", function() Snacks.toggle.line_number():toggle() end, desc = "Line Number" },
      { "<leader>Td", function() Snacks.toggle.dim():toggle() end, desc = "Dim" },
      { "<leader>Ta", function() Snacks.toggle.animate():toggle() end, desc = "Animations" },
      { "<leader>Ts", function() Snacks.toggle.option("spell", { name = "Spelling" }):toggle() end, desc = "Spelling" },
      { "<leader>Tt", function() Snacks.toggle.option("showtabline", { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline" }):toggle() end, desc = "Tabline" },
      { "<leader>Tw", function() Snacks.toggle.option("wrap", { name = "Wrap" }):toggle() end, desc = "Word Wrap" },
      { "<leader>Ti", function() Snacks.toggle.indent():toggle() end, desc = "Indentation" },
      { "<leader>Tz", function() Snacks.zen() end, desc = "Zen Mode" },

      -- Windows
      { "<leader>w", group = "window", proxy = "<C-w>" },
      { "<leader>w-", Cmd("rightbelow sb"), desc = "Split Window Horizontal" },
      { "<leader>w/", Cmd("vertical rightbelow sb"), desc = "Split Window Vertical" },
      { "<leader>wd", "<C-w>c", desc = "Delete Window" },
      { "<leader>wz", function() Snacks.zen() end, desc = "Zen Mode" },
    },
  })
end)

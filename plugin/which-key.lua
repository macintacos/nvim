-- github.com/folke/which-key.nvim
-- Displays available keybindings in a popup as you type
vim.pack.add({ "https://github.com/folke/which-key.nvim" }, { load = false })

vim.schedule(function()
  vim.cmd.packadd("which-key.nvim")

  local Cmd = require("helpers.mappings").Cmd
  local Snacks = require("snacks")
  local Paths = require("helpers.paths")

  require("which-key").setup({
    preset = "helix",

    -- stylua: ignore
    spec = {
      -- Top-level Things
      { "<leader>?", function() require("which-key").show({ global = false }) end,
        desc = "Buffer Local Keymaps (which-key)" },
      { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep Project" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader><leader>", function() Snacks.picker.commands() end, desc = "Search All Commands" },

      -- Buffers
      { "<leader>b", group = "buffers", icon = { icon = "󰈔", color = "cyan" } },
      { "<leader>bn", Cmd("bnext"), desc = "Next Buffer" },
      { "<leader>bp", Cmd("bprevious"), desc = "Prev Buffer" },
      { "<leader>bb", function() Snacks.picker.buffers() end, desc = "Show Open Buffers" },
      { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
      { "<leader>bD", function() Snacks.bufdelete.other() end, desc = "Delete Other Buffers" },
      { "<leader>by", Cmd("%y"), desc = "Copy Buffer Text" },
      { "<leader>bs", function () Snacks.picker.lines() end, desc = "Search Buffer Lines"},
      { "<leader>bz", function() Snacks.zen() end, desc = "Zen Mode" },

      -- Files
      { "<leader>f", group = "files", icon = { icon = "󰉋", color = "cyan" } },
      ---@diagnostic disable-next-line: undefined-field
      { "<leader>ff", function() require("fff").find_files() end, desc = "FFFind Files" },
      { "<leader>fn", Cmd("enew"), desc = "New File" },
      { "<leader>ft", function() Snacks.scratch() end, desc = "Scratch Buffer" },
      { "<leader>fe", function() MiniFiles.open() end, desc = "Show mini.files" },
      { "<leader>fE", function() Snacks.explorer() end, desc = "Show Snacks Explorer" },
      { "<leader>fu",
        function()
          MiniFiles.open(vim.api.nvim_buf_get_name(0), true)
        end,
        desc = "Unveil in Explorer" },
      { "<leader>fR", function() Snacks.rename.rename_file() end, desc = "Rename File" },
      { "<leader>f=", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, desc = "Format File" },
      { "<leader>fl", function() require("plugins.ftchooser").open() end, desc = "Set Filetype" },
      { "<leader>fs", Cmd("w"), desc = "Save File" },
      { "<leader>fS", Cmd("noautocmd w"), desc = "Save File (no format)" },

      -- Files > Copy paths
      { "<leader>fy", group = "copy", icon = { icon = "󰅍", color = "yellow" } },
      { "<leader>fyp", function() Paths.copy(Paths.path(0), "relative path") end, desc = "Relative Path" },
      { "<leader>fyP", function() Paths.copy(Paths.path(0, { absolute = true }), "absolute path") end, desc = "Absolute Path" },
      { "<leader>fyl", function() Paths.copy(Paths.path(0, { with_line = true }), "relative path:line") end, desc = "Relative Path:Line" },
      { "<leader>fyL", function() Paths.copy(Paths.path(0, { absolute = true, with_line = true }), "absolute path:line") end, desc = "Absolute Path:Line" },
      { "<leader>fyn", function() Paths.copy(Paths.path(0, { basename = true }), "filename") end, desc = "Filename" },
      { "<leader>fyd", function() Paths.copy(Paths.path(0, { dir_only = true }), "relative dir") end, desc = "Relative Dir" },
      { "<leader>fyD", function() Paths.copy(Paths.path(0, { absolute = true, dir_only = true }), "absolute dir") end, desc = "Absolute Dir" },
      { "<leader>fyw",
        function()
          local list = vim.tbl_map(function(b) return Paths.path(b) end, Paths.tab_window_buffers())
          Paths.copy(list, "relative paths")
        end,
        desc = "Visible Windows: Relative Paths" },
      { "<leader>fyW",
        function()
          local list = vim.tbl_map(function(b) return Paths.path(b, { absolute = true }) end, Paths.tab_window_buffers())
          Paths.copy(list, "absolute paths")
        end,
        desc = "Visible Windows: Absolute Paths" },

      -- Git
      { "<leader>g", group = "git", icon = { cat = "filetype", name = "git" } },
      { "<leader>gs", function() Snacks.lazygit.open() end, desc = "Open Lazygit" },
      { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git Log" },
      { "<leader>gb", function() Snacks.picker.git_log_line() end, desc = "Git Blame Line" },
      { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Git Log File" },
      { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse (open)" },
      { "<leader>gd", "<Cmd>CodeDiff<CR>", desc = "Diff Changed Files (CodeDiff)" },
      { "<leader>gh", "<Cmd>CodeDiff history<CR>", desc = "File History (CodeDiff)" },

      -- Help
      { "<leader>h", group = "help", icon = { icon = "󰋖", color = "purple" } },
      { "<leader>hh", function() Snacks.picker.help() end, desc = "Search All Help Docs" },
      { "<leader>hm", function() Snacks.picker.man() end, desc = "Search All Manpages" },
      { "<leader>hM", function() Snacks.picker.keymaps() end, desc = "Search All Keymaps" },
      { "<leader>hk", Cmd("norm! K"), desc = "Lookup Keyword Under Cursor" },
      { "<leader>hH", function() Snacks.picker.highlights() end, desc = "Search All Highlights" },

      -- Open various UIs
      { "<leader>o", group = "open...", icon = { icon = "󰏌", color = "green" } },
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
      { "<leader>on", Cmd("messages"), desc = "Show Messages" },

      -- Search
      { "<leader>s", group = "search", icon = { icon = "", color = "green" } },
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
      { "<leader>sp", function() Snacks.picker.grep() end, desc = "Grep Project"},
      { "<leader>sb", function () Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers"},

      -- Jump to
      { "<leader>j", group = "jump to...", icon = { icon = "󰌑", color = "yellow" } },
      { "<leader>ji", function() Snacks.picker.lsp_symbols() end, desc = "Symbols in File" },
      { "<leader>jI", function() Snacks.picker.lsp_workspace_symbols() end, desc = "Symbols in Workspace" },

      -- Tabs
      { "<leader><tab>", group = "tabs", icon = { icon = "󰓩", color = "purple" } },
      {"<leader><tab><tab>", Cmd("tabnew"), desc = "New Tab" },
      {"<leader><tab>[", Cmd("tabprevious"), desc = "Previous Tab" },
      {"<leader><tab>]", Cmd("tabnext"), desc = "Next Tab" },
      {"<leader><tab>d", Cmd("tabclose"), desc = "Close Tab" },
      {"<leader><tab>f", Cmd("tabfirst"), desc = "First Tab" },
      {"<leader><tab>l", Cmd("tablast"), desc = "Last Tab" },
      {"<leader><tab>n", Cmd("tabnew"), desc = "New Tab" },
      {"<leader><tab>o", Cmd("tabonly"), desc = "Close Other Tabs" },

      -- Toggles
      { "<leader>T", group = "ui/toggles", icon = { icon = "", color = "yellow" } },
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

      -- Project (<leader>pp lives in plugin/projects.lua)
      { "<leader>p", group = "project", icon = { icon = "", color = "green" } },
      { "<leader>ps", function() Snacks.scratch() end, desc = "Scratch Buffer" },
      { "<leader>pS", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },

      -- Plugins
      { "<leader>P", group = "plugins", icon = { icon = "󰏗", color = "azure" } },
      { "<leader>Pc", function() require("config.pack-updates").check(true) end, desc = "Check for Updates" },
      { "<leader>Pu", function() vim.pack.update() end, desc = "Update Plugins" },
      { "<leader>PU", function() vim.pack.update(nil, { force = true }) end, desc = "Update Plugins (force, no confirm)" },
      { "<leader>Ps", function() vim.pack.update(nil, { offline = true }) end, desc = "Show Plugin Status" },
      { "<leader>Pr", function() vim.pack.update(nil, { target = "lockfile" }) end, desc = "Restore to Lockfile" },
      { "<leader>Ph", Cmd("checkhealth vim.pack"), desc = "Health Check" },
      { "<leader>Pd",
        function()
          -- vim.pack.del() requires an explicit list of names; gather the plugins
          -- on disk that no vim.pack.add() references this session (active == false).
          local unused = vim.tbl_map(function(p) return p.spec.name end,
            vim.tbl_filter(function(p) return not p.active end, vim.pack.get()))
          if #unused == 0 then
            vim.notify("No unused plugins to remove", vim.log.levels.INFO)
            return
          end
          local prompt = ("Remove %d unused plugin(s)?\n%s"):format(#unused, table.concat(unused, ", "))
          if vim.fn.confirm(prompt, "&Yes\n&No", 2) == 1 then
            vim.pack.del(unused)
          end
        end,
        desc = "Clean Unused Plugins" },
      { "<leader>PR", Cmd("restart"), desc = "Restart Neovim" },

      -- Quit
      { "<leader>q", group = "quit", icon = { icon = "󰗼", color = "red" } },
      { "<leader>qq", Cmd("qa"), desc = "Quit All" },
      { "<leader>qw", Cmd("wq"), desc = "Write & Quit" },
      { "<leader>qW", Cmd("wqa"), desc = "Write All & Quit All" },
      { "<leader>q!", Cmd("qa!"), desc = "Force Quit All (discard changes)" },

      -- UI
      { "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },

      -- Windows
      { "<leader>w", group = "window", proxy = "<C-w>", icon = { icon = " ", color = "blue" } },
      { "<leader>w-", Cmd("rightbelow sb"), desc = "Split Window Horizontal" },
      { "<leader>w/", Cmd("vertical rightbelow sb"), desc = "Split Window Vertical" },
      { "<leader>wd", "<C-w>c", desc = "Delete Window" },
      { "<leader>wD",
        function()
          -- Count non-floating windows in the current tab; :only closes every
          -- one but the current, so bail with a notice when this is the last.
          local wins = vim.tbl_filter(function(win)
            return vim.api.nvim_win_get_config(win).relative == ""
          end, vim.api.nvim_tabpage_list_wins(0))
          if #wins <= 1 then
            vim.notify("No other windows to close", vim.log.levels.INFO)
            return
          end
          vim.cmd.only()
        end,
        desc = "Delete Other Windows" },
      { "<leader>wt", function() Snacks.scratch() end, desc = "Scratch Buffer" },
      { "<leader>wz", function() Snacks.zen() end, desc = "Zen Mode" },
    },
  })
end)

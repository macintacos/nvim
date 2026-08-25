-- github.com/folke/which-key.nvim
-- Displays available keybindings in a popup as you type
vim.pack.add({ "https://github.com/folke/which-key.nvim" }, { load = false })

vim.schedule(function()
  vim.cmd.packadd("which-key.nvim")

  local Cmd = require("helpers.mappings").Cmd
  local Snacks = require("snacks")
  local Yank = require("helpers.yank")

  -- Call a mini.pick registry picker directly. Going through `:Pick` routes the
  -- options through Vim's command parser, which shell-expands quoted arguments;
  -- under a non-POSIX shell (fish) that expansion fails and prints
  -- "E79: Cannot expand wildcards" before the picker opens.
  ---@param name string Registry picker name.
  ---@param local_opts table? Options for that picker.
  ---@return fun()
  local function pick(name, local_opts)
    return function()
      MiniPick.registry[name](local_opts)
    end
  end

  require("which-key").setup({
    preset = "helix",

    -- stylua: ignore
    spec = {
      -- Top-level Things
      { "<leader>?", function() require("which-key").show({ global = false }) end,
        desc = "Buffer Local Keymaps (which-key)" },
      { "<leader>/", pick("grep_live"), desc = "Grep Project" },
      { "<leader>:", pick("history", { scope = ":" }), desc = "Command History" },
      { "<leader><leader>", pick("commands"), desc = "Search All Commands" },

      -- Buffers
      { "<leader>b", group = "buffers", icon = { icon = "󰈔", color = "cyan" } },
      { "<leader>bn", Cmd("bnext"), desc = "Next Buffer" },
      { "<leader>bp", Cmd("bprevious"), desc = "Prev Buffer" },
      { "<leader>bb", pick("buffers"), desc = "Show Open Buffers" },
      { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
      { "<leader>bD", function() Snacks.bufdelete.other() end, desc = "Delete Other Buffers" },
      { "<leader>by", Cmd("%y"), desc = "Copy Buffer Text" },
      { "<leader>bs", pick("buf_lines", { scope = "current" }), desc = "Search Buffer Lines"},
      { "<leader>bz", function() Snacks.zen() end, desc = "Zen Mode" },

      -- Files
      { "<leader>f", group = "files", icon = { icon = "󰉋", color = "cyan" } },
      { "<leader>ff", pick("files"), desc = "Find Files" },
      { "<leader>fn", Cmd("enew"), desc = "New File" },
      { "<leader>fo", pick("oldfiles"), desc = "Recent Files" },
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

      -- Files > Copy paths (the same actions as <leader>y, kept under their
      -- original prefix)
      { "<leader>fy", group = "copy", icon = { icon = "󰅍", color = "yellow" } },
      { "<leader>fyp", Yank.rel_path, desc = "Relative Path" },
      { "<leader>fyP", Yank.abs_path, desc = "Absolute Path" },
      { "<leader>fyl", Yank.rel_line, desc = "Relative Path:Line" },
      { "<leader>fyL", Yank.abs_line, desc = "Absolute Path:Line" },
      { "<leader>fyn", Yank.filename, desc = "Filename" },
      { "<leader>fyd", Yank.rel_dir, desc = "Relative Dir" },
      { "<leader>fyD", Yank.abs_dir, desc = "Absolute Dir" },
      { "<leader>fyw", Yank.window_paths, desc = "Visible Windows: Relative Paths" },
      { "<leader>fyW", Yank.window_paths_abs, desc = "Visible Windows: Absolute Paths" },

      -- Errors (anything reporting a problem: diagnostics and the fix lists)
      { "<leader>e", group = "errors", icon = { icon = "", color = "red" } },
      { "<leader>ee", pick("diagnostic", { scope = "all" }), desc = "Diagnostics (Workspace)" },
      { "<leader>eb", pick("diagnostic", { scope = "current" }), desc = "Diagnostics (Buffer)" },
      { "<leader>eq", pick("list", { scope = "quickfix" }), desc = "Quickfix List" },
      { "<leader>el", pick("list", { scope = "location" }), desc = "Location List" },

      -- Git
      { "<leader>g", group = "git", icon = { cat = "filetype", name = "git" } },
      { "<leader>gs", function() Snacks.lazygit.open() end, desc = "Open Lazygit" },
      { "<leader>gl", pick("git_commits"), desc = "Git Log" },
      { "<leader>gb", pick("git_blame_line"), desc = "Git Blame Line" },
      { "<leader>gf",
        function()
          -- `:Pick` would expand `%` itself; doing it here keeps the whole
          -- mapping off the command parser (see the `pick` helper above).
          local path = vim.fn.expand("%:p")
          MiniPick.registry.git_commits({ path = path ~= "" and path or nil })
        end,
        desc = "Git Log File" },
      { "<leader>gH", pick("git_hunks", { scope = "unstaged" }), desc = "Git Hunks (unstaged)" },
      { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse (open)" },
      { "<leader>gd", "<Cmd>CodeDiff<CR>", desc = "Diff Changed Files (CodeDiff)" },
      { "<leader>gh", "<Cmd>CodeDiff history<CR>", desc = "File History (CodeDiff)" },

      -- Help
      { "<leader>h", group = "help", icon = { icon = "󰋖", color = "purple" } },
      { "<leader>hh", pick("help"), desc = "Search All Help Docs" },
      { "<leader>hm", pick("manpages"), desc = "Search All Manpages" },
      { "<leader>hM", pick("keymaps"), desc = "Search All Keymaps" },
      { "<leader>hk", Cmd("norm! K"), desc = "Lookup Keyword Under Cursor" },
      { "<leader>hH", pick("hl_groups"), desc = "Search All Highlights" },

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
      { "<leader>ss", pick("buf_lines", { scope = "current" }), desc = "Buffer Lines"},
      { "<leader>sp", pick("grep_live"), desc = "Grep Project"},
      { "<leader>sP",
        function()
          -- grep_live always starts empty, and MiniPickStart fires once the picker
          -- is up — the first moment its query can be seeded with <cword>.
          local word = vim.fn.expand("<cword>")
          if word ~= "" then
            vim.api.nvim_create_autocmd("User", {
              pattern = "MiniPickStart",
              once = true,
              callback = function() MiniPick.set_picker_query({ word }) end,
            })
          end
          MiniPick.registry.grep_live()
        end,
        desc = "Grep Word Under Cursor"},
      { "<leader>sb", pick("buf_lines", { scope = "all" }), desc = "Search Open Buffer Lines"},
      { "<leader>sR", pick("resume"), desc = "Resume Last Picker"},
      { "<leader>sm", pick("marks"), desc = "Marks"},
      { "<leader>sy", pick("registers"), desc = "Registers"},
      { "<leader>s/", pick("history", { scope = "/" }), desc = "Search History"},

      -- Jump to
      { "<leader>j", group = "jump to...", icon = { icon = "󰌑", color = "yellow" } },
      { "<leader>ji", pick("lsp", { scope = "document_symbol" }), desc = "Symbols in File" },
      { "<leader>jI", pick("lsp", { scope = "workspace_symbol_live" }), desc = "Symbols in Workspace" },
      { "<leader>jt", pick("treesitter"), desc = "Treesitter Nodes" },

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

      -- Yank (anything that ends up on the `+` register)
      { "<leader>y", group = "yank", icon = { icon = "󰅍", color = "yellow" } },
      { "<leader>yy", Yank.rel_path, desc = "Relative Path" },
      { "<leader>yY", Yank.abs_path, desc = "Absolute Path" },
      { "<leader>yl", Yank.rel_line, desc = "Relative Path:Line" },
      { "<leader>yL", Yank.abs_line, desc = "Absolute Path:Line" },
      { "<leader>yn", Yank.filename, desc = "Filename" },
      { "<leader>yd", Yank.rel_dir, desc = "Relative Dir" },
      { "<leader>yD", Yank.abs_dir, desc = "Absolute Dir" },
      { "<leader>yw", Yank.window_paths, desc = "Visible Windows: Relative Paths" },
      { "<leader>yW", Yank.window_paths_abs, desc = "Visible Windows: Absolute Paths" },
      { "<leader>ya", Yank.buffer_paths, desc = "All Buffers: Relative Paths" },
      { "<leader>yA", Yank.buffer_paths_abs, desc = "All Buffers: Absolute Paths" },
      { "<leader>yt", Yank.buffer_text, desc = "Buffer Text" },
      { "<leader>yc", Yank.cwd, desc = "Working Directory" },
      { "<leader>yx", Yank.diagnostics, desc = "Diagnostics on Line" },
      { "<leader>ym", Yank.markdown_link, desc = "Markdown Link to Line" },

      -- Yank > git and github
      { "<leader>yg", group = "git", icon = { cat = "filetype", name = "git" } },
      { "<leader>ygh", Yank.commit_hash, desc = "Line's Commit Hash (short)" },
      { "<leader>ygH", Yank.commit_hash_full, desc = "Line's Commit Hash (full)" },
      { "<leader>ygd", Yank.commit_date, desc = "Line's Commit Date" },
      { "<leader>yga", Yank.commit_author, desc = "Line's Commit Author" },
      { "<leader>ygm", Yank.commit_summary, desc = "Line's Commit Subject" },
      { "<leader>ygu", Yank.gh_commit, desc = "Link: Line's Commit" },
      { "<leader>ygb", Yank.gh_blame, desc = "Link: Blame at Line" },
      { "<leader>ygl", Yank.gh_permalink, desc = "Link: Permalink to Line" },
      { "<leader>ygf", Yank.gh_file, desc = "Link: File on Branch" },
      { "<leader>ygr", Yank.gh_repo, desc = "Link: Repo" },
      { "<leader>ygB", Yank.branch, desc = "Branch Name" },
      { "<leader>ygc", Yank.head_sha, desc = "HEAD Commit Hash" },
    },
  })
end)

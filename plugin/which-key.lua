-- github.com/folke/which-key.nvim
-- Displays available keybindings in a popup as you type
vim.pack.add({ "https://github.com/folke/which-key.nvim" }, { load = false })

vim.schedule(function()
  vim.cmd.packadd("which-key.nvim")

  local Cmd = require("helpers.mappings").Cmd
  local Kinds = require("plugins.mini-pickers.kinds")
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

  -- which-key's default sort pins buffer-local mappings first and splits groups
  -- from plain mappings, which buries `<Space>` and scatters keys that belong
  -- side by side (`p` and `P`). Order by what the key *is* instead; view.lua
  -- appends a natural, case-aware sort, so within a class `p` lands beside `P`.
  ---@param item wk.Item
  ---@return integer
  local function key_class(item)
    local key = item.raw_key
    if key == "<Space>" then
      return 0
    elseif key:match("^%d$") then
      return 1
    elseif key:match("^%a$") then
      return 3
    end
    return 2
  end

  require("which-key").setup({
    preset = "helix",
    sort = { "order", key_class },

    -- stylua: ignore
    spec = {
      -- Top-level Things
      { "<leader>?", function() require("which-key").show({ global = false }) end,
        desc = "Buffer Local Keymaps (which-key)", icon = { icon = "󰌌", color = "cyan" } },
      { "<leader>/", pick("grep_live"), desc = "Grep Project", icon = { icon = "󰍉", color = "green" } },
      { "<leader>:", pick("history", { scope = ":" }), desc = "Command History", icon = { icon = "󰞷", color = "azure" } },
      { "<leader><leader>", pick("which_key"), desc = "Search All Keybindings", icon = { icon = "󰌌", color = "green" } },

      -- Z — ZR is mapped in config/keymaps.lua; ZZ and ZQ are Vim built-ins, so
      -- which-key only learns them from a description-only entry (no rhs, so no
      -- mapping is created), the same way its own presets label z, g and [ ].
      { "Z", group = "quit/restart", icon = { icon = "󰗼", color = "red" } },
      { "ZZ", desc = "Write & Quit", icon = { icon = "󰆓", color = "red" } },
      { "ZQ", desc = "Quit Without Writing", icon = { icon = "󰅖", color = "red" } },

      -- Buffers
      { "<leader>b", group = "buffers", icon = { icon = "󰈔", color = "cyan" } },
      { "<leader>bn", Cmd("bnext"), desc = "Next Buffer", icon = { icon = "󰒭", color = "cyan" } },
      { "<leader>bp", Cmd("bprevious"), desc = "Prev Buffer", icon = { icon = "󰒮", color = "cyan" } },
      { "<leader>bb", pick("buffers"), desc = "Show Open Buffers", icon = { icon = "󰪷", color = "cyan" } },
      { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer", icon = { icon = "󰅖", color = "red" } },
      { "<leader>bD", function() Snacks.bufdelete.other() end, desc = "Delete Other Buffers", icon = { icon = "󰱝", color = "red" } },
      { "<leader>by", Cmd("%y"), desc = "Copy Buffer Text", icon = { icon = "󰅍", color = "yellow" } },
      { "<leader>bs", pick("buf_lines", { scope = "current" }), desc = "Search Buffer Lines", icon = { icon = "󱎸", color = "green" } },
      { "<leader>bz", function() Snacks.zen() end, desc = "Zen Mode", icon = { icon = "󱅻", color = "purple" } },

      -- Files
      { "<leader>f", group = "files", icon = { icon = "󰉋", color = "cyan" } },
      { "<leader>ff", pick("files"), desc = "Find Files", icon = { icon = "󰈞", color = "green" } },
      { "<leader>fn", Cmd("enew"), desc = "New File", icon = { icon = "󰝒", color = "green" } },
      { "<leader>fo", pick("oldfiles"), desc = "Recent Files", icon = { icon = "󱋡", color = "azure" } },
      { "<leader>ft", function() require("plugins.scratch").open() end, desc = "Scratch Buffer", icon = { icon = "󱞁", color = "yellow" } },
      { "<leader>fe", function() MiniFiles.open() end, desc = "Show mini.files", icon = { icon = "󰙅", color = "cyan" } },
      { "<leader>fE", function() Snacks.explorer() end, desc = "Show Snacks Explorer", icon = { icon = "󰝰", color = "cyan" } },
      { "<leader>fu",
        function()
          MiniFiles.open(vim.api.nvim_buf_get_name(0), true)
        end,
        desc = "Unveil in Explorer", icon = { icon = "󰥨", color = "cyan" } },
      { "<leader>fR", function() Snacks.rename.rename_file() end, desc = "Rename File", icon = { icon = "󰑕", color = "orange" } },
      { "<leader>f=", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, desc = "Format File", icon = { icon = "󰁨", color = "cyan" } },
      { "<leader>fl", function() require("plugins.ftchooser").open() end, desc = "Set Filetype", icon = { icon = "󱁻", color = "orange" } },
      { "<leader>fs", Cmd("w"), desc = "Save File", icon = { icon = "󰆓", color = "green" } },
      { "<leader>fS", Cmd("noautocmd w"), desc = "Save File (no format)", icon = { icon = "󰠘", color = "green" } },

      -- Files > Copy paths (the same actions as <leader>y, kept under their
      -- original prefix)
      { "<leader>fy", group = "copy", icon = { icon = "󰅍", color = "yellow" } },
      { "<leader>fyp", Yank.rel_path, desc = "Relative Path", icon = { icon = "󰈤", color = "yellow" } },
      { "<leader>fyP", Yank.abs_path, desc = "Absolute Path", icon = { icon = "󰿟", color = "yellow" } },
      { "<leader>fyl", Yank.rel_line, desc = "Relative Path:Line", icon = { icon = "󰉻", color = "yellow" } },
      { "<leader>fyL", Yank.abs_line, desc = "Absolute Path:Line", icon = { icon = "󰉻", color = "yellow" } },
      { "<leader>fyn", Yank.filename, desc = "Filename", icon = { icon = "󰓹", color = "yellow" } },
      { "<leader>fyd", Yank.rel_dir, desc = "Relative Dir", icon = { icon = "󰉋", color = "yellow" } },
      { "<leader>fyD", Yank.abs_dir, desc = "Absolute Dir", icon = { icon = "󰉋", color = "yellow" } },
      { "<leader>fyw", Yank.window_paths, desc = "Visible Windows: Relative Paths", icon = { icon = "󰖲", color = "yellow" } },
      { "<leader>fyW", Yank.window_paths_abs, desc = "Visible Windows: Absolute Paths", icon = { icon = "󰖲", color = "yellow" } },

      -- Errors (anything reporting a problem: diagnostics and the fix lists)
      { "<leader>e", group = "errors", icon = { icon = "󰀩", color = "red" } },
      { "<leader>ee", pick("diagnostic", { scope = "all" }), desc = "Diagnostics (Workspace)", icon = { icon = "󰓙", color = "red" } },
      { "<leader>eb", pick("diagnostic", { scope = "current" }), desc = "Diagnostics (Buffer)", icon = { icon = "󰀨", color = "red" } },
      { "<leader>eq", pick("list", { scope = "quickfix" }), desc = "Quickfix List", icon = { icon = "󰉹", color = "orange" } },
      { "<leader>el", pick("list", { scope = "location" }), desc = "Location List", icon = { icon = "󰍎", color = "orange" } },

      -- Git
      { "<leader>g", group = "git", icon = { cat = "filetype", name = "git" } },
      { "<leader>gs", function() Snacks.lazygit.open() end, desc = "Open Lazygit", icon = { icon = "󰊢", color = "orange" } },
      { "<leader>gl", pick("git_commits"), desc = "Git Log", icon = { icon = "󰜘", color = "orange" } },
      { "<leader>gb", pick("git_blame_line"), desc = "Git Blame Line", icon = { icon = "󰭖", color = "orange" } },
      { "<leader>gf",
        function()
          -- `:Pick` would expand `%` itself; doing it here keeps the whole
          -- mapping off the command parser (see the `pick` helper above).
          local path = vim.fn.expand("%:p")
          MiniPick.registry.git_commits({ path = path ~= "" and path or nil })
        end,
        desc = "Git Log File", icon = { icon = "󱋡", color = "orange" } },
      { "<leader>gH", pick("git_hunks", { scope = "unstaged" }), desc = "Git Hunks (unstaged)", icon = { icon = "󰕚", color = "orange" } },
      { "<leader>gP", Cmd("PRReview"), desc = "PR Review Mode (gutter vs default branch)", icon = { icon = "󰓂", color = "orange" } },
      { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse (open)", icon = { icon = "󰖟", color = "blue" } },
      { "<leader>gd", "<Cmd>CodeDiff<CR>", desc = "Diff Changed Files (CodeDiff)", icon = { icon = "󰢪", color = "orange" } },
      { "<leader>gh", "<Cmd>CodeDiff history<CR>", desc = "File History (CodeDiff)", icon = { icon = "󰋚", color = "orange" } },

      -- Help
      { "<leader>h", group = "help", icon = { icon = "󰋖", color = "purple" } },
      { "<leader>hh", pick("help"), desc = "Search All Help Docs", icon = { icon = "󰋗", color = "purple" } },
      { "<leader>hc", pick("commands"), desc = "Search All Commands", icon = { icon = "󰞷", color = "purple" } },
      { "<leader>hm", pick("manpages"), desc = "Search All Manpages", icon = { icon = "󰗚", color = "purple" } },
      { "<leader>hM", pick("keymaps"), desc = "Search All Keymaps", icon = { icon = "󰌌", color = "purple" } },
      { "<leader>hk", Cmd("norm! K"), desc = "Lookup Keyword Under Cursor", icon = { icon = "󰺄", color = "purple" } },
      { "<leader>hH", pick("hl_groups"), desc = "Search All Highlights", icon = { icon = "󰏘", color = "purple" } },

      -- Open various UIs
      { "<leader>o", group = "open...", icon = { icon = "󰏌", color = "green" } },
      { "<leader>ol",
        function()
          local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
          if not success and err then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end,
        desc = "Location List", icon = { icon = "󰍎", color = "green" } },
      { "<leader>oq",
        function()
          local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
          if not success and err then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end, desc = "Quickfix List", icon = { icon = "󰉹", color = "green" } },
      { "<leader>on", Cmd("messages"), desc = "Show Messages", icon = { icon = "󰍩", color = "green" } },

      -- Search
      { "<leader>s", group = "search", icon = { icon = "󰍉", color = "green" } },
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
        desc = "Search and Replace", icon = { icon = "󰛔", color = "blue" } },
      { "<leader>ss", pick("buf_lines", { scope = "current" }), desc = "Buffer Lines", icon = { icon = "󱎸", color = "green" } },
      { "<leader>sp", pick("grep_live"), desc = "Grep Project", icon = { icon = "󰍉", color = "green" } },
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
        desc = "Grep Word Under Cursor", icon = { icon = "󰺮", color = "green" } },
      { "<leader>sb", pick("buf_lines", { scope = "all" }), desc = "Search Open Buffer Lines", icon = { icon = "󰪷", color = "green" } },
      { "<leader>sR", pick("resume"), desc = "Resume Last Picker", icon = { icon = "󰦛", color = "green" } },
      { "<leader>sm", pick("marks"), desc = "Marks", icon = { icon = "󰃀", color = "green" } },
      { "<leader>sy", pick("registers"), desc = "Registers", icon = { icon = "󱃔", color = "green" } },
      { "<leader>s/", pick("history", { scope = "/" }), desc = "Search History", icon = { icon = "󰋚", color = "green" } },

      -- Jump to
      { "<leader>j", group = "jump to...", icon = { icon = "󰌑", color = "yellow" } },
      { "<leader>ji", pick("lsp", { scope = "document_symbol" }), desc = "Symbols in File", icon = { icon = "󰠱", color = "yellow" } },
      { "<leader>jI", pick("lsp", { scope = "workspace_symbol_live" }), desc = "Symbols in Workspace", icon = { icon = "󰠲", color = "yellow" } },
      { "<leader>jm", pick("lsp", { scope = "document_symbol", kinds = Kinds.FUNCTIONS, name = "LSP (functions)" }), desc = "Functions in File", icon = { icon = "󰊕", color = "yellow" } },
      { "<leader>jM", pick("lsp", { scope = "workspace_symbol", kinds = Kinds.FUNCTIONS, name = "LSP (workspace functions)" }), desc = "Functions in Workspace", icon = { icon = "󰊕", color = "yellow" } },
      { "<leader>jv", pick("lsp", { scope = "document_symbol", kinds = Kinds.VARIABLES, name = "LSP (variables)" }), desc = "Variables in File", icon = { icon = "󰫧", color = "yellow" } },
      { "<leader>jV", pick("lsp", { scope = "workspace_symbol", kinds = Kinds.VARIABLES, name = "LSP (workspace variables)" }), desc = "Variables in Workspace", icon = { icon = "󰫧", color = "yellow" } },
      { "<leader>jt", pick("treesitter"), desc = "Treesitter Nodes", icon = { icon = "󰒪", color = "yellow" } },

      -- Tabs
      { "<leader><tab>", group = "tabs", icon = { icon = "󰓩", color = "purple" } },
      {"<leader><tab><tab>", Cmd("tabnew"), desc = "New Tab", icon = { icon = "󰝜", color = "purple" } },
      {"<leader><tab>[", Cmd("tabprevious"), desc = "Previous Tab", icon = { icon = "󰅁", color = "purple" } },
      {"<leader><tab>]", Cmd("tabnext"), desc = "Next Tab", icon = { icon = "󰅂", color = "purple" } },
      {"<leader><tab>d", Cmd("tabclose"), desc = "Close Tab", icon = { icon = "󰭌", color = "red" } },
      {"<leader><tab>f", Cmd("tabfirst"), desc = "First Tab", icon = { icon = "󰘀", color = "purple" } },
      {"<leader><tab>l", Cmd("tablast"), desc = "Last Tab", icon = { icon = "󰘁", color = "purple" } },
      {"<leader><tab>n", Cmd("tabnew"), desc = "New Tab", icon = { icon = "󰝜", color = "purple" } },
      {"<leader><tab>o", Cmd("tabonly"), desc = "Close Other Tabs", icon = { icon = "󰱝", color = "red" } },

      -- Toggles
      { "<leader>T", group = "ui/toggles", icon = { icon = "󰔡", color = "yellow" } },
      { "<leader>TL", function() Snacks.toggle.option("relativenumber", { name = "Relative Number" }):toggle() end, desc = "Relative Number", icon = { icon = "󰎠", color = "yellow" } },
      { "<leader>TT", function() Snacks.toggle.treesitter():toggle() end, desc = "Treesitter", icon = { icon = "󰒪", color = "yellow" } },
      { "<leader>Tb", function() Snacks.toggle.option("background", {off = "light", on = "dark", name = "Dark Background"}):toggle() end, desc = "Dark Background", icon = { icon = "󰔎", color = "yellow" } },
      { "<leader>Tc", function() Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" }):toggle() end, desc = "Conceal Level", icon = { icon = "󰈉", color = "yellow" } },
      { "<leader>Th", function() Snacks.toggle.inlay_hints():toggle() end, desc = "Inlay Hints", icon = { icon = "󰔣", color = "yellow" } },
      { "<leader>Tl", function() Snacks.toggle.line_number():toggle() end, desc = "Line Number", icon = { icon = "󰉻", color = "yellow" } },
      { "<leader>Td", function() Snacks.toggle.dim():toggle() end, desc = "Dim", icon = { icon = "󰃟", color = "yellow" } },
      { "<leader>Ta", function() Snacks.toggle.animate():toggle() end, desc = "Animations", icon = { icon = "󰗘", color = "yellow" } },
      { "<leader>Ts", function() Snacks.toggle.option("spell", { name = "Spelling" }):toggle() end, desc = "Spelling", icon = { icon = "󰓆", color = "yellow" } },
      { "<leader>Tt", function() Snacks.toggle.option("showtabline", { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline" }):toggle() end, desc = "Tabline", icon = { icon = "󰓩", color = "yellow" } },
      { "<leader>Tw", function() Snacks.toggle.option("wrap", { name = "Wrap" }):toggle() end, desc = "Word Wrap", icon = { icon = "󰖶", color = "yellow" } },
      { "<leader>Ti", function() Snacks.toggle.indent():toggle() end, desc = "Indentation", icon = { icon = "󰉶", color = "yellow" } },
      { "<leader>Tp", Cmd("PRReview"), desc = "PR Review Mode", icon = { icon = "󰓂", color = "yellow" } },
      { "<leader>Tz", function() Snacks.zen() end, desc = "Zen Mode", icon = { icon = "󱅻", color = "yellow" } },

      -- Project (<leader>pp is mapped in plugin/projects.lua; the entry below is
      -- description-only — no rhs, so no mapping is created — and exists to give
      -- it an icon alongside the rest of the group.)
      { "<leader>p", group = "project", icon = { icon = "󰉓", color = "green" } },
      { "<leader>pp", desc = "Projects", icon = { icon = "󰃖", color = "green" } },
      { "<leader>ps", function() require("plugins.scratch").open() end, desc = "Scratch Buffer", icon = { icon = "󱞁", color = "green" } },
      { "<leader>pS", function() require("plugins.scratch").float() end, desc = "Scratch Buffer (Float)", icon = { icon = "󰚸", color = "green" } },

      -- Plugins
      { "<leader>P", group = "plugins", icon = { icon = "󰏗", color = "azure" } },
      { "<leader>Pc", function() require("config.pack-updates").check(true) end, desc = "Check for Updates", icon = { icon = "󰍉", color = "azure" } },
      { "<leader>Pu", function() vim.pack.update() end, desc = "Update Plugins", icon = { icon = "󰚰", color = "azure" } },
      { "<leader>PU", function() vim.pack.update(nil, { force = true }) end, desc = "Update Plugins (force, no confirm)", icon = { icon = "󰇚", color = "azure" } },
      { "<leader>Ps", function() vim.pack.update(nil, { offline = true }) end, desc = "Show Plugin Status", icon = { icon = "󰋼", color = "azure" } },
      { "<leader>Pr", function() vim.pack.update(nil, { target = "lockfile" }) end, desc = "Restore to Lockfile", icon = { icon = "󰁯", color = "azure" } },
      { "<leader>Ph", Cmd("checkhealth vim.pack"), desc = "Health Check", icon = { icon = "󰗶", color = "azure" } },
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
        desc = "Clean Unused Plugins", icon = { icon = "󰃢", color = "azure" } },
      { "<leader>PR", Cmd("restart"), desc = "Restart Neovim", icon = { icon = "󰜉", color = "red" } },

      -- Quit
      { "<leader>q", group = "quit", icon = { icon = "󰗼", color = "red" } },
      { "<leader>qq", Cmd("qa"), desc = "Quit All", icon = { icon = "󰗼", color = "red" } },
      { "<leader>qw", Cmd("wq"), desc = "Write & Quit", icon = { icon = "󰆓", color = "red" } },
      { "<leader>qW", Cmd("wqa"), desc = "Write All & Quit All", icon = { icon = "󰆔", color = "red" } },
      { "<leader>q!", Cmd("qa!"), desc = "Force Quit All (discard changes)", icon = { icon = "󰅜", color = "red" } },

      -- UI (<leader>ux is registered by Snacks.toggle in plugin/illuminate.lua,
      -- which supplies its own icon reflecting the enabled/disabled state)
      { "<leader>u", group = "ui", icon = { icon = "󰙵 ", color = "cyan" } },

      -- Windows
      { "<leader>w", group = "window", proxy = "<C-w>", icon = { icon = "󰕰", color = "blue" } },
      { "<leader>w-", Cmd("rightbelow sb"), desc = "Split Window Horizontal", icon = { icon = "󰤼", color = "blue" } },
      { "<leader>w/", Cmd("vertical rightbelow sb"), desc = "Split Window Vertical", icon = { icon = "󰤻", color = "blue" } },
      { "<leader>wd", "<C-w>c", desc = "Delete Window", icon = { icon = "󰖭", color = "red" } },
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
        desc = "Delete Other Windows", icon = { icon = "󰖯", color = "red" } },
      { "<leader>wt", function() require("plugins.scratch").open() end, desc = "Scratch Buffer", icon = { icon = "󱞁", color = "blue" } },
      { "<leader>wT", function() require("plugins.scratch").float() end, desc = "Scratch Buffer (Float)", icon = { icon = "󱂬", color = "blue" } },
      { "<leader>wz", function() Snacks.zen() end, desc = "Zen Mode", icon = { icon = "󱅻", color = "blue" } },

      -- Actions (things that change the code under the cursor)
      { "<leader>x", group = "actions", icon = { icon = "󰌵", color = "yellow" } },
      { "<leader>xr", vim.lsp.buf.rename, desc = "Rename Symbol (LSP)", icon = { icon = "󰑕", color = "yellow" } },

      -- Yank (anything that ends up on the `+` register)
      { "<leader>y", group = "yank", icon = { icon = "󰅍", color = "yellow" } },
      { "<leader>yy", Yank.rel_path, desc = "Relative Path", icon = { icon = "󰈤", color = "yellow" } },
      { "<leader>yY", Yank.abs_path, desc = "Absolute Path", icon = { icon = "󰿟", color = "yellow" } },
      { "<leader>yl", Yank.rel_line, desc = "Relative Path:Line", icon = { icon = "󰉻", color = "yellow" } },
      { "<leader>yL", Yank.abs_line, desc = "Absolute Path:Line", icon = { icon = "󰉻", color = "yellow" } },
      { "<leader>yn", Yank.filename, desc = "Filename", icon = { icon = "󰓹", color = "yellow" } },
      { "<leader>yd", Yank.rel_dir, desc = "Relative Dir", icon = { icon = "󰉋", color = "yellow" } },
      { "<leader>yD", Yank.abs_dir, desc = "Absolute Dir", icon = { icon = "󰉋", color = "yellow" } },
      { "<leader>yw", Yank.window_paths, desc = "Visible Windows: Relative Paths", icon = { icon = "󰖲", color = "yellow" } },
      { "<leader>yW", Yank.window_paths_abs, desc = "Visible Windows: Absolute Paths", icon = { icon = "󰖲", color = "yellow" } },
      { "<leader>ya", Yank.buffer_paths, desc = "All Buffers: Relative Paths", icon = { icon = "󰪷", color = "yellow" } },
      { "<leader>yA", Yank.buffer_paths_abs, desc = "All Buffers: Absolute Paths", icon = { icon = "󰪷", color = "yellow" } },
      { "<leader>yt", Yank.buffer_text, desc = "Buffer Text", icon = { icon = "󰈚", color = "yellow" } },
      { "<leader>yc", Yank.cwd, desc = "Working Directory", icon = { icon = "󱂵", color = "yellow" } },
      { "<leader>yx", Yank.diagnostics, desc = "Diagnostics on Line", icon = { icon = "󰀨", color = "red" } },
      { "<leader>ym", Yank.markdown_link, desc = "Markdown Link to Line", icon = { icon = "󰍔", color = "yellow" } },

      -- Yank > git and github
      { "<leader>yg", group = "git", icon = { cat = "filetype", name = "git" } },
      { "<leader>ygh", Yank.commit_hash, desc = "Line's Commit Hash (short)", icon = { icon = "󰐣", color = "orange" } },
      { "<leader>ygH", Yank.commit_hash_full, desc = "Line's Commit Hash (full)", icon = { icon = "󰐣", color = "orange" } },
      { "<leader>ygd", Yank.commit_date, desc = "Line's Commit Date", icon = { icon = "󰃭", color = "orange" } },
      { "<leader>yga", Yank.commit_author, desc = "Line's Commit Author", icon = { icon = "󰀄", color = "orange" } },
      { "<leader>ygm", Yank.commit_summary, desc = "Line's Commit Subject", icon = { icon = "󰍩", color = "orange" } },
      { "<leader>ygu", Yank.gh_commit, desc = "Link: Line's Commit", icon = { icon = "󰊤", color = "blue" } },
      { "<leader>ygb", Yank.gh_blame, desc = "Link: Blame at Line", icon = { icon = "󰭖", color = "blue" } },
      { "<leader>ygl", Yank.gh_permalink, desc = "Link: Permalink to Line", icon = { icon = "󰌹", color = "blue" } },
      { "<leader>ygf", Yank.gh_file, desc = "Link: File on Branch", icon = { icon = "󱅷", color = "blue" } },
      { "<leader>ygr", Yank.gh_repo, desc = "Link: Repo", icon = { icon = "󰳏", color = "blue" } },
      { "<leader>ygB", Yank.branch, desc = "Branch Name", icon = { icon = "󰘬", color = "orange" } },
      { "<leader>ygc", Yank.head_sha, desc = "HEAD Commit Hash", icon = { icon = "󰜘", color = "orange" } },
    },
  })
end)

--[[
The best keymapping system in the land.

'which-key' keymaps are defined in a variety of places, not in this file. Those places are:

- `lua/config/keymaps.lua`
- Respective plugin definitions (in `lua/plugins`)
--]]

return {
  "folke/which-key.nvim",
  config = function(_, opts)
    local wk = require("which-key")
    local Cmd = require("config.helpers").Cmd
    local del = vim.keymap.del

    -- [[ OPTIONS ]]
    -- Override defaults
    opts = {
      defaults = opts.defaults,
      plugins = {
        marks = true, -- shows a list of your marks on ' and `
        registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
        -- the presets plugin, adds help for a bunch of default keybindings in Neovim
        -- No actual key bindings are created
        spelling = {
          enabled = true, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
          suggestions = 20, -- how many suggestions should be shown in the list?
        },
        presets = {
          operators = true, -- adds help for operators like d, y, ... and registers them for motion / text object completion
          motions = true, -- adds help for motions
          text_objects = true, -- help for text objects triggered after entering an operator
          windows = true, -- default bindings on <c-w>
          nav = true, -- misc bindings to work with windows
          z = true, -- bindings for folds, spelling and others prefixed with z
          g = true, -- bindings for prefixed with g
        },
      },
      -- add operators that will trigger motion and text object completion
      -- to enable all native operators, set the preset / operators plugin above
      operators = { gc = "Comments" },
      key_labels = {
        -- override the label used to display some keys. It doesn't effect WK in any other way.
        -- For example:
        ["<space>"] = "SPC",
        ["<cr>"] = "RET",
        ["<tab>"] = "TAB",
      },
      icons = {
        breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
        separator = "➜", -- symbol used between a key and it's label
        group = "+", -- symbol prepended to a group
      },
      window = {
        border = "double", -- none, single, double, shadow
        position = "bottom", -- bottom, top
        margin = { 1, 3, 2, 3 }, -- extra window margin [top, right, bottom, left]
        padding = { 2, 2, 2, 2 }, -- extra window padding [top, right, bottom, left]
      },
      layout = {
        height = { min = 4, max = 25 }, -- min and max height of the columns
        width = { min = 20, max = 50 }, -- min and max width of the columns
        spacing = 3, -- spacing between columns
        align = "center", -- align columns left, center or right
      },
      ignore_missing = false, -- enable this to hide mappings for which you didn't specify a label
      hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " }, -- hide mapping boilerplate
      show_help = false, -- show help message on the command line when the popup is visible
      show_keys = false, -- don't show keys as they are typed (better interaction with noice.nvim)
      triggers = "auto", -- automatically setup triggers
      triggers_blacklist = {
        -- list of mode / prefixes that should never be hooked by WhichKey
        -- this is mostly relevant for key maps that start with a native binding
        -- most people should not need to change this
        i = { "j", "k" },
        v = { "j", "k" },
      },
    }
    wk.setup(opts)

    -- [[ MAPPINGS ]]
    -- wk.register(opts.defaults) -- TODO: maybe doesn't need to be here? Seems to get set anyway

    -- Delete top-level menu items here that you want to get overridden
    del("n", "<leader>h")
    del("n", "<leader>e")
    del("n", "<leader>E")

    wk.register({
      -- Buffers
      b = {
        name = "buffer",
        ["<"] = { Cmd("edit #"), "Go to Last Buffer" },
        b = { Cmd("FzfLua buffers"), "List Buffers" },
        c = { Cmd("FzfLua git_bcommits"), "List Commits for Buffer" },
        m = { Cmd("messages"), "Show 'messages' Buffer" },
        n = { "<Plug>(cokeline-focus-next)", "Next Buffer" },
        p = { "<Plug>(cokeline-focus-next)", "Prev Buffer" },
        P = { "<Plug>(cokeline-pick-focus)", "Pick Buffer in Line" },
        N = { Cmd("enew"), "New Empty Buffer" },
        y = { Cmd("%y"), "Copy Buffer" },
        z = { Cmd("ZenMode"), "Zen Mode" },
      },

      -- Files
      f = {
        name = "file",
        ["="] = {
          function()
            require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
          end,
          "Format Range/File",
        },
        s = { Cmd("w"), "Save Current File" },
        f = { Cmd("FzfLua files"), "Find File" },
        S = { Cmd("wa"), "Save All Open Files" },
        n = {
          Cmd("FzfLua file_browser initial_mode=normal"),
          "Open File Browser",
        },
        u = {
          Cmd("Neotree reveal"),
          "Unveil in Neotree",
        },
      },

      -- Help
      h = {
        name = "help",
        c = { Cmd("Legendary"), "Search Legendary" },
        h = { Cmd("FzfLua help_tags"), "Search All Help Docs" },
        m = { Cmd("FzfLua keymaps"), "Search All Keymaps" },
        M = { Cmd("FzfLua man_pages"), "Search All Manpages" },
        H = { Cmd("FzfLua highlights"), "Search All Highlights" },
      },

      -- Windows
      w = {
        name = "window",
        ["="] = { "<C-w>=", "Reset Window Layout" },
        ["-"] = { Cmd("rightbelow sb"), "Split Window Horizontal" },
        ["/"] = { Cmd("vertical rightbelow sb"), "Split Window Vertical" },
        d = { Cmd("q"), "Close Current Window" },
        D = { Cmd("only"), "Close All Other Windows" },
        h = { "<C-w>h", "Focus Window to Left" },
        l = { "<C-w>l", "Focus Window to Right" },
        j = { "<C-w>j", "Focus Window Below" },
        k = { "<C-w>k", "Focus Window Above" },
        H = { Cmd("wincmd H"), "Move Window to Right" },
        L = { Cmd("wincmd L"), "Move Window to Left" },
        J = { Cmd("wincmd J"), "Move Window to Bottom" },
        K = { Cmd("wincmd K"), "Move Window to Top" },
        m = { Cmd("ZenMode"), "Zen Mode" },
        s = { Cmd("rightbelow sb"), "Split Window Horizontal" },
        t = { Cmd("enew"), "New Empty Buffer" },
        T = {
          name = "tabs",
          d = { Cmd("tabclose"), "Close Current Tab" },
        },
        f = {
          v = { Cmd("vertical rightbelow sb"), "Split Window Vertical" },
          name = "file new window",
          l = {
            "New File Split Right",
            Cmd("vertical rightbelow sb<CR><Cmd>Telescope files"),
          },
          h = { Cmd("vertical sb<CR><Cmd>Telescope files"), "New File Split Left" },
          j = {
            Cmd("rightbelow sb<CR><Cmd>Telescope files"),
            "New File Split Below",
          },
          k = { Cmd("split<CR><Cmd>Telescope files"), "New File Split Above" },
        },
        N = {
          name = "new empty buffer",
          c = { Cmd("enew"), "New In Current Window" },
          h = { Cmd("vnew"), "New In Split Left" },
          l = { Cmd("vertical rightbelow new"), "New In Split Right" },
          j = { Cmd("rightbelow new"), "New In Split Below" },
          k = { Cmd("new"), "New In Split Above" },
        },
      },
    }, { prefix = "<leader>" })
  end,
}

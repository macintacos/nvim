local wk = require("which-key")
local Cmd = require("config.helpers").Cmd

wk.register({
  -- Buffers
  b = {
    name = "buffer",
    ["<"] = { Cmd("edit #"), "Go to Last Buffer" },
    b = { Cmd("Telescope buffers"), "List Buffers" },
    c = { Cmd("Telescope git_bcommits"), "List Commits for Buffer" },
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
    f = { Cmd("Telescope files"), "Find File" },
    S = { Cmd("wa"), "Save All Open Files" },
    n = {
      Cmd("Telescope file_browser initial_mode=normal"),
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
    h = { Cmd("Telescope help_tags"), "Search All Help Docs" },
    m = { Cmd("Telescope keymaps"), "Search All Keymaps" },
    M = { Cmd("Telescope man_pages"), "Search All Manpages" },
    H = { Cmd("Telescope highlights"), "Search All Highlights" },
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

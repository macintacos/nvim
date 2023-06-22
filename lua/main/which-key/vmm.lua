-- vim-visual-multi mapping configuration
local wk = require("which-key")

wk.register({
    a = { "<Plug>(VM-Visual-Add)", "Visual Add" },
    c = { "<Plug>(VM-Visual-Find)", "Visual Find" },
    f = { "<Plug>(VM-Visual-Cursors)", "Visual Cursors" },
    ["<TAB>"] = { "<Plug>(VM-Switch-Mode)", "Switch Mode" },
}, { prefix = "\\\\", mode = "v" })

wk.register({
    ["<TAB>"] = { "<Plug>(VM-Switch-Mode)", "Switch Mode" },
    j = { "<Plug>(VM-Add-Cursor-Down)", "Add Cursor Down" },
    k = { "<Plug>(VM-Add-Cursor-Up)", "Add Cursor Up" },
}, { prefix = "\\\\", mode = "n" })

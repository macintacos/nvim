local wk = require("which-key")
local cmd = require("main.helpers").cmd

-- <leader> keybinds for specific
vim.cmd('autocmd FileType neo-tree lua WhichKeyNeoTree()')

function WhichKeyNeoTree()
    wk.register({
        f = {
            name = "file",
            t = { cmd("Neotree close"), "Close Neotree" }
        }
    }, { prefix = "<leader>", buffer = 0 })
end


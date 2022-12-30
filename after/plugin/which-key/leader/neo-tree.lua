local wk = require("which-key")

-- <leader> keybinds for specific
vim.cmd('autocmd FileType neo-tree lua WhichKeyNeoTree()')

function WhichKeyNeoTree()
    wk.register({
        f = {
            name = "file",
            t = { "<Cmd>Neotree close<CR>", "Close Neotree" }
        }
    }, { prefix = "<leader>", buffer = 0 })
end


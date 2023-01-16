local wk = require("which-key")

wk.register({
    ["]d"] = { "<Cmd>lua vim.diagnostic.goto_next<CR>", "Next Diagnostic" },
    ["[d"] = { "<Cmd>lua vim.diagnostic.goto_prev<CR>", "Prev Diagnostic" },
    ["]t"] = { "<Cmd>require('todo-comments').jump_next()<CR>", "Next TODO" },
    ["[t"] = { "<Cmd>require('todo-comments').jump_prev()<CR>", "Prev TODO" },
    ["]p"] = { "]p", "<Plug>(YankyPutIndentAfterFilter)" },
    ["[p]"] = { "[p", "<Plug>(YankyPutIndentBeforeFilter)" },
})

local wk = require("which-key")
local cmd = require("main.helpers").cmd

wk.register({
    ["]d"] = { cmd("lua vim.diagnostic.goto_next"), "Next Diagnostic" },
    ["[d"] = { cmd("lua vim.diagnostic.goto_prev"), "Prev Diagnostic" },
    ["]t"] = { cmd("require('todo-comments').jump_next()"), "Next TODO" },
    ["[t"] = { cmd("require('todo-comments').jump_prev()"), "Prev TODO" },
    ["]p"] = { "]p", "<Plug>(YankyPutIndentAfterFilter)" },
    ["[p]"] = { "[p", "<Plug>(YankyPutIndentBeforeFilter)" },
})

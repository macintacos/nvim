local wk = require("which-key")

wk.register({
    f = {
        name = "file",
        ["="] = { "<Cmd>LspZeroFormat<CR>", "Format Range/File" },
    }
}, { prefix = "<leader>", mode = "v" })

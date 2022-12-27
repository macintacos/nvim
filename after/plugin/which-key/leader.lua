local wk = require("which-key")

wk.register({
    -- Buffer switching
    ["1"] = { "<Cmd>BufferLineGoToBuffer 1<CR>", "which_key_ignore" },
}, { prefix = "<leader>" })

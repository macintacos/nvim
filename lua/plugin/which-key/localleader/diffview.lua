local wk = require("which-key")

_G.which_key_diffview = function()
    local buf = vim.api.nvim_get_current_buf()
    local map = vim.api.nvim_set_keymap

    -- Normal Mappings
    map("n", "q", "<Cmd>DiffviewClose<CR>", { noremap = true, silent = true })

    wk.register({}, { prefix = "<localleader>", buffer = buf, noremap = false })

    -- Visual Mappings
    wk.register({}, { prefix = "<localleader>", buffer = buf, mode = "v", noremap = false })
end

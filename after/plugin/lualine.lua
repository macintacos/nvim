require("lualine").setup({
    options = {
        globalstatus = true
    },
    sections = {
        lualine_x = {
            {
                require("lazy.status").updates,
                cond = require("lazy.status").has_updates,
                color = { fg = "#ff9e64" },
            },
        },
    },
})

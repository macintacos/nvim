require("paint").setup({
    highlights = {
        {
            filter = { filetype = "lua" },
            pattern = "%s*%-%-%-%s*(@%w+)",
            hl = "Constant",
        },
        {
            filter = { filetype = "lua" },
            pattern = "%s*%-%-%[%[(@%w+)",
            hl = "Constant",
        },
        {
            filter = { filetype = "lua" },
            pattern = "%s*%-%-%-%s*@field%s+(%S+)",
            hl = "@field",
        },
        {
            filter = { filetype = "lua" },
            pattern = "%s*%-%-%-%s*@class%s+(%S+)",
            hl = "@variable.builtin",
        },
        {
            filter = { filetype = "lua" },
            pattern = "%s*%-%-%-%s*@alias%s+(%S+)",
            hl = "@keyword",
        },
        {
            filter = { filetype = "lua" },
            pattern = "%s*%-%-%-%s*@param%s+(%S+)",
            hl = "@parameter",
        },
    },
})

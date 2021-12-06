require("nvim-gps").setup({
    -- depth = 2,
    separator = "  ",
    icons = {
        ["class-name"] = " ", -- Classes and class-like objects
        ["function-name"] = " ", -- Functions
        ["method-name"] = " ", -- Methods (functions inside class-like objects)
        ["container-name"] = "ﬓ ", -- Containers (example: lua tables)
        ["tag-name"] = " ", -- Tags (example: html tags)
    },
})

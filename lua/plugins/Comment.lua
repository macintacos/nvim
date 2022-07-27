local ext_config = {
    "numToStr/Comment.nvim",
    config = function()
        require("Comment").setup({
            ignore = "^$", -- ignore empty lines
        })
    end,
}

print("Loaded ext_config from Comment.lua!")

return ext_config

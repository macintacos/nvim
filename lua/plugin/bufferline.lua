require("bufferline").setup({
    options = {
        numbers = "ordinal",
        close_command = "BDelete this",
        offsets = {
            {
                filetype = "NvimTree",
                text = function()
                    local cwd = vim.fn.getcwd()
                    local name = vim.api.nvim_call_function("fnamemodify", { cwd, ":t" })
                    return " " .. name
                end,
                highlight = "Directory",
                text_align = "left",
            },
        },
    },
})

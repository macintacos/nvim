vim.o.showtabline = 2

require("bufferline").setup({
    options = {
        numbers = "ordinal",
        offsets = {
            {
                filetype = "neo-tree",
                text = function()
                    local cwd = vim.fn.getcwd()
                    local name = vim.api.nvim_call_function("fnamemodify", { cwd, ":t" })
                    return " " .. name
                end,
                highlight = "Directory",
                text_align = "left",
            },
        },
        event_handlers = {
            {
                event = "neo_tree_buffer_enter",
                handler = function()
                    vim.cmd 'highlight! Cursor blend=100'
                end
            },
            {
                event = "neo_tree_buffer_leave",
                handler = function()
                    vim.cmd 'highlight! Cursor guibg=#5f87af blend=0'
                end
            }
        },
    },
})

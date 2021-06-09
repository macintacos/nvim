local map = vim.api.nvim_set_keymap

-- TODO: Get MUCH more granular about what you do here! Mappings, styling, etc.
-- https://github.com/akinsho/nvim-bufferline.lua#usage
-- https://github.com/akinsho/nvim-bufferline.lua#configuration
-- There's so much shit to check out.

require("bufferline").setup{
    options = {
        numbers = "buffer_id",
        number_style = "",
        diagnostics = false,
    },
    highlights = {
        fill = {
            guibg = "#181a29"
        }
    }
}

-- Mappings
map("n", "[b", ":BufferLineCyclePrev<CR>", {silent = true})
map("n", "]b", ":BufferLineCycleNext<CR>", {silent = true})
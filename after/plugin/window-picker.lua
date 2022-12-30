require("window-picker").setup({
    autoselect_one = true,
    include_current = false,
    use_winbar = "always",
    filter_rules = {
        -- filter using buffer options
        bo = {
            -- if the file type is one of following, the window will be ignored
            filetype = {
                "neo-tree-popup",
                "notify",
            },

            -- if the buffer type is one of following, the window will be ignored
            buftype = { "terminal", "quickfix" },
        },
    },
    other_win_hl_color = "#e35e4f",
})

local picker = require("window-picker")

-- Mapping to switch the current window
vim.keymap.set("n", "<leader>wp", function()
    local picked_window_id = picker.pick_window() or vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(picked_window_id)
end, { desc = "Pick a window" })

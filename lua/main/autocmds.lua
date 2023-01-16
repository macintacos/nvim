local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight text when yanking
local yank_group = augroup("HighlightYank", {})
autocmd("TextYankPost", {
    group = yank_group,
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({
            higroup = "IncSearch",
            timeout = 150,
        })
    end,
})

-- Set lazygit file to yaml
autocmd({"BufRead", "BufEnter"}, {
    pattern = "*lazygit*",
    callback = function()
        vim.opt_local.filetype = "yaml"
    end,
})

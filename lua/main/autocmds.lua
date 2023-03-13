local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Set a bunch of config files to yaml
autocmd({ "BufRead", "BufEnter" }, {
    pattern = { "*lazygit*", "*yamlfmt*", "*yamllint*" },
    callback = function()
        vim.opt_local.filetype = "yaml"
    end,
})

-- Set a bunch of config files to toml
autocmd({ "BufRead", "BufEnter" }, {
    pattern = { "*jakrc*", "*xbarrc*" },
    callback = function()
        vim.opt_local.filetype = "toml"
    end,
})

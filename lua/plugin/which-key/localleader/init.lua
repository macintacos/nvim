package.path = PLUG_PATH .. '/which-key/localleader/?.lua;' .. package.path

require("markdown")

vim.cmd([[
    autocmd FileType markdown lua which_key_markdown()
]])

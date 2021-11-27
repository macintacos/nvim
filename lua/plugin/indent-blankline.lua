local global = vim.api.nvim_set_var
local nvim_cmd = vim.api.nvim_command

global("indent_blankline_use_treesitter", true)
global("indent_blankline_show_first_indent_level", false)
global("indent_blankline_filetype_exclude", {"dashboard", "help", "packer", "coc-explorer"})

nvim_cmd([[hi IndentBlanklineChar guifg=#6272a4 gui=nocombine]])

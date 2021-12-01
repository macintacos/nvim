require("neoscroll").setup {
    easing_function = "quadratic"
}

local t = {}

t['<C-u>'] = {'scroll', {'-vim.wo.scroll', 'true', '450'}}
t['<C-d>'] = {'scroll', {'vim.wo.scroll', 'true', '450'}}
t['<C-b>'] = {'scroll', {'-vim.api.nvim_win_get_height(0)', 'true', '450'}}
t['<C-f>'] = {'scroll', {'vim.api.nvim_win_get_height(0)', 'true', '450'}}
t['<C-y>'] = {'scroll', {'-0.10', 'false', '250'}}
t['<C-e>'] = {'scroll', {'0.10', 'false', '250'}}
t['G']     = {'scroll', {'vim.api.nvim_buf_line_count(0)', 'true', '500'}}
t['zt']    = {'zt', {'450'}}
t['zz']    = {'zz', {'450'}}
t['zb']    = {'zb', {'450'}}

require('neoscroll.config').set_mappings(t)


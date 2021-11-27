local gvar = vim.api.nvim_set_var

gvar("rooter_patterns", { '.git', '.git/', 'package.json', 'yarn.lock', 'poetry.lock'})

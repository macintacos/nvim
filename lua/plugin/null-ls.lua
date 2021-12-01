-- Ref: https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md#stylua
local null_ls = require("null-ls")

local sources = {
    -- Formatters
    null_ls.builtins.formatting.prettier,
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.formatting.black,

    -- Actions
    null_ls.builtins.code_actions.gitsigns,
}

require("null-ls").config({ sources = sources })

require("lspconfig")["null-ls"].setup({})

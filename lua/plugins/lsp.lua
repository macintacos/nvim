-- LSP configuration that is different from defaults provided by LazyVim
return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    -- [[ KEYMAPS ]]
    local keys = require("lazyvim.plugins.lsp.keymaps").get()

    -- disable keymaps we want to override
    keys[#keys + 1] = { "K", false }

    -- add keymaps
    keys[#keys + 1] = { "gh", vim.lsp.buf.hover, desc = "Hover" }
    keys[#keys + 1] = { "gl", vim.diagnostic.open_float, desc = "Open Diagnostic" }

    opts.diagnostics = {
      float = {
        border = "rounded",
      },
    }
  end,
}

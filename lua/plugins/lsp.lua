-- LSP configuration that is different from defaults provided by LazyVim
return {
  "neovim/nvim-lspconfig",
  opts = function()
    local keys = require("lazyvim.plugins.lsp.keymaps").get()

    -- disable keymaps we want to override
    keys[#keys + 1] = { "K", false }

    -- add keymaps
    keys[#keys + 1] = { "gh", vim.lsp.buf.hover, desc = "Hover" }
  end,
}

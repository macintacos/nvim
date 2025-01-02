return {
  "neovim/nvim-lspconfig",
  opts = function()
    local keys = require("lazyvim.plugins.lsp.keymaps").get()

    -- `gD` should open a split to the right, and go to definition
    keys[#keys + 1] = {
      "gD",
      function()
        vim.cmd("vsplit")
        vim.lsp.buf.definition()
      end,
    }
  end,
}

-- github.com/stevearc/conform.nvim
-- Auto-formatting on save via external formatters
vim.pack.add({ "https://github.com/stevearc/conform.nvim" }, { load = false })

-- Load on first save, configure formatters, then re-trigger BufWritePre
-- so the current save is formatted (conform's own handler takes over after)
vim.api.nvim_create_autocmd("BufWritePre", {
  once = true,
  callback = function()
    vim.cmd.packadd("conform.nvim")
    require("conform").setup({
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        yaml = { "yamlfmt" },
      },
      format_on_save = {
        timeout_ms = 3000,
        lsp_format = "fallback",
      },
    })
    vim.api.nvim_exec_autocmds("BufWritePre", {
      buffer = vim.api.nvim_get_current_buf(),
      modeline = false,
    })
  end,
})

-- Stub command so :ConformInfo works before the first save
vim.api.nvim_create_user_command("ConformInfo", function()
  vim.cmd.packadd("conform.nvim")
  require("conform").setup({
    formatters_by_ft = {
      lua = { "stylua" },
      sh = { "shfmt" },
      yaml = { "yamlfmt" },
    },
    format_on_save = {
      timeout_ms = 3000,
      lsp_format = "fallback",
    },
  })
  vim.cmd("ConformInfo")
end, { desc = "Lazy-loaded: conform.nvim" })

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
        just = { "just" },
        lua = { "stylua" },
        markdown = { "rumdl" },
        python = { "ruff_format" },
        rust = { "rustfmt" },
        sh = { "shfmt" },
        toml = { "taplo" },
        yaml = { "yamlfmt" },
      },
      formatters = {
        just = {
          command = "just",
          args = { "--fmt", "--justfile", "$FILENAME" },
          stdin = false,
        },
        shfmt = {
          prepend_args = { "-i", "0" },
        },
      },
      format_on_save = function(bufnr)
        if vim.b[bufnr].is_tmpl then
          return nil
        end
        return { timeout_ms = 3000, lsp_format = "fallback" }
      end,
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
      markdown = { "rumdl" },
      python = { "ruff_format" },
      rust = { "rustfmt" },
      sh = { "shfmt" },
      toml = { "taplo" },
      yaml = { "yamlfmt" },
    },
    formatters = {
      shfmt = {
        prepend_args = { "-i", "0" },
      },
    },
    format_on_save = function(bufnr)
      if vim.b[bufnr].is_tmpl then
        return nil
      end
      return { timeout_ms = 3000, lsp_format = "fallback" }
    end,
  })
  vim.cmd("ConformInfo")
end, { desc = "Lazy-loaded: conform.nvim" })

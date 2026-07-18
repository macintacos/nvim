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
        help = { "vimdoc" },
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
        rumdl = {
          -- `rumdl fmt` reads stdin, so rumdl never sees the file path and resolves
          -- its config from the process cwd. Pin cwd to the file's own directory so
          -- discovery is file-relative (like the LSP): a Claude prompt buffer in
          -- $TMPDIR picks up ~/.config/rumdl/rumdl.toml (MD013 reflow), while project
          -- files still get their own .rumdl.toml. Without this, formatting ran in
          -- Neovim's cwd, so a prompt opened from a repo that overrides MD013 never
          -- reflowed.
          cwd = function(_, ctx)
            return ctx.dirname
          end,
        },
        shfmt = {
          prepend_args = { "-i", "0" },
        },
        vimdoc = {
          command = "vimdoc-language-server",
          args = { "format", "$FILENAME" },
          stdin = false,
        },
      },
      format_on_save = function(bufnr)
        if vim.b[bufnr].is_tmpl then
          return nil
        end
        -- Svelte formats on demand only (<leader>f=), never on save: caret
        -- doesn't auto-format .svelte (Biome excludes them), so a save must not
        -- reformat its files to the LSP's prettier defaults.
        if vim.bo[bufnr].filetype == "svelte" then
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
      help = { "vimdoc" },
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
      vimdoc = {
        command = "vimdoc-language-server",
        args = { "format", "$FILENAME" },
        stdin = false,
      },
    },
    format_on_save = function(bufnr)
      if vim.b[bufnr].is_tmpl then
        return nil
      end
      -- Svelte formats on demand only (<leader>f=), never on save: caret
      -- doesn't auto-format .svelte (Biome excludes them), so a save must not
      -- reformat its files to the LSP's prettier defaults.
      if vim.bo[bufnr].filetype == "svelte" then
        return nil
      end
      return { timeout_ms = 3000, lsp_format = "fallback" }
    end,
  })
  vim.cmd("ConformInfo")
end, { desc = "Lazy-loaded: conform.nvim" })

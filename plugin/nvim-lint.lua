-- github.com/mfussenegger/nvim-lint
-- Runs linters on save, open, and leaving insert mode
vim.pack.add({ "https://github.com/mfussenegger/nvim-lint" }, { load = false })

-- Load on the first write/read/insert-leave, configure linters, then
-- register a persistent autocmd that lints on every subsequent trigger.
-- Also runs an immediate lint for the buffer that triggered the load.
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  once = true,
  callback = function()
    vim.cmd.packadd("nvim-lint")
    local lint = require("lint")
    -- Use tests/selene.toml for test files (has busted/luassert globals)
    lint.linters.selene.args = function()
      local file = vim.api.nvim_buf_get_name(0)
      if file:match("/tests/") then
        return { "--display-style", "json", "--config", "tests/selene.toml", "-" }
      end
      return { "--display-style", "json", "-" }
    end
    lint.linters_by_ft = {
      lua = { "selene" },
      markdown = { "markdownlint-cli2" },
      sh = { "shellcheck" },
    }
    -- Persistent autocmd for all future lint triggers
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      group = vim.api.nvim_create_augroup("__personal_nvim_lint", { clear = true }),
      callback = function()
        if vim.bo.modifiable then
          require("lint").try_lint()
        end
      end,
    })
    -- Lint the current buffer immediately
    if vim.bo.modifiable then
      require("lint").try_lint()
    end
  end,
})

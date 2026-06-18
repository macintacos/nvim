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

    lint.linters_by_ft = {
      lua = { "selene" },
      sh = { "shellcheck" },
    }

    -- Tests get a looser selene config (busted/luassert globals).
    -- nvim-lint requires `args` to be a table, so resolve it per-buffer
    -- and assign just before each try_lint() call.
    local function selene_args_for_buffer()
      local file = vim.api.nvim_buf_get_name(0)
      if file:match("/tests/") then
        return { "--display-style", "json", "--config", "tests/selene.toml", "-" }
      end
      return { "--display-style", "json", "-" }
    end

    -- Persistent autocmd for all future lint triggers
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      group = vim.api.nvim_create_augroup("__personal_nvim_lint", { clear = true }),
      callback = function()
        if not vim.bo.modifiable or vim.b.is_tmpl then
          return
        end
        lint.linters.selene.args = selene_args_for_buffer()
        lint.try_lint()
      end,
    })

    -- Lint the current buffer immediately
    if vim.bo.modifiable and not vim.b.is_tmpl then
      lint.linters.selene.args = selene_args_for_buffer()
      lint.try_lint()
    end
  end,
})

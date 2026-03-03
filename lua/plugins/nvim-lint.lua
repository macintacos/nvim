---@module "lazy"
---@type LazySpec
return {
  "mfussenegger/nvim-lint",
  event = { "BufWritePost", "BufReadPost", "InsertLeave" },
  config = function()
    require("lint").linters_by_ft = {
      lua = { "selene" },
      sh = { "shellcheck" },
      markdown = { "markdownlint-cli2" },
    }

    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      group = vim.api.nvim_create_augroup("__personal_nvim_lint", { clear = true }),
      callback = function()
        if vim.bo.modifiable then
          require("lint").try_lint()
        end
      end,
    })
  end,
}

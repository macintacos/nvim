-- github.com/jakewvincent/mkdnflow.nvim
-- Conveniences for dealing with Markdown and links

---@module "lazy"
---@type LazySpec
return {
  "jakewvincent/mkdnflow.nvim",
  config = function()
    require("mkdnflow").setup({
      mappings = {
        MkdnNewListItem = { "i", "<CR>" },
      },
    })
  end,
}

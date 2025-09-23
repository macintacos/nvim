-- github.com/MeanderingProgrammer/render-markdown.nvim
-- Render markdown in-line, without needing to show a preview

---@module "lazy"
---@type LazySpec
return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    html = {
      comment = {
        conceal = false,
      },
    },
  },
}

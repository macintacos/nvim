---Draws a vertical line marking the indent scope the cursor sits in.
---@see https://github.com/nvim-mini/mini.indentscope/blob/main/doc/mini-indentscope.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.indentscope", version = "stable" } })

-- Scope indicator only: the `ii`/`ai` textobjects and `[i`/`]i` motions it maps
-- by default are already provided by snacks.scope. Animation is off to match
-- vim.g.snacks_animate = false.
local indentscope = require("mini.indentscope")
indentscope.setup({
  draw = { animation = indentscope.gen_animation.none() },
  mappings = {
    object_scope = "",
    object_scope_with_border = "",
    goto_top = "",
    goto_bottom = "",
  },
})

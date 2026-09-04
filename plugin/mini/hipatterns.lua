---Colorizes hex codes in place: the background of each `#rrggbb` becomes the
---color it names.
---@see https://github.com/nvim-mini/mini.hipatterns/blob/main/doc/mini-hipatterns.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.hipatterns", version = "stable" } })

-- The module ships no highlighters of its own, so this table is the whole of
-- what it does — anything else to highlight gets an entry here.
local hipatterns = require("mini.hipatterns")
hipatterns.setup({
  highlighters = {
    hex_color = hipatterns.gen_highlighter.hex_color(),
  },
})

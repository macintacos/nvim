local hi = vim.highlight.create
local colors = require("plug.global_colors")

require("gitsigns").setup {
    current_line_blame = true,
    current_line_blame_delay = 600,
}

-- Appearance
hi("GitSignsCurrentLineBlame", {guifg = colors.comment}, false)
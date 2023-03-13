-- Modules w/ default configs
require("mini.ai").setup() -- more text objects
require("mini.indentscope").setup() -- show scope of current cursor
require("mini.trailspace").setup() -- highlight trailing spaces
require("mini.bracketed").setup() -- use brackets to navigate around

-- Modules w/ custom configs

--- Move things up, down, and around.
require("mini.move").setup({
    mappings = {
        left = "<S-h>",
        right = "<S-l>",
        down = "<S-j>",
        up = "<S-k>",

        -- Move current line in Normal mode
        line_left = "<S-h>",
        line_right = "<S-l>",
        line_down = "<S-j>",
        line_up = "<S-k>",
    },
})

--- Mess with alignment in selected code
require("mini.align").setup({
    -- Module mappings. Use `''` (empty string) to disable one.
    mappings = {
        start = "ga",
        start_with_preview = "gA",
    },

    -- Default options controlling alignment process
    options = {
        split_pattern = "",
        justify_side = "left",
        merge_delimiter = "",
    },

    -- Default steps performing alignment (if `nil`, default is used)
    steps = {
        pre_split = {},
        split = nil,
        pre_justify = {},
        justify = nil,
        pre_merge = {},
        merge = nil,
    },
})

local wk = require("which-key")

wk.register({
    -- Common actions
    [";"] = { ":normal gcc<CR>", "Toggle Comment" },

    -- Everything else
    f = {
        name = "file",
        ["="] = { "<Cmd>LspZeroFormat<CR>", "Format Range/File" },
    },
    x = {
        name = "text",
        c = {
            name = "change case",
            [" "] = { "<Plug>CaserVSpaceCase", "space case" },
            ["."] = { "<Plug>CaserVDotCase", "dot.case" },
            m = { "<Plug>CaserVMixedCase", "MixedCase" },
            c = { "<Plug>CaserVCamelCase", "camelCase" },
            s = { "<Plug>CaserVSnakeCase", "snake_case" },
            t = { "<Plug>CaserVTitleCase", "Title Case" },
            S = { "<Plug>CaserVSnakeCase", "Sentence case" },
            k = { "<Plug>CaserVKebabCase", "kebab-case" },
            K = { "<Plug>CaserVTitleKebabCase", "Title-Kebab-Case" },
            u = { "<Plug>CaserVUpperCase", "UPPERCASE" },
            l = { "u", "lowercase" },
        },
    },
}, { prefix = "<leader>", mode = "v" })

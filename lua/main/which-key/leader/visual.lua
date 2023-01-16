local wk = require("which-key")
local cmd = require("main.helpers").cmd

wk.register({
    -- Common actions
    [";"] = { cmd("normal gcc"), "Toggle Comment" },

    -- Everything else
    f = {
        name = "file",
        ["="] = { cmd("LspZeroFormat"), "Format Range/File" },
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

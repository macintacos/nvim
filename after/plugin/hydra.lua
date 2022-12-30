local Hydra = require("hydra")
local cmd = require("hydra.keymap-util").cmd

Hydra({
    name = "Resize Windows",
    config = {
        color = "amaranth",
        invoke_on_body = true,
        hint = {
            type = "statusline",
        },
    },
    mode = "n",
    body = "<leader>wz",
    heads = {
        { "<left>", cmd("vertical resize +5") },
        { "<right>", cmd("vertical resize -5") },
        { "<up>", cmd("resize +5") },
        { "<down>", cmd("resize -5"), { desc = "+/-" } },
    },
})

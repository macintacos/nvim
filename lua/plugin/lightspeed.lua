local map = vim.api.nvim_set_keymap

-- Needs to come before setup to 's/S' works properly,
-- see: https://github.com/ggandor/lightspeed.nvim/issues/11
-- Eventually, would like to remove this and only map 'f/F'
map("n", "f", "<Plug>Lightspeed_s", {})
map("n", "F", "<Plug>Lightspeed_S", {})

require("lightspeed").setup {
    exit_after_idle_msecs = nil,
}


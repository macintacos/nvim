local map = vim.api.nvim_set_keymap

require("lightspeed").setup {
    exit_after_idle_msecs = nil,
}

map("n", "f", "<Plug>Lightspeed_s", {})
map("n", "F", "<Plug>Lightspeed_S", {})

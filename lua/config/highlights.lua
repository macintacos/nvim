-- Adjustments to colors and whatnot
vim.api.nvim_set_hl(0, "Normal", { bg = "#10111f" })
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#202342" })
vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#393f77", bg = "NONE" })

-- blink.cmp completion menu (slightly lighter than editor bg)
vim.api.nvim_set_hl(0, "BlinkCmpMenu", { bg = "#181a2e" })
vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { bg = "#181a2e" })
vim.api.nvim_set_hl(0, "BlinkCmpLabelDescription", { fg = "#7a7fa0", bg = "NONE" })
vim.api.nvim_set_hl(0, "BlinkCmpLabelDetail", { fg = "#7a7fa0", bg = "NONE" })
-- blink.cmp documentation preview (matches editor bg)
vim.api.nvim_set_hl(0, "BlinkCmpDoc", { bg = "#10111f" })
vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { bg = "#10111f" })

-- mini.statusline things
vim.api.nvim_set_hl(0, "MiniStatuslineFilename", { bg = "#101120" })

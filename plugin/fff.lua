-- github.com/dmtrKovalenko/fff.nvim
-- Fast fuzzy file finder with Rust backend
vim.pack.add({ "https://github.com/dmtrKovalenko/fff.nvim" }, { load = false })
vim.schedule(function()
  vim.cmd.packadd("fff.nvim")
  require("fff").setup({
    debug = { enabled = false, show_scores = false },
    layout = { prompt_position = "top" },
    preview = { show_file_info = true },
  })
end)

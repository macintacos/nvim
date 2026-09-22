-- github.com/folke/flash.nvim
-- Jump anywhere on screen with labeled targets via 's', 'f', 'F', 't' and 'T'
vim.pack.add({ "https://github.com/folke/flash.nvim" }, { load = false })

-- Deferred rather than lazy-loaded off a key stub: flash claims f/F/t/T/;/,
-- when it loads, and a stub that replays the key it swallowed can't restore a
-- pending operator, so the session's first `df` would delete nothing.
vim.schedule(function()
  vim.cmd.packadd("flash.nvim")
  -- Label every f/F/t/T match rather than only highlighting it, so any
  -- character in the motion's direction is one keystroke away, not a run of ';'.
  require("flash").setup({ modes = { char = { jump_labels = true } } })
  require("helpers.mappings").map("Flash", { "n", "x", "o" }, "s", function()
    require("flash").jump()
  end)
end)

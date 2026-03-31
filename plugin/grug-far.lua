-- github.com/MagicDuck/grug-far.nvim
-- Project-wide search and replace interface
vim.pack.add({ "https://github.com/MagicDuck/grug-far.nvim" }, { load = false })

local commands = { "GrugFar", "GrugFarWithin" }
for _, cmd in ipairs(commands) do
  vim.api.nvim_create_user_command(cmd, function(info)
    for _, c in ipairs(commands) do
      pcall(vim.api.nvim_del_user_command, c)
    end
    vim.cmd.packadd("grug-far.nvim")
    require("grug-far").setup({ headerMaxWidth = 80 })
    vim.cmd(cmd .. (info.bang and "!" or "") .. " " .. (info.args or ""))
  end, { nargs = "*", bang = true, desc = "Lazy-loaded: grug-far.nvim" })
end

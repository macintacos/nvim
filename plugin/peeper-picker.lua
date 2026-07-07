-- github.com/parwest/peeper-picker.nvim
-- LSP-powered picker that peeks at the definition/references of the symbol under the cursor
vim.pack.add({ "https://github.com/parwest/peeper-picker.nvim" }, { load = false })

local map = require("helpers.mappings").map
local Cmd = require("helpers.mappings").Cmd

-- Lazy-load peeper-picker.nvim on first use of either command. Each stub
-- deletes both stubs, packadds the plugin (registering the real commands and
-- running setup), then re-runs the requested command.
local commands = { "PeeperPicker", "PeeperPickerHistory" }
for _, cmd in ipairs(commands) do
  vim.api.nvim_create_user_command(cmd, function(info)
    for _, c in ipairs(commands) do
      pcall(vim.api.nvim_del_user_command, c)
    end
    vim.cmd.packadd("peeper-picker.nvim")
    require("peeper_picker").setup({})
    vim.cmd(cmd .. (info.bang and "!" or "") .. " " .. (info.args or ""))
  end, { nargs = "*", bang = true, desc = "Lazy-loaded: peeper-picker.nvim" })
end

map("Peeper Picker", "n", "gpp", Cmd("PeeperPicker"))
map("Peeper Picker history", "n", "gph", Cmd("PeeperPickerHistory"))

-- Bare `gp` (builtin put-and-leave-cursor-after) is shadowed by gpp/gph, so
-- neutralize it: a lone `gp` does nothing instead of pasting.
map("No-op (shadowed by gpp/gph)", "n", "gp", "<Nop>")

-- github.com/RRethy/vim-illuminate
-- Highlights other instances of the word under the cursor
vim.pack.add({ "https://github.com/RRethy/vim-illuminate" })

require("illuminate").configure({
  delay = 200,
  large_file_cutoff = 2000,
  large_file_overrides = { providers = { "lsp" } },
})

-- Register the Snacks toggle once plugin/snacks.lua has been sourced. Fires on
-- VimEnter rather than from vim.schedule() because a scheduled callback runs at
-- the next event loop pump, and vim.pack pumps it mid-startup while installing
-- a plugin — at which point snacks.lua (sourced after this file) hasn't run and
-- require("snacks") aborts the plugin file that triggered the install.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    require("snacks")
      .toggle({
        name = "Illuminate",
        get = function()
          return not require("illuminate.engine").is_paused()
        end,
        set = function(enabled)
          local m = require("illuminate")
          if enabled then
            m.resume()
          else
            m.pause()
          end
        end,
      })
      :map("<leader>ux")
  end,
})

local map = require("helpers.mappings").map

local function map_ref(key, dir, buffer)
  map(dir:sub(1, 1):upper() .. dir:sub(2) .. " Reference", "n", key, function()
    require("illuminate")["goto_" .. dir .. "_reference"](false)
  end, { buffer = buffer })
end

map_ref("]]", "next")
map_ref("[[", "prev")

vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    local buffer = vim.api.nvim_get_current_buf()
    map_ref("]]", "next", buffer)
    map_ref("[[", "prev", buffer)
  end,
})

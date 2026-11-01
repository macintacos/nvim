-- github.com/Bekaboo/dropbar.nvim
-- Breadcrumb navigation bar
vim.pack.add({ "https://github.com/Bekaboo/dropbar.nvim" })

local utils = require("dropbar.utils")

---Close the open submenu, or with none open, swap this segment's menu for the one
---before it in the winbar. The first segment's menu stays open.
local function step_out()
  local menu = utils.menu.get_current()
  if not menu then
    return
  end
  if menu.prev_menu then
    menu:close()
    return
  end
  -- By buffer too: the menu's preview has swapped another buffer into the window.
  local bar = utils.bar.get({ buf = menu.prev_buf, win = menu.prev_win }) --[[@as dropbar_t?]]
  if not bar then
    return
  end
  for idx, segment in ipairs(bar.components) do
    if segment.menu == menu and idx > 1 then
      menu:close()
      bar:pick(idx - 1)
      return
    end
  end
end

---Open the submenu of the row under the cursor. Unlike <CR>, never jumps to a row.
local function descend()
  local menu = utils.menu.get_current()
  local entry = menu and menu.entries[vim.api.nvim_win_get_cursor(0)[1]]
  -- A row's first component is the submenu arrow, clickable only when the row has children.
  local arrow = entry and entry.components[1]
  if menu and arrow and arrow.on_click then
    menu:click_on(arrow, nil, 1, "l")
  end
end

---Close every menu level, back to the window the winbar belongs to.
local function leave()
  local menu = utils.menu.get_current()
  local root = menu and menu:root()
  if root then
    root:close()
  end
end

-- dropbar_configs_t declares every key required, but setup() deep-merges this onto its defaults.
---@diagnostic disable-next-line: missing-fields, param-type-mismatch
require("dropbar").setup({
  menu = {
    keymaps = {
      h = step_out,
      l = descend,
      ["<Esc>"] = leave,
    },
  },
})

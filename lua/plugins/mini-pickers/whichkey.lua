---A picker over which-key's mapping tree.
---
---which-key keeps one tree per buffer and mode, built from the real keymaps
---plus its own spec and with its own triggers filtered back out -- exactly what
---the popup can reach. `nvim_get_keymap`, which `:Pick keymaps` reads, has
---neither the group descriptions nor that filtering.

local M = {}

---Group descriptions above `node`, outermost first.
---@param node wk.Node
---@return string[]
local function trail(node)
  local ret = {}
  local parent = node.parent
  while parent do
    if parent.desc then
      table.insert(ret, 1, parent.desc)
    end
    parent = parent.parent
  end
  return ret
end

---Picker items for `nodes`: keys padded into a column, and the group trail
---folded into the matched text so `<leader>gs` is reachable by "git" too.
---@param nodes wk.Node[]
---@return table[]
function M._rows(nodes)
  local rows, width = {}, 0
  for _, node in ipairs(nodes) do
    -- A mapping with no description of its own still shows in the popup, with
    -- its rhs standing in for one.
    local rhs = node.keymap and node.keymap.rhs
    local desc = node.desc or (type(rhs) == "string" and rhs ~= "" and rhs or nil)
    if desc then
      local lhs = (node.keys:gsub("^<Space>", "<leader>"))
      local crumbs = trail(node)
      crumbs[#crumbs + 1] = desc
      width = math.max(width, vim.fn.strdisplaywidth(lhs))
      rows[#rows + 1] = { keys = node.keys, lhs = lhs, label = table.concat(crumbs, " » ") }
    end
  end

  table.sort(rows, function(a, b)
    return a.lhs < b.lhs
  end)

  for _, row in ipairs(rows) do
    row.text = row.lhs .. (" "):rep(width - vim.fn.strdisplaywidth(row.lhs) + 2) .. row.label
  end
  return rows
end

---Every mapping which-key can reach in normal mode from `buf`, groups aside --
---a group's keys only reopen the popup.
---@param buf integer
---@return wk.Node[]
local function leaves(buf)
  local mode = require("which-key.buf").get({ buf = buf, mode = "n" })
  if not mode then
    return {}
  end
  local ret = {}
  mode.tree:walk(function(node)
    if not node:is_group() then
      ret[#ret + 1] = node
    end
  end)
  return ret
end

---Pick a which-key mapping and run it.
function M.pick()
  local rows = M._rows(leaves(vim.api.nvim_get_current_buf()))
  return MiniPick.start({
    source = {
      name = "Keymaps (which-key)",
      items = rows,
      choose = function(item)
        -- Typing the keys rather than calling the rhs is the one path that
        -- works for every mapping shape (expr, <Plug>, operator-pending), and
        -- it has to wait for the picker to hand the buffer back.
        vim.schedule(function()
          vim.api.nvim_feedkeys(vim.keycode(item.keys), "mt", false)
        end)
      end,
    },
  })
end

return M

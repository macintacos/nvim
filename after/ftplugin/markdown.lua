-- Softwrapped blockquotes hang under their text: 'breakindentopt=list:-1' sizes
-- the indent from 'formatlistpat', which the runtime ftplugin covers for list
-- markers only. The trailing group keeps a list inside a quote aligned too.
vim.opt_local.formatlistpat:append([[\|^\s*>\+\s*\%([-*+]\s\+\|\d\+[.)]\s\+\)\=]])

-- <Tab>/<S-Tab> indent the list item under the cursor, in insert mode.
-- mkdnflow's own MkdnTab does this only for an empty item, so its <Tab> mapping
-- is disabled in plugin/mkdnflow.lua in favor of these.

---Indent or dedent the list item under the cursor, else jump table cells.
---Both wrappers return a key to feed only when they did not handle the line, so
---a line that is neither a list item nor a table falls through to a literal key.
---@param direction integer 1 to indent (<Tab>), -1 to dedent (<S-Tab>)
local function indent_list_item(direction)
  local wrappers = require("mkdnflow.wrappers")
  if not wrappers.indentListItem(direction) then
    return
  end
  local fallback = wrappers.indentListItemOrJumpTableCell(direction)
  if fallback then
    vim.api.nvim_feedkeys(fallback, "n", true)
  end
end

-- blink.cmp maps <Tab> on InsertEnter -- after these, so it wins -- and reaches
-- them through its "fallback" command, which runs only when no menu is open.
vim.keymap.set("i", "<Tab>", function()
  indent_list_item(1)
end, { buffer = true, desc = "Indent list item or jump to next table cell" })

vim.keymap.set("i", "<S-Tab>", function()
  indent_list_item(-1)
end, { buffer = true, desc = "Dedent list item or jump to previous table cell" })

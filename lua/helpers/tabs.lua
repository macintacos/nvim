local M = {}

-- nf-md-numeric_1_box through _9_box, as herdr numbers its panes; 5's box breaks the
-- codepoints' stride of 3.
local NUMBER_BOXES = vim.tbl_map(vim.fn.nr2char, {
  0xF03A4,
  0xF03A7,
  0xF03AA,
  0xF03AD,
  0xF03B1,
  0xF03B3,
  0xF03B6,
  0xF03B9,
  0xF03BC,
})

-- nf-fa-plug, the statusline's update count icon.
local PLUG = vim.fn.nr2char(0xF1E6)
-- The scratch keymaps' icon.
local SCRATCH = vim.fn.nr2char(0xF1781)

---Tab number `nr` as the tabline shows it: boxed up to 9, plain past that.
---@param nr number
---@return string
function M.number_box(nr)
  return NUMBER_BOXES[nr] or tostring(nr)
end

---@class tabs.Special
---@field name string
---@field icon string
---@field hl string
---@field hl_sel string The highlight while the tab is current.
---@field hl_list string The highlight in the tab picker, which keeps its own background.

---How a tab showing `buf` stands out: as vim.pack's update review (`vim.pack.update()`'s
---confirmation), as a scratch file, or not at all.
---@param buf integer
---@return tabs.Special?
function M.special(buf)
  if vim.bo[buf].filetype == "nvim-pack" then
    return {
      name = "Plugin Updates",
      icon = PLUG,
      hl = "TabbyPack",
      hl_sel = "TabbyPackSel",
      hl_list = "MiniPickTabPack",
    }
  end
  local path = vim.api.nvim_buf_get_name(buf)
  if require("plugins.scratch").is_scratch(path) then
    local stem = vim.fn.fnamemodify(path, ":t:r")
    local name = stem == "scratch" and "Scratch" or "Scratch: " .. stem
    return {
      name = name,
      icon = SCRATCH,
      hl = "TabbyScratch",
      hl_sel = "TabbyScratchSel",
      hl_list = "MiniPickTabScratch",
    }
  end
end

return M

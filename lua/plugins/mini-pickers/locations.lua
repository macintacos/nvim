---Location-list LSP pickers (`references`, `definition`, …), listed as paths.
---
---mini.extra prints each hit as `path│lnum│col│ text`. The side preview already
---shows the line, so the text is dropped and the position hangs off the right
---edge as dim virtual text, the way the live grep shows its line numbers.

local preview = require("plugins.mini-pickers.preview")
local render = require("plugins.mini-pickers.render")

local M = {}

---Split a mini.extra location row into its path and position.
---@param text string
---@return string path The row verbatim when it carries no position.
---@return string? position "lnum:col"
local function parse(text)
  local path, lnum, col = text:match("^(.-)│(%d+)│(%d+)")
  if not path then
    return text, nil
  end
  return path, lnum .. ":" .. col
end

---`source.show` for the location pickers.
---@param buf_id integer
---@param items table[]
---@param query string[]
local function show(buf_id, items, query)
  local display, positions = {}, {}
  for i, item in ipairs(items) do
    local path, position = parse(item.text)
    display[i], positions[i] = vim.tbl_extend("force", item, { text = path }), position
  end

  MiniPick.default_show(buf_id, display, query, { show_icons = true })

  vim.api.nvim_buf_clear_namespace(buf_id, render.ns, 0, -1)
  for i = 1, #items do
    if positions[i] then
      vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, 0, {
        virt_text = { { positions[i], "LineNr" } },
        virt_text_pos = "right_align",
        priority = 199,
      })
    end
  end
end

---`source.match` on the paths alone, so a query never hits text the rows hide.
---@param stritems string[]
---@param inds integer[]
---@param query string[]
---@return integer[]
local function match(stritems, inds, query)
  local paths = vim.tbl_map(function(stritem)
    return (parse(stritem))
  end, stritems)
  -- `sync` makes `default_match` return the matches instead of setting them.
  return MiniPick.default_match(paths, inds, query, { sync = true }) --[[@as integer[] ]]
end

-- Exposed for tests: the row format, the renderer, and the matcher.
M._parse = parse
M._show = show
M._match = match

---Open a location picker.
---@param local_opts table Passed through to `MiniExtra.pickers.lsp`.
function M.pick(local_opts)
  return MiniExtra.pickers.lsp(local_opts, {
    source = { show = show, match = match },
    window = preview.window(),
  })
end

return M

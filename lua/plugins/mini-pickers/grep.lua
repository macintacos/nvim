---Live grep rendered as a breadcrumb list.
---
---`MiniPick.default_show` prints an rg hit as `path│lnum│col│text`, so the path
---repeats on every row of a file and the matched text starts three columns in.
---This changes only the drawing — the items stay the raw rg strings, so
---choosing and previewing still work — hoisting the path into a virtual header
---above each run of hits and right-aligning the line number against the text it
---belongs to.
---
---rg walks a file at a time and `grep_live` matches with `do_match = false`, so
---hits arrive already grouped by path: one header per run of equal paths covers
---every hit in that file.

local render = require("plugins.mini-pickers.render")
local symbols = require("plugins.mini-pickers.symbols")

local M = {}

---Split one rg item into its path, line number, and matched text.
---
---`grep_live` runs rg with `--field-match-separator '\x00'`, so an item is
---`path\0lnum\0col\0text`. Leading indentation is dropped from the text — the
---rows are already indented under their header, and a deeply nested match
---would otherwise start off the right edge of the window.
---@param item any
---@return string? path nil when the item is not an rg hit.
---@return string? lnum
---@return string text Always set; the item verbatim when it does not parse.
local function parse(item)
  local str = tostring(item)
  local path, lnum, text = str:match("^(.-)%z(%d+)%z%d+%z(.*)$")
  if not path then
    return nil, nil, str
  end
  return path, lnum, (text:gsub("^%s+", ""))
end

---`source.show` for the live grep.
---@param buf_id integer
---@param items any[]
---@param query string[]
local function show(buf_id, items, query)
  local paths, lnums, lines = {}, {}, {}
  for i, item in ipairs(items) do
    paths[i], lnums[i], lines[i] = parse(item)
  end

  MiniPick.default_show(buf_id, lines, query)

  local state = MiniPick.get_picker_state()
  local width = state and vim.api.nvim_win_get_width(state.windows.main) or 80

  vim.api.nvim_buf_clear_namespace(buf_id, render.ns, 0, -1)
  local prev_path, first_has_header = nil, false
  for i = 1, #lines do
    if paths[i] and paths[i] ~= prev_path then
      local ok, icon, hl = pcall(MiniIcons.get, "file", paths[i])
      icon = ok and icon or " "
      vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, 0, {
        virt_lines = {
          {
            { icon .. " ", ok and hl or "Comment" },
            { symbols.fit(paths[i], width - 2), render.crumb_hl() },
          },
        },
        virt_lines_above = true,
        priority = 199,
      })
      first_has_header = first_has_header or i == 1
    end

    if lnums[i] then
      vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, 0, {
        virt_text = { { lnums[i], "LineNr" } },
        virt_text_pos = "right_align",
        priority = 199,
      })
    end

    -- Indent the hits so the header's first glyph sits left of what it covers.
    vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, 0, {
      virt_text = { { "  " } },
      virt_text_pos = "inline",
      priority = 199,
    })

    prev_path = paths[i]
  end

  if state then
    render.reserve_trail_row(state.windows.main, first_has_header)
  end
end

-- Exposed for tests: the item format is the only part worth asserting headlessly.
M._parse = parse
M._show = show

---Open the live grep picker.
---@param local_opts table? Options for `MiniPick.builtin.grep_live`.
function M.pick(local_opts)
  return MiniPick.builtin.grep_live(local_opts, { source = { show = show } })
end

return M

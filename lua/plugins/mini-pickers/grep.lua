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

local side_preview = require("plugins.mini-pickers.preview")
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
---@return integer? col 1-based byte column where the hit starts.
local function parse(item)
  local str = tostring(item)
  local path, lnum, col, text = str:match("^(.-)%z(%d+)%z(%d+)%z(.*)$")
  if not path then
    return nil, nil, str
  end
  return path, lnum, (text:gsub("^%s+", "")), tonumber(col)
end

-- Characters Vim's very-magic regex treats as operators but rg's regex reads
-- literally. Everything else the two dialects spell the same way.
local VIM_ONLY_SPECIALS = "[<>=@%%&~]"

---Where the query's match ends, given where rg says it starts.
---
---rg reports only a hit's start column, which leaves the preview marking one
---character. The rg pattern is re-run as a Vim regex to measure the rest.
---Syntax only rg understands (inline flags, lookarounds) fails to compile or to
---match at `col`, and gets nil rather than a guess.
---@param line string The line the hit is on.
---@param col integer 1-based byte column where the hit starts.
---@param pattern string The rg pattern.
---@param ignore_case boolean Whether rg searched case-insensitively.
---@return integer? end_col 0-based exclusive byte column.
local function match_end(line, col, pattern, ignore_case)
  local vim_pattern = (ignore_case and "\\c" or "\\C") .. "\\v" .. pattern:gsub(VIM_ONLY_SPECIALS, "\\%0")
  local ok, regex = pcall(vim.regex, vim_pattern)
  if not ok then
    return nil
  end
  local from, to = regex:match_str(line:sub(col))
  if from ~= 0 then
    return nil
  end
  return col - 1 + to
end

---`source.preview` that marks the whole match, not just its first character.
---@param buf_id integer
---@param item any
local function preview(buf_id, item)
  MiniPick.default_preview(buf_id, item)
  local _, lnum, _, col = parse(item)
  local pattern = table.concat(MiniPick.get_picker_query() or {})
  if not (lnum and col) or pattern == "" then
    return
  end
  local row = tonumber(lnum) - 1
  local line = vim.api.nvim_buf_get_lines(buf_id, row, row + 1, false)[1]
  -- Mirrors the case flag `grep_live` hands rg.
  local ignore_case = vim.o.ignorecase and not (vim.o.smartcase and pattern:find("%u"))
  local end_col = line and match_end(line, col, pattern, ignore_case)
  if end_col then
    vim.api.nvim_buf_set_extmark(buf_id, render.ns, row, col - 1, {
      end_col = end_col,
      hl_group = "MiniPickPreviewRegion",
      priority = 203,
    })
  end
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

---Grep scope for one filesystem entry.
---
---A directory greps itself. A file greps its parent directory narrowed back down
---to the file: the leading `/` anchors the glob to the search root, so a
---same-named file in a subdirectory does not come along.
---@param path string
---@param fs_type "file"|"directory"
---@return string cwd Directory the picker searches.
---@return string[] globs Restriction passed to `grep_live`.
local function scope(path, fs_type)
  if fs_type == "directory" then
    return path, {}
  end
  return vim.fs.dirname(path), { "/" .. vim.fs.basename(path) }
end

-- Exposed for tests: the item format and the scope split are the only parts
-- worth asserting headlessly.
M._parse = parse
M._show = show
M._match_end = match_end
M._scope = scope

---Open the live grep picker.
---@param local_opts table? Options for `MiniPick.builtin.grep_live`.
---@param opts table? Options for `MiniPick.start`, merged over the custom show.
function M.pick(local_opts, opts)
  opts = vim.tbl_deep_extend(
    "force",
    { source = { show = show, preview = preview }, window = side_preview.window() },
    opts or {}
  )
  return MiniPick.builtin.grep_live(local_opts, opts)
end

---Open the live grep picker scoped to one filesystem entry.
---
---The scope replaces `grep_live`'s `(rg regex)` detail in the border label,
---since it is the part that actually varies between these pickers. The label is
---fitted from the left, so a path too long for the window keeps its tail.
---@param path string
---@param fs_type "file"|"directory"
function M.pick_in(path, fs_type)
  local cwd, globs = scope(path, fs_type)
  local label = vim.fn.fnamemodify(path, ":~:.") .. (fs_type == "directory" and "/" or "")
  return M.pick({ globs = globs }, { source = { cwd = cwd, name = "Grep live (" .. label .. ")" } })
end

return M

---`:Pick files`, listing through `rg` with a few ignored paths added back.

local render = require("plugins.mini-pickers.render")

local M = {}

---Paths `.gitignore` hides that should still show up in the picker.
---
---Handed to `rg` as literal path arguments, the one spelling that outranks an
---ignore file: a positive `-g` glob also outranks it but turns the run into a
---whitelist and drops every other file, and `--ignore-file` with a `!` rule
---loses to `.gitignore` outright. Nothing expands these, since the spawn has
---no shell — a plain relative path to a file or a directory. Dotfiles are
---already covered by `--hidden`.
---@type string[]
M.extra = { "CLAUDE.md", ".env" }

---Build the `rg` invocation for a directory.
---
---Extras this project does not have are dropped: `rg` errors on a path that
---is not there, and the list is shared by every project.
---@param cwd string Directory the picker lists.
---@return string[]
function M._command(cwd)
  -- `--hidden` reaches dotfiles like `.mise/tasks/` and `.emmyrc.json`, which
  -- rg skips by default; `.git` is the one directory it must not follow into.
  local command = { "rg", "--files", "--color=never", "--hidden", "--glob", "!.git", "." }
  for _, path in ipairs(M.extra) do
    if vim.uv.fs_stat(vim.fs.joinpath(cwd, path)) then
      table.insert(command, path)
    end
  end
  return command
end

---Turn rg's output lines into items.
---
---The `.` argument prefixes every path rg walks to with `./` while the extra
---paths come back bare, so a file listed both ways arrives twice.
---@param lines string[]
---@return string[]
function M._postprocess(lines)
  local items, seen = {}, {}
  for _, line in ipairs(lines) do
    local path = line:gsub("^%./", "")
    if path ~= "" and not seen[path] then
      seen[path] = true
      table.insert(items, path)
    end
  end
  return items
end

---@param path string
---@return string
local function filename(path)
  return (path:gsub("^.*/", ""))
end

---The path with its filename repeated in front, so an in-order query can name
---the filename before the directories above it. The `\0` seam is untypeable,
---so an exact query never matches across it.
---@param path string
---@return string
local function filename_first(path)
  return filename(path) .. "\0" .. path
end

---@type table<string[], string[]>
local copies = setmetatable({}, { __mode = "k" })

---`source.match` over the filename-first paths: `buzfoo` finds `foo/buz.ts`,
---and a filename hit starts earlier, so it outranks an equally tight directory
---hit. `^` still anchors to the start of the path.
---@param stritems string[]
---@param inds integer[]
---@param query string[]
---@return integer[]? matches Nil while a picker is open; mini.pick sets them.
local function match(stritems, inds, query)
  if query[1] == "^" then
    return MiniPick.default_match(stritems, inds, query)
  end
  -- mini.pick hands every keystroke the same table, so build the copy once.
  -- ponytail: the first keystroke pays for it, ~200ms at 200k paths; build it
  -- when the items arrive if that hitch shows up.
  copies[stritems] = copies[stritems] or vim.tbl_map(filename_first, stritems)
  return MiniPick.default_match(copies[stritems], inds, query)
end

---Byte ranges of the narrowest in-order match of `chars` in `s`, the one
---mini.pick highlights.
---@param s string
---@param chars string[] Non-empty.
---@return [integer, integer][]? ranges One `{ from, to }` per element of `chars`.
local function narrowest(s, chars)
  local best, init = nil, 1
  while true do
    local ranges, to = {}, init - 1
    for i, char in ipairs(chars) do
      local from = s:find(char, to + 1, true)
      if not from then
        return best
      end
      to = from + #char - 1
      ranges[i] = { from, to }
    end
    if not best or ranges[#ranges][1] - ranges[1][1] < best[#best][1] - best[1][1] then
      best = ranges
    end
    init = ranges[1][1] + 1
  end
end

---Where a filename-first match of `chars` falls in `path`. Nil when the path
---matches in order, since mini.pick already highlights that.
---@param path string
---@param chars string[] Non-empty.
---@return [integer, integer][]?
local function filename_first_ranges(path, chars)
  if narrowest(path, chars) then
    return nil
  end
  local ranges = narrowest(filename_first(path), chars)
  if not ranges then
    return nil
  end
  local base = #filename(path)
  return vim.tbl_map(function(range)
    local shift = range[2] <= base and #path - base or -(base + 1)
    return { range[1] + shift, range[2] + shift }
  end, ranges)
end

---`source.show` that also highlights filename-first hits, which mini.pick's
---own in-order pass over the shown path cannot find.
---@param buf_id integer
---@param items string[]
---@param query string[]
local function show(buf_id, items, query)
  render.show_paths(buf_id, items, query)

  local chars = query[1] == "*" and vim.list_slice(query, 2) or query
  if #chars == 0 then
    return
  end
  local prompt = table.concat(query)
  local ignorecase = vim.o.ignorecase and not (vim.o.smartcase and prompt ~= prompt:lower())
  if ignorecase then
    chars = vim.tbl_map(string.lower, chars)
  end

  local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
  for i, path in ipairs(items) do
    local offset = #lines[i] - #path -- the icon in front of the path
    for _, range in ipairs(filename_first_ranges(ignorecase and path:lower() or path, chars) or {}) do
      vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, offset + range[1] - 1, {
        end_col = offset + range[2],
        hl_group = "MiniPickMatchRanges",
        hl_mode = "combine",
        priority = 200,
      })
    end
  end
end

-- Exposed for tests: the matcher and the renderer.
M._match = match
M._show = show

---Pick a file.
---
---`<Space>` toggles the preview instead of the global `<M-p>`. A file query
---never contains a space, unlike the prose queries grep and the command
---pickers take, so the key is only free to steal here.
function M.pick()
  local cwd = vim.fn.getcwd()
  return MiniPick.builtin.cli({
    command = M._command(cwd),
    postprocess = M._postprocess,
  }, {
    source = {
      name = "Files (rg)",
      cwd = cwd,
      match = match,
      show = show,
    },
    mappings = { toggle_preview = "<Space>" },
    window = require("plugins.mini-pickers.preview").window(),
  })
end

return M

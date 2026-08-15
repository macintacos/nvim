---Workspace symbol pickers, thinned down.
---
---These stay on `MiniExtra.pickers.lsp` — a workspace query is a location list
---with no tree to recover — but its rows arrive doubly prefixed: Neovim formats
---every symbol as "[Kind] name" (`vim.lsp.util.symbols_to_items`) and mini.extra
---prepends "<path>│<lnum>│<col>│ ". The kind is already carried by the icon and
---the path is what pushes the name off-screen, so both are stripped back out
---and re-hung as annotations.

local kinds = require("plugins.mini-pickers.kinds")
local render = require("plugins.mini-pickers.render")

local M = {}

-- Relative path when the file lives under cwd, otherwise just enough tail to
-- tell two files apart. Plain `pathshorten` is useless on the deep absolute
-- paths workspace symbols return — it yields "/o/h/C/n/0/s/n/r/l/v/_/u/x.lua".
---@param path string
---@return string
local function short_path(path)
  local rel = vim.fn.fnamemodify(path, ":.")
  if rel ~= path and #rel <= 40 then
    return rel
  end
  return "…/" .. vim.fn.fnamemodify(path, ":h:t") .. "/" .. vim.fn.fnamemodify(path, ":t")
end

---Split a mini.extra LSP symbol item into its display parts.
---@param item table
---@return string icon, string hl, string name, string kind
local function symbol_parts(item)
  local ok, icon, hl = pcall(MiniIcons.get, "lsp", item.kind)
  icon = ok and icon or " "
  -- Drop mini.extra's position prefix, or the icon it prepended when there is
  -- no position prefix, then split off Neovim's own "[Kind] " label.
  local raw = item.text:match("^.*│ (.*)$")
  if raw == nil then
    raw = item.text:gsub("^" .. vim.pesc(icon) .. "%s*", "")
  end
  local kind, name = raw:match("^%[([^%]]*)%]%s*(.*)$")
  return icon, (ok and hl or "Normal"), (name or raw), (kind or item.kind or "")
end

---`source.show` for the workspace symbol pickers.
---
---Buffer text is only "<icon> <name>" — the kind and the location are
---right-aligned virtual text. Being virtual keeps them out of the buffer
---entirely, so they read as labels and can never be matched by a query (typing
---"string" won't surface every String-kind symbol).
---@param buf_id integer
---@param items table[]
---@param query string[]
local function show(buf_id, items, query)
  local rows, display = {}, {}
  for i, item in ipairs(items) do
    local icon, hl, name, kind = symbol_parts(item)
    rows[i] = {
      icon = icon,
      hl = hl,
      kind = kind,
      loc = item.path and ("%s:%d"):format(short_path(item.path), item.lnum or 1) or "",
    }
    display[i] = vim.tbl_extend("force", item, { text = icon .. " " .. name })
  end

  MiniPick.default_show(buf_id, display, query)

  -- Colour the kind icon and hang the annotation off the right edge. Runs
  -- after default_show so it layers on top of the query match highlights.
  vim.api.nvim_buf_clear_namespace(buf_id, render.ns, 0, -1)
  for i, row in ipairs(rows) do
    vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, 0, {
      end_col = #row.icon,
      hl_group = row.hl,
      priority = 199,
    })
    local annotation = {}
    if row.loc ~= "" then
      annotation[#annotation + 1] = { row.loc .. "  ", "Comment" }
    end
    if row.kind ~= "" then
      annotation[#annotation + 1] = { row.kind, render.kind_hl(row.kind, row.hl) }
    end
    if #annotation > 0 then
      vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, 0, {
        virt_text = annotation,
        virt_text_pos = "right_align",
        priority = 199,
      })
    end
  end
end

---Build a `source.match` that matches on symbol names alone.
---
---mini.pick derives its match strings from each item's raw `text`, which still
---carries the path and the "[Kind]" label, so both would otherwise be
---queryable. Matching against the cleaned names keeps the query honest.
---@param keep table<string, true>? Kinds to list, or nil to list every kind.
---@return fun(stritems: string[], inds: integer[], query: string[]): integer[]
local function make_match(keep)
  return function(stritems, inds, query)
    local items = MiniPick.get_picker_items() or {}
    local names = {}
    for i, stritem in ipairs(stritems) do
      names[i] = items[i] and select(3, symbol_parts(items[i])) or stritem
    end

    local kept = {}
    for _, i in ipairs(inds) do
      local kind = items[i] and items[i].kind
      if keep == nil or kind == nil or keep[kind] then
        kept[#kept + 1] = i
      end
    end

    -- default_match short-circuits an empty query to *every* stritem, ignoring
    -- the inds we just filtered — which is the picker's opening state, so the
    -- filter has to be returned directly here.
    if #query == 0 then
      return kept
    end
    -- `default_match` only returns nil in its async mode, where it sets the
    -- matches on the picker itself; `sync` always hands them back.
    return MiniPick.default_match(names, kept, query, { sync = true }) --[[@as integer[] ]]
  end
end

---Open a workspace symbol picker.
---@param local_opts table Passed through to `MiniExtra.pickers.lsp`.
---@param scope string The `local_opts.scope` already resolved by the caller.
function M.pick(local_opts, scope)
  local source = { show = show }
  -- The live scope drives its query through `source.match`, so overriding it
  -- would break the search. Its results come from the server already scoped
  -- to the query, which is far less noisy than a whole-file outline anyway.
  if scope ~= "workspace_symbol_live" then
    source.match = make_match(kinds.for_filetype(vim.bo.filetype))
  end
  return MiniExtra.pickers.lsp(local_opts, { source = source })
end

return M

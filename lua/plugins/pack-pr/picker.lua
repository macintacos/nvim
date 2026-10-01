local install = require("plugins.pack-pr.install")
local prs = require("plugins.pack-pr.prs")
local spec = require("plugins.pack-pr.spec")

local M = {}

local ns = vim.api.nvim_create_namespace("pack_pr_picker")

local GAP = "  "

local RESET_LABEL = "default branch"

---Row glyphs, drawn from the nf-md set mini.icons uses and coloured from its palette.
local GLYPHS = {
  pr = { icon = "󰓂", hl = "MiniIconsGreen" },
  reset = { icon = "󰘬", hl = "MiniIconsOrange" },
}

---Resolve a registry `spec_file` to an absolute path. Absolute paths pass
---through (used by tests); relative paths are anchored at the nvim config dir.
---@param spec_file string
---@return string
local function resolve(spec_file)
  if spec_file:sub(1, 1) == "/" then
    return spec_file
  end
  return vim.fs.joinpath(vim.fn.stdpath("config"), spec_file)
end

---Build picker items: one per open PR, plus a "reset to default branch"
---sentinel per managed repo. PRs whose repo is not in `repos` are skipped.
---@param prlist pack-pr.PR[]
---@param repos pack-pr.Repo[]
---@return table[] items Picker items (each carries `text`, `plugin`, `entry`, `branch`, `kind`).
function M._build_items(prlist, repos)
  local by_repo = {}
  for _, r in ipairs(repos) do
    by_repo[r.repo] = r
  end
  local function plugin(r)
    return (r.name:gsub("%.n?vim$", ""))
  end
  local items = {}
  for _, pr in ipairs(prlist) do
    local entry = by_repo[pr.repo]
    if entry then
      items[#items + 1] = {
        text = ("%s #%d %s %s"):format(plugin(entry), pr.number, pr.title, pr.branch),
        plugin = plugin(entry),
        kind = "pr",
        entry = entry,
        branch = pr.branch,
        pr = pr,
      }
    end
  end
  for _, r in ipairs(repos) do
    items[#items + 1] = {
      text = plugin(r) .. " " .. RESET_LABEL,
      plugin = plugin(r),
      kind = "reset",
      entry = r,
      branch = nil,
    }
  end
  return items
end

---Pad `s` with trailing spaces to `width` cells.
---@param s string
---@param width integer
---@return string
local function pad(s, width)
  return s .. (" "):rep(width - vim.fn.strdisplaywidth(s))
end

---Cut `s` to at most `width` cells, ending the cut with an ellipsis.
---@param s string
---@param width integer
---@return string
local function clip(s, width)
  if vim.fn.strdisplaywidth(s) <= width then
    return s
  end
  if width < 1 then
    return ""
  end
  local out = vim.fn.strcharpart(s, 0, width - 1)
  while vim.fn.strdisplaywidth(out) > width - 1 do
    out = vim.fn.strcharpart(out, 0, vim.fn.strchars(out) - 1)
  end
  return out .. "…"
end

---@class pack-pr.Columns
---@field width integer Window width in cells.
---@field plugin integer
---@field number integer Zero when no item is a PR.
---@field branch integer

---Size the table's columns over every item, so they hold still while a query
---narrows the rows. The branch column takes at most a quarter of the window.
---@param items table[] Items from `_build_items`.
---@param width integer
---@return pack-pr.Columns
function M._columns(items, width)
  local columns = { width = width, plugin = 0, number = 0, branch = 0 }
  for _, item in ipairs(items) do
    columns.plugin = math.max(columns.plugin, vim.fn.strdisplaywidth(item.plugin))
    if item.pr then
      columns.number = math.max(columns.number, #tostring(item.pr.number) + 1)
      columns.branch = math.max(columns.branch, vim.fn.strdisplaywidth(item.pr.branch))
    end
  end
  columns.branch = math.min(columns.branch, math.floor(width / 4))
  return columns
end

---@class pack-pr.Row
---@field text string Buffer line: glyph, plugin, PR number and title.
---@field spans { [1]: integer, [2]: integer, [3]: string }[] Byte ranges of `text` and their highlight groups.
---@field branch string? Branch cell to hang off the right edge.

---Lay one item out as a table row. The title gives up cells so the row and its
---branch fit `columns.width`.
---@param item table An item from `_build_items`.
---@param columns pack-pr.Columns
---@return pack-pr.Row
function M._row(item, columns)
  local row = { text = "", spans = {} }
  local function add(s, hl)
    if hl then
      row.spans[#row.spans + 1] = { #row.text, #row.text + #s, hl }
    end
    row.text = row.text .. s
  end

  local glyph = GLYPHS[item.kind]
  add(glyph.icon .. " ", glyph.hl)
  add(pad(item.plugin, columns.plugin) .. GAP)
  if columns.number > 0 then
    local number = item.pr and ("#" .. item.pr.number) or ""
    add((" "):rep(columns.number - #number) .. number .. GAP, "Comment")
  end

  local room = columns.width - vim.fn.strdisplaywidth(row.text)
  if item.pr then
    row.branch = pad(clip(item.pr.branch, columns.branch), columns.branch)
    add(clip(item.pr.title, room - #GAP - columns.branch))
  else
    add(clip(RESET_LABEL, room), "Comment")
  end
  return row
end

---`source.show`: draw the items as a table sized to the picker window.
---@param buf_id integer
---@param items table[]
---@param query string[]
local function show(buf_id, items, query)
  local state = MiniPick.get_picker_state()
  local width = state and vim.api.nvim_win_get_width(state.windows.main) or 80
  local columns = M._columns(MiniPick.get_picker_items() or items, width)
  local rows = vim.tbl_map(function(item)
    return M._row(item, columns)
  end, items)

  MiniPick.default_show(
    buf_id,
    vim.tbl_map(function(row)
      return row.text
    end, rows),
    query
  )

  -- Below default_show's priority-200 match ranges, so typed characters stay marked.
  vim.api.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
  for i, row in ipairs(rows) do
    for _, span in ipairs(row.spans) do
      vim.api.nvim_buf_set_extmark(
        buf_id,
        ns,
        i - 1,
        span[1],
        { end_col = span[2], hl_group = span[3], priority = 199 }
      )
    end
    if row.branch then
      vim.api.nvim_buf_set_extmark(buf_id, ns, i - 1, 0, {
        virt_text = { { row.branch, "Comment" } },
        virt_text_pos = "right_align",
        hl_mode = "combine", -- keep the current row's background under the branch
        priority = 199,
      })
    end
  end
end

---Ask to restart into the freshly installed `target`.
---@param name string
---@param target string
local function offer_restart(name, target)
  if vim.fn.confirm(("pack-pr: %s is on %s. Restart now?"):format(name, target), "&Yes\n&No", 1) == 1 then
    vim.cmd("restart +confirm\\ qall") -- +confirm: modified buffers prompt instead of aborting with E37
    return
  end
  vim.notify(("pack-pr: %s is on %s; restart to load it"):format(name, target), vim.log.levels.INFO)
end

---Apply a selection: rewrite the entry's spec file to track `branch` (or the
---default branch when nil) if needed, install it headlessly, then offer a restart.
---@param entry pack-pr.Repo
---@param branch string?
function M._apply(entry, branch)
  local path = resolve(entry.spec_file)
  if vim.fn.filereadable(path) == 0 then
    vim.notify(("pack-pr: spec file not found: %s"):format(entry.spec_file), vim.log.levels.ERROR)
    return
  end
  local original = table.concat(vim.fn.readfile(path), "\n")
  local rewritten, changed = spec.rewrite(original, entry.src, branch)
  if not changed and not original:find(vim.pesc(entry.src)) then
    vim.notify(("pack-pr: no spec for %s in %s"):format(entry.src, entry.spec_file), vim.log.levels.WARN)
    return
  end
  if changed then
    vim.fn.writefile(vim.split(rewritten, "\n"), path)
  end
  local target = branch or "its default branch"
  vim.notify(("pack-pr: installing %s for %s…"):format(target, entry.name), vim.log.levels.INFO)
  install.run(entry, branch, function(ok, reason)
    if not ok then
      -- Only undo our own rewrite; a later edit or selection may own the file now.
      if changed and table.concat(vim.fn.readfile(path), "\n") == rewritten then
        vim.fn.writefile(vim.split(original, "\n"), path)
      end
      vim.notify(("pack-pr: %s did not reach %s: %s"):format(entry.name, target, reason), vim.log.levels.ERROR)
      return
    end
    offer_restart(entry.name, target)
  end)
end

---Open the PR-branch picker: gather open PRs across `repos`, present them (plus
---a reset sentinel per repo) in a picker, and apply the selection.
---@param repos pack-pr.Repo[]? Defaults to the discovered repos.
function M.open(repos)
  repos = repos or require("plugins.pack-pr").registry()
  if vim.fn.executable("gh") == 0 then
    vim.notify("pack-pr: `gh` not found on PATH", vim.log.levels.ERROR)
    return
  end
  prs.gather(repos, function(prlist, errors)
    for _, err in ipairs(errors) do
      vim.notify(("pack-pr: %s: %s"):format(err.repo, err.message), vim.log.levels.WARN)
    end
    local items = M._build_items(prlist, repos)
    if #items == 0 then
      vim.notify("pack-pr: no matching vim.pack plugins found", vim.log.levels.INFO)
      return
    end
    if #prlist == 0 and #errors == 0 then
      vim.notify("pack-pr: no open PRs found — showing reset options only", vim.log.levels.INFO)
    end
    -- mini.pick matches on each item's `text` field and calls `choose` after
    -- the picker has already closed, so no explicit close is needed here.
    MiniPick.start({
      source = {
        name = "vim.pack PR branches",
        items = items,
        show = show,
        -- Items are plain tables with no `path`, so the default preview would
        -- dump vim.inspect output. Show the PR's own fields instead.
        preview = function(buf_id, item)
          local lines
          if item.kind == "pr" then
            local pr = item.pr
            lines = {
              ("%s #%d"):format(pr.repo, pr.number),
              pr.title,
              "",
              ("branch  %s"):format(pr.branch),
              ("author  @%s"):format(pr.author),
              ("url     %s"):format(pr.url),
            }
          else
            lines = { ("Reset %s to its default branch"):format(item.entry.repo) }
          end
          vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
        end,
        choose = function(item)
          if not item then
            return
          end
          M._apply(item.entry, item.branch)
        end,
      },
    })
  end)
end

return M

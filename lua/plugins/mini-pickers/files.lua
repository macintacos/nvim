---`:Pick files`, listing through `rg` with a few ignored paths added back.

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
  -- `--hidden` reaches dotfiles like `.mise/tasks/` and `.luarc.json`, which
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
      show = function(buf_id, items, query)
        MiniPick.default_show(buf_id, items, query, { show_icons = true })
      end,
    },
    mappings = { toggle_preview = "<Space>" },
  })
end

return M

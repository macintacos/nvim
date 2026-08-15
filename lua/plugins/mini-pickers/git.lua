---Git pickers that neither mini.pick nor mini.extra provides.

local M = {}

-- Same preview/choose shape mini.extra's git_commits uses, so both git pickers
-- behave identically: diff in the preview pane, and choosing one replaces the
-- target window rather than opening somewhere new.
---@param buf_id integer
---@param item string|table
local function show_commit(buf_id, item)
  local hash = type(item) == "string" and item:match("^%x+")
  if not hash then
    return
  end
  vim.bo[buf_id].syntax = "git"
  vim.system(
    { "git", "--no-pager", "show", hash },
    { text = true },
    vim.schedule_wrap(function(res)
      if vim.api.nvim_buf_is_valid(buf_id) then
        vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, vim.split(res.stdout or "", "\n"))
      end
    end)
  )
end

---Commits that touched the line under the cursor.
---
---`-L` restricts the log to a line range and forces patch output, so `-s`
---suppresses it back down to one line per commit; choosing one opens its full
---diff in a scratch tab.
function M.blame_line()
  local path = vim.fn.expand("%:p")
  if path == "" then
    vim.notify("git_blame_line: buffer has no file", vim.log.levels.WARN)
    return
  end
  local lnum = vim.fn.line(".")

  return MiniPick.builtin.cli({
    command = { "git", "log", "-s", "--format=%h %as %an: %s", ("-L%d,%d:%s"):format(lnum, lnum, path) },
  }, {
    source = {
      name = ("Git blame line %d"):format(lnum),
      preview = show_commit,
      choose = function(item)
        local win = (MiniPick.get_picker_state().windows or {}).target
        if win == nil or not vim.api.nvim_win_is_valid(win) then
          return
        end
        local buf_id = vim.api.nvim_create_buf(true, true)
        show_commit(buf_id, item)
        vim.bo[buf_id].filetype = "git"
        vim.api.nvim_win_set_buf(win, buf_id)
      end,
    },
  })
end

return M

-- github.com/esmuellert/codediff.nvim
-- Side-by-side/inline diff viewer with a changed-files explorer, file history,
-- and merge-conflict resolution. Prebuilt C binaries auto-download on first use.
vim.pack.add({ "https://github.com/esmuellert/codediff.nvim" }, { load = false })

-- Lazy-load codediff on the first :CodeDiff. The stub deletes itself, packadds
-- the plugin (which registers the real :CodeDiff), then re-runs the invocation
-- with the original bang/args preserved.
vim.api.nvim_create_user_command("CodeDiff", function(info)
  pcall(vim.api.nvim_del_user_command, "CodeDiff")
  vim.cmd.packadd("codediff.nvim")
  -- Rebind the built-in context-aware keymap-help float from g? to ?. It's a
  -- tab-local map, so ? only shadows backward-search inside codediff tabs.
  require("codediff").setup({ keymaps = { view = { show_help = "?" } } })
  vim.cmd("CodeDiff" .. (info.bang and "!" or "") .. " " .. info.args)
end, { nargs = "*", bang = true, desc = "Lazy-loaded: codediff.nvim" })

local half_down = vim.keycode("<C-d>")
local half_up = vim.keycode("<C-u>")

-- Scroll codediff's diff panes without moving focus out of the picker. The
-- panes are scrollbind-linked, so scrolling the modified window drags the
-- original (and any conflict-result window) with it. No-ops when no diff pane
-- is open yet (e.g. history list before a commit is selected).
local function scroll_diff(term)
  local orig, mod = require("codediff.ui.lifecycle.accessors").get_windows(vim.api.nvim_get_current_tabpage())
  local win = (mod and vim.api.nvim_win_is_valid(mod) and mod) or (orig and vim.api.nvim_win_is_valid(orig) and orig)
  if win then
    vim.api.nvim_win_call(win, function()
      vim.cmd("normal! " .. term)
    end)
  end
end

-- Bind J/K to scroll the diff panes half a page from inside the explorer and
-- history pickers, keeping the cursor put. Fires once per picker buffer when
-- its filetype is set; scheduled so these maps win over the plugin's own
-- buffer-local keymaps applied in the same render tick (this replaces the
-- explorer's default K=hover).
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "codediff-explorer", "codediff-history" },
  desc = "codediff: J/K scroll the diff panes without leaving the picker",
  callback = function(ev)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(ev.buf) then
        return
      end
      vim.keymap.set("n", "J", function()
        scroll_diff(half_down)
      end, { buffer = ev.buf, nowait = true, desc = "CodeDiff scroll diff down" })
      vim.keymap.set("n", "K", function()
        scroll_diff(half_up)
      end, { buffer = ev.buf, nowait = true, desc = "CodeDiff scroll diff up" })
    end)
  end,
})

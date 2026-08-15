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

-- ---------------------------------------------------------------------------
-- Pickers: gather the arguments interactively, then dispatch :CodeDiff. Git
-- calls are synchronous systemlist (tiny commands, no shell), guarded so they
-- degrade to a notify outside a repo instead of erroring.
-- ---------------------------------------------------------------------------

local function dispatch(args)
  vim.cmd("CodeDiff " .. args)
end

local function git_lines(cmd)
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return {}
  end
  return out
end

-- Resolve the repo's base branch: origin/HEAD's target, else the first of
-- main/master/trunk that exists, else "main".
local function default_base()
  local head = git_lines({ "git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD" })[1]
  if head then
    return (head:gsub("^origin/", ""))
  end
  for _, name in ipairs({ "main", "master", "trunk" }) do
    if #git_lines({ "git", "rev-parse", "--verify", "--quiet", name }) > 0 then
      return name
    end
  end
  return "main"
end

-- vim.ui.select with an empty-list guard and cancel handling.
local function ui_select(items, opts, on_choice)
  if vim.tbl_isempty(items) then
    vim.notify("codediff: nothing to pick (not in a git repo?)", vim.log.levels.WARN)
    return
  end
  vim.ui.select(items, opts, function(choice)
    if choice ~= nil then
      on_choice(choice)
    end
  end)
end

local function all_branches()
  local out = {}
  for _, b in
    ipairs(git_lines({
      "git",
      "for-each-ref",
      "--sort=-committerdate",
      "--format=%(refname:short)",
      "refs/heads",
      "refs/remotes",
    }))
  do
    if not b:match("/HEAD$") then
      table.insert(out, b)
    end
  end
  return out
end

-- Ref candidates for the general-purpose picker: branches (recent-first), tags,
-- then the last 20 commits. Each entry carries the ref string and a display label.
local function ref_items()
  local base = default_base()
  local items = {}
  for _, b in ipairs(all_branches()) do
    table.insert(items, { ref = b, label = "branch  " .. b .. (b == base and "  (base)" or "") })
  end
  for _, t in ipairs(git_lines({ "git", "tag", "--sort=-creatordate" })) do
    table.insert(items, { ref = t, label = "tag     " .. t })
  end
  for _, c in ipairs(git_lines({ "git", "log", "--oneline", "--no-decorate", "-n", "20" })) do
    table.insert(items, { ref = c:match("^(%S+)"), label = "commit  " .. c })
  end
  return items
end

local function pick_ref(prompt, on_ref)
  ui_select(ref_items(), {
    prompt = prompt,
    format_item = function(e)
      return e.label
    end,
  }, function(e)
    on_ref(e.ref)
  end)
end

local function pick_branch(prompt, on_branch)
  local branches = all_branches()
  local base = default_base()
  for i, b in ipairs(branches) do
    if b == base then
      table.remove(branches, i)
      table.insert(branches, 1, b)
      break
    end
  end
  ui_select(branches, { prompt = prompt }, on_branch)
end

-- Review the current branch like a PR: only the changes introduced since it
-- forked from the base (git merge-base "..." semantics).
local function review_pr()
  pick_branch("PR base branch", function(base)
    ui_select({
      { label = "All changes (incl. working tree)", spec = base .. "..." },
      { label = "Committed changes only", spec = base .. "...HEAD" },
    }, {
      prompt = "Scope",
      format_item = function(e)
        return e.label
      end,
    }, function(e)
      dispatch(e.spec)
    end)
  end)
end

-- Walk commits one at a time (per-commit diff explorer).
local function review_history()
  ui_select({
    { label = "Recent commits (last 50)", run = "history" },
    { label = "Since base branch (PR range)", branch = true },
    { label = "Current file only", file = true },
  }, {
    prompt = "History",
    format_item = function(e)
      return e.label
    end,
  }, function(e)
    if e.branch then
      pick_branch("PR base branch", function(base)
        dispatch("history " .. base .. "..HEAD")
      end)
    elseif e.file then
      local path = vim.fn.expand("%:p")
      if path == "" then
        vim.notify("codediff: current buffer has no file", vim.log.levels.WARN)
        return
      end
      dispatch("history HEAD~50 " .. vim.fn.fnameescape(path))
    else
      dispatch(e.run)
    end
  end)
end

-- Open the changed-files explorer comparing the working tree to any ref.
local function diff_ref()
  pick_ref("Diff against ref", dispatch)
end

-- Diff just the current buffer against a chosen revision.
local function diff_file_ref()
  if vim.fn.expand("%") == "" then
    vim.notify("codediff: current buffer has no file", vim.log.levels.WARN)
    return
  end
  pick_ref("Diff current file against ref", function(ref)
    dispatch("file " .. ref)
  end)
end

-- Register the <leader>gc "codediff" picker group once plugin/which-key.lua has
-- been sourced. Fires on VimEnter rather than from vim.schedule() because a
-- scheduled callback runs at the next event loop pump, and vim.pack pumps it
-- mid-startup while installing a plugin — at which point which-key.lua (sourced
-- after this file) hasn't run and the group goes unregistered for the session.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    require("which-key").add({
      { "<leader>gc", group = "codediff", icon = { cat = "filetype", name = "git" } },
      { "<leader>gcp", review_pr, desc = "Review branch as PR" },
      { "<leader>gch", review_history, desc = "Commit-by-commit / history" },
      { "<leader>gcr", diff_ref, desc = "Diff against a ref" },
      { "<leader>gcf", diff_file_ref, desc = "Current file vs a ref" },
    })
  end,
})

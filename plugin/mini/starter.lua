---Start screen listing sessions, project actions, worktrees, and recent files.
---@see https://github.com/nvim-mini/mini.starter/blob/main/doc/mini-starter.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.starter", version = "stable" } })

local session_name = require("helpers.sessions").name

local starter = require("mini.starter")

-- The cwd's own session, pinned above every other section. Returns nothing when
-- the project has no session yet. This is a function rather than a table because
-- items are evaluated when the screen is drawn, not when setup() runs — by then
-- the session written by a previous Neovim has been detected.
---@return table[]
local function session_resume_item()
  local name = session_name()
  if not MiniSessions.detected[name] then
    return {}
  end
  return {
    {
      name = "Resume " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":~"),
      action = function()
        MiniSessions.read(name)
      end,
      section = "Resume",
    },
  }
end

---Run git in the cwd, returning trimmed stdout or nil on any failure.
---@param args string[]
---@return string?
local function git(args)
  local ok, res = pcall(function()
    return vim.system(vim.list_extend({ "git" }, args), { text = true }):wait(300)
  end)
  if not ok or res.code ~= 0 then
    return nil
  end
  return vim.trim(res.stdout)
end

-- What is worth reaching for before any file is open: the README, the two
-- pickers, the explorer, and the project switcher — this screen is exactly
-- where you land after realising Neovim opened in the wrong directory.
---@return table[]
local function project_items()
  local items = {
    { name = "Find file", action = MiniPick.registry.files, section = "Project" },
    { name = "Grep", action = MiniPick.registry.grep_live, section = "Project" },
    {
      name = "Explorer",
      action = function()
        MiniFiles.open()
      end,
      section = "Project",
    },
    {
      name = "Switch project",
      action = function()
        require("plugins.projects").open()
      end,
      section = "Project",
    },
  }

  -- Only where there is a repo to look at — lazygit in a non-repo directory
  -- opens on an error prompt.
  if git({ "rev-parse", "--git-dir" }) then
    table.insert(items, {
      name = "Lazygit",
      action = function()
        Snacks.lazygit.open()
      end,
      section = "Project",
    })
  end

  -- README leads when the project has one — the thing most often wanted from a
  -- cold start, and what the auto-session setup used to open on its own.
  local readme = vim.fs.joinpath(vim.fn.getcwd(), "README.md")
  if vim.fn.filereadable(readme) == 1 then
    table.insert(items, 1, {
      name = "Open README",
      action = function()
        vim.cmd.edit(vim.fn.fnameescape(readme))
      end,
      section = "Project",
    })
  end

  return items
end

-- Rendered only when something is actually out of date. The count comes from
-- the disk cache config.pack-updates fills during init; on the first launch
-- after that cache expires the check is still running when this renders, so the
-- item turns up next launch instead. The statusline shows it live either way.
---@return table[]
local function pack_update_item()
  local n = require("config.pack-updates").update_count()
  if n == 0 then
    return {}
  end
  return {
    {
      name = ("Update plugins (%d)"):format(n),
      action = function()
        vim.pack.update()
      end,
      section = "Plugins",
    },
  }
end

-- Distance from the branch this one merges into. The worktree layout already
-- puts the current branch in the directory name, so the useful thing to show is
-- how far it has drifted from the default. Synchronous because `rev-list
-- --count` is ~5ms on a warm repo; the 300ms cap stops a pathological one from
-- stalling startup, and any failure just drops the line.
---@return string?
local function branch_divergence()
  local default = git({ "rev-parse", "--abbrev-ref", "origin/HEAD" })
  if not default then
    return nil
  end
  local counts = git({ "rev-list", "--left-right", "--count", default .. "...HEAD" })
  if not counts then
    return nil
  end
  local behind, ahead = counts:match("(%d+)%s+(%d+)")
  if not behind then
    return nil
  end
  behind, ahead = tonumber(behind), tonumber(ahead)

  if ahead == 0 and behind == 0 then
    return "in sync with " .. default
  end
  local parts = {}
  if ahead > 0 then
    table.insert(parts, "↑" .. ahead)
  end
  if behind > 0 then
    table.insert(parts, "↓" .. behind)
  end
  return table.concat(parts, " ") .. " vs " .. default
end

-- Every other worktree of this repo, most recently used first. The bare repo is
-- skipped (nothing to open) and so is the current worktree (already here).
-- Selecting one only changes the cwd and redraws: its session, if it has one,
-- then leads the refreshed screen as "Resume".
--
-- "Recently used" is the session's write time — when Neovim was last quit in
-- that worktree — falling back to the directory's own mtime for one never
-- opened here.
---@return table[]
local function worktree_items()
  local out = git({ "worktree", "list", "--porcelain" })
  if not out then
    return {}
  end

  -- Porcelain separates worktrees by a blank line, which is what makes the
  -- `bare` marker attributable to the entry it belongs to.
  local cwd = vim.fn.getcwd()
  local paths = {}
  for entry in vim.gsplit(out, "\n\n") do
    local path = entry:match("^worktree ([^\n]+)")
    if path and path ~= cwd and not entry:find("\nbare") then
      table.insert(paths, path)
    end
  end

  local function last_used(path)
    local session = MiniSessions.detected[session_name(path)]
    if session then
      return session.modify_time
    end
    local stat = vim.uv.fs_stat(path)
    return stat and stat.mtime.sec or 0
  end
  table.sort(paths, function(a, b)
    return last_used(a) > last_used(b)
  end)

  local items = {}
  for _, path in ipairs(paths) do
    table.insert(items, {
      -- The layout puts the branch in the directory name, so the tail is the
      -- whole identity — and short enough to filter down to by typing.
      name = vim.fn.fnamemodify(path, ":t"),
      action = function()
        vim.cmd.cd(vim.fn.fnameescape(path))
        starter.refresh()
      end,
      section = "Worktrees",
    })
  end
  return items
end

---@return string
local function starter_header()
  local hour = tonumber(vim.fn.strftime("%H"))
  local part = (hour < 12 and "morning") or (hour < 18 and "afternoon") or "evening"
  local lines = {
    ("Good %s, %s"):format(part, vim.uv.os_get_passwd().username),
    vim.fn.fnamemodify(vim.fn.getcwd(), ":~"),
  }
  local divergence = branch_divergence()
  if divergence then
    lines[#lines] = lines[#lines] .. "  " .. divergence
  end
  return table.concat(lines, "\n")
end

-- mini.starter's default footer spells every key out in <>-notation over six
-- lines. Neither mini.icons nor nvim-web-devicons carries keyboard glyphs —
-- both are filetype/LSP-kind icon sets — so these are the plain Unicode key
-- symbols instead, the same ones macOS prints on its own menus.
--
-- Laid out as a grid: within each column the symbols are right-aligned and the
-- labels left-aligned, so the two rows line up vertically. Widths come from
-- strdisplaywidth rather than `#` because every symbol here is multibyte, and
-- mini.starter's aligning hook derives a single left pad from the widest line
-- and applies it to all of them — so a grid built here survives centering.
-- ⌃n/⌃p and ⌥j/⌥k also move, left out to keep the rows short.
---@return string
local function build_starter_footer()
  local rows = {
    { { "↑↓", "move" }, { "⏎", "open" }, { "⌫", "delete" } },
    { { "⎋", "reset" }, { "⌃c", "close" } },
  }

  local width = vim.fn.strdisplaywidth
  local sym_w, label_w = {}, {}
  for _, row in ipairs(rows) do
    for col, pair in ipairs(row) do
      sym_w[col] = math.max(sym_w[col] or 0, width(pair[1]))
      label_w[col] = math.max(label_w[col] or 0, width(pair[2]))
    end
  end

  local lines = { "󰌌  type to filter" }
  for _, row in ipairs(rows) do
    local cells = {}
    for col, pair in ipairs(row) do
      local sym = string.rep(" ", sym_w[col] - width(pair[1])) .. pair[1]
      local label = pair[2] .. string.rep(" ", label_w[col] - width(pair[2]))
      table.insert(cells, sym .. "  " .. label)
    end
    -- Trailing pad would count toward this line's width and shift the whole
    -- centered block, so it comes off before the line is kept.
    table.insert(lines, (table.concat(cells, "   "):gsub("%s+$", "")))
  end

  return table.concat(lines, "\n")
end

local starter_footer = build_starter_footer()

-- mini.starter only binds the characters listed in `query_updaters`; every
-- other key keeps its normal-mode meaning, which in a nomodifiable buffer means
-- typing the `~` that leads a session path fires the built-in `~` and errors
-- with E21 instead of filtering. The default list is `[a-z0-9_-.]`, far short of
-- what the items here are named after — paths, capitals, parens. So every
-- printable character filters instead, bar `:` and `<Space>`: reaching the
-- command line and the leader-key maps (which-key included) from the start
-- screen is worth more than filtering on a colon no item contains or a space
-- the fuzzy matcher steps over anyway. Queries are matched case-insensitively,
-- so capitals fold in.
local query_updaters = {}
for byte = 33, 126 do
  local char = string.char(byte)
  if char ~= ":" then
    table.insert(query_updaters, char)
  end
end

-- HACK: reaching into mini.starter's private internals to make the query fuzzy.
--
-- mini.starter matches a query against the *start* of an item's name and
-- exposes no hook to change that, so a session named "~/Projects/dotfiles" is
-- only reachable by typing its path from the leading `~`. The module keeps its
-- internals in a file-local `H`, so there is no supported way in — but `H` is
-- upvalue #1 of every public function, and `debug.getupvalue` will hand it over.
--
-- This is exactly as brittle as it looks: it is pinned to two private function
-- names and their signatures, and nothing upstream promises either. It survives
-- only because both replacements are guarded on the fields they need, so a
-- mini.starter that reshapes its internals silently falls back to prefix
-- matching instead of breaking the start screen. Rip all of it out the day
-- upstream takes a matcher hook.
local H = select(2, debug.getupvalue(starter.add_to_query, 1))

if
  type(H) == "table"
  and H.item_is_active
  and H.add_hl_activity
  and H.buf_hl
  and H.position_cursor_on_current_item
  and H.add_hl_current_item
  and H.buffer_data
  and H.ns
then
  -- Vim's own fuzzy matcher: case-insensitive, and it hands back both the
  -- matched byte positions the highlighting needs and the score the cursor
  -- follows. An empty query matches nothing rather than everything, hence the
  -- callers' guards.
  ---@param name string
  ---@param query string Non-empty.
  ---@return integer[]? positions Zero-based byte offsets into `name`, nil when no match.
  ---@return integer? score Higher is a closer match.
  local function fuzzy_match(name, query)
    local res = vim.fn.matchfuzzypos({ name }, query)
    return res[2][1], res[3][1]
  end

  H.item_is_active = function(item, query)
    if item.action == "" then
      return false
    end
    return query == "" or fuzzy_match(item.name, query) ~= nil
  end

  -- The stock version highlights the first #query characters, which is the
  -- match only while matching is by prefix. Fuzzy matches are scattered through
  -- the name, so each matched character is highlighted where it actually landed.
  H.add_hl_activity = function(buf_id, query)
    for _, item in ipairs(H.buffer_data[buf_id].items) do
      if not item._active then
        H.buf_hl(buf_id, H.ns.activity, "MiniStarterInactive", item._line, item._start_col, item._end_col, 53)
      elseif query ~= "" then
        for _, pos in ipairs(fuzzy_match(item.name, query) or {}) do
          local col = item._start_col + pos
          H.buf_hl(buf_id, H.ns.activity, "MiniStarterQuery", item._line, col, col + 1, 53)
        end
      end
    end
  end

  -- Stock mini.starter only moves the cursor once the query makes the current
  -- item inactive, and then only to the next active one down the screen. That
  -- strands the cursor on a scraping match while a far better one sits above
  -- it: with "Foo" and "lololololfoo" both on screen, typing `f` should land on
  -- "Foo" wherever it is. Vim scores the two at 890 against -55, so the cursor
  -- follows the score instead. Ties keep the higher item, which is why the
  -- comparison is strict.
  ---@param buf_id integer
  local function focus_best_match(buf_id)
    local data = H.buffer_data[buf_id]
    if data == nil or data.query == "" then
      return
    end

    local best_id, best_score
    for id, item in ipairs(data.items) do
      if item._active then
        local _, score = fuzzy_match(item.name, data.query)
        if score ~= nil and (best_score == nil or score > best_score) then
          best_id, best_score = id, score
        end
      end
    end
    if best_id == nil or best_id == data.current_item_id then
      return
    end

    -- The tail of MiniStarter.update_current_item, which can only step by one.
    data.current_item_id = best_id
    H.position_cursor_on_current_item(buf_id)
    vim.api.nvim_buf_clear_namespace(buf_id, H.ns.current_item, 0, -1)
    H.add_hl_current_item(buf_id)
  end

  -- The query only ever reaches H.make_query through these two, and both have
  -- placed the cursor by the time they return, so rescoring after them is the
  -- whole hook. Wrapping rather than replacing: everything else they do —
  -- validation, the no-match message, the query echo — still runs.
  local add_to_query, set_query = starter.add_to_query, starter.set_query

  starter.add_to_query = function(char, buf_id)
    add_to_query(char, buf_id)
    focus_best_match(buf_id or vim.api.nvim_get_current_buf())
  end

  starter.set_query = function(query, buf_id)
    set_query(query, buf_id)
    focus_best_match(buf_id or vim.api.nvim_get_current_buf())
  end
end
-- END HACK

-- Sections render in order of first appearance, so "Resume" leads the screen.
starter.setup({
  items = {
    session_resume_item,
    project_items,
    worktree_items,
    starter.sections.recent_files(5, true, false),
    pack_update_item,
    starter.sections.builtin_actions(),
  },
  header = starter_header,
  footer = starter_footer,
  query_updaters = table.concat(query_updaters),
})

---A centered picker over the repo's branches, Local above Remote: switch to one,
---hop to the worktree that holds one, or create one off HEAD.

local refs = require("plugins.branches.refs")

local M = {}

local NS = vim.api.nvim_create_namespace("branches")

---@type table<branches.Kind|"create", string>
local ICONS = {
  current = vim.fn.nr2char(0xF14CF), -- nf-md-source_branch_check
  ["local"] = vim.fn.nr2char(0xF062C), -- nf-md-source_branch
  worktree = vim.fn.nr2char(0xE5FB), -- nf-custom-folder_git_branch
  remote = vim.fn.nr2char(0xF0163), -- nf-md-cloud_outline
  create = vim.fn.nr2char(0xF14CA), -- nf-md-source_branch_plus
}

-- Caps that keep one long name, author, or subject from widening the whole float.
local NAME_MAX, AUTHOR_MAX, SUBJECT_MAX = 40, 16, 50

-- Room for the prompt and the footer's name and count however short the rows are.
local MIN_WIDTH = 40

local GAP = "  "

-- Keeps the rows a cell off the float's border on either side.
local PAD = " "

local HEADERS = { ["local"] = "Local", remote = "Remote" }

-- The top section's header titles the columns after its name, which heads the names.
local TITLES = { track = "Upstream", age = "Updated", author = "Author", subject = "Last commit" }

---@class branches.Item: branches.Branch
---@field kind branches.Kind|"create"
---@field text string What the row's name shows and the query matches; "" on the create row.
---@field track string `↑2 ↓1` against its upstream, `gone`, or "".
---@field age string How long since its last commit.

---@class branches.Widths
---@field name integer
---@field track integer
---@field age integer
---@field author integer

---@class branches.Command
---@field git string[]? Arguments to run git with.
---@field worktree string? A worktree to relaunch Neovim in.

---Run git in Neovim's cwd.
---@param args string[]
---@return string? stdout Nil when git fails.
---@return string? err What git said when it failed.
local function git(args)
  local result = vim.system(vim.list_extend({ "git" }, args), { cwd = vim.fn.getcwd(), text = true }):wait()
  if result.code ~= 0 then
    return nil, vim.trim(result.stderr ~= "" and result.stderr or result.stdout or "")
  end
  return result.stdout
end

---@param b branches.Branch
---@return string
local function track(b)
  if b.gone then
    return "gone"
  end
  local parts = {}
  if b.ahead > 0 then
    parts[#parts + 1] = "↑" .. b.ahead
  end
  if b.behind > 0 then
    parts[#parts + 1] = "↓" .. b.behind
  end
  return table.concat(parts, " ")
end

---A row per branch, then the create row.
---@param branches branches.Branch[]
---@param now integer Unix time the ages count back from.
---@return branches.Item[]
local function rows(branches, now)
  local items = vim.tbl_map(function(b)
    return vim.tbl_extend("force", b, { text = b.name, track = track(b), age = refs.age(now - b.time) })
  end, branches)
  items[#items + 1] = {
    kind = "create",
    text = "",
    name = "",
    ref = "HEAD",
    ahead = 0,
    behind = 0,
    gone = false,
    time = now,
    author = "",
    subject = "",
    track = "",
    age = "",
  }
  return items
end

---@param items branches.Item[]
---@return branches.Widths
local function widths(items)
  ---@type branches.Widths
  -- A section's name starts at the icon, two cells left of the names it heads.
  local w = { name = #HEADERS.remote - 2, track = 0, age = #TITLES.age, author = #TITLES.author }
  for _, item in ipairs(items) do
    w.name = math.max(w.name, vim.api.nvim_strwidth(item.text))
    w.track = math.max(w.track, vim.api.nvim_strwidth(item.track))
    w.age = math.max(w.age, #item.age)
    w.author = math.max(w.author, vim.api.nvim_strwidth(item.author))
  end
  w.name, w.author = math.min(w.name, NAME_MAX), math.min(w.author, AUTHOR_MAX)
  if w.track > 0 then
    w.track = math.max(w.track, #TITLES.track)
  end
  return w
end

---`text` cut to `width` cells, ending in an ellipsis when it had to be cut.
---@param text string
---@param width integer
---@return string
local function fit(text, width)
  if vim.api.nvim_strwidth(text) <= width then
    return text
  end
  return width < 1 and "" or vim.fn.strcharpart(text, 0, width - 1) .. "…"
end

---`text` padded on the right to `width` cells.
---@param text string
---@param width integer
---@return string
local function pad(text, width)
  return text .. (" "):rep(width - vim.api.nvim_strwidth(text))
end

---The upstream, age, and author cells that follow the name column, each padded
---to its width in `w`.
---@param w branches.Widths
---@param upstream string
---@param age string
---@param author string
---@return string
local function columns(w, upstream, age, author)
  local cols = {}
  if w.track > 0 then
    cols[#cols + 1] = pad(upstream, w.track)
  end
  cols[#cols + 1] = (" "):rep(w.age - #age) .. age
  cols[#cols + 1] = pad(fit(author, w.author), w.author)
  return GAP .. table.concat(cols, GAP) .. GAP
end

---The dim columns after a branch's name: its upstream standing, age, author, and
---subject, the subject cut to whatever of `room` the others leave.
---@param item branches.Item
---@param w branches.Widths
---@param room integer Cells left on the row after the name.
---@return string
local function details(item, w, room)
  local head = pad("", w.name - vim.api.nvim_strwidth(item.text)) .. columns(w, item.track, item.age, item.author)
  return head .. fit(item.subject, room - vim.api.nvim_strwidth(head))
end

---The column titles that follow a section's name on its header.
---@param w branches.Widths
---@param name string
---@return string
local function titles(w, name)
  return pad("", 2 + w.name - #name) .. columns(w, TITLES.track, TITLES.age, TITLES.author) .. TITLES.subject
end

---The row that creates a branch, named after the query.
---@param query string
---@return [string, string][]
local function create_label(query)
  if query == "" then
    return { { PAD .. ICONS.create .. " Type a name to create a branch", "Comment" } }
  end
  return { { PAD .. ICONS.create .. " Create branch ", "Comment" }, { query, "MiniPickNormal" } }
end

---`chunks` laid over the current row's band when `here`. mini.pick's band
---starts at the row's first character, which leaves out text drawn before it.
---@param chunks [string, string][]
---@param here boolean
---@return [string, string|string[]][]
local function banded(chunks, here)
  if not here then
    return chunks
  end
  return vim.tbl_map(function(chunk)
    return { chunk[1], { "MiniPickMatchCurrent", chunk[2] } }
  end, chunks)
end

---@param item branches.Item
---@return string
local function section(item)
  return (item.kind == "remote" or item.kind == "create") and item.kind or "local"
end

---Whether a header names `shown[i]`'s section above it while `shown[top]` is
---the top row in view: the top row's section is always named, then each one
---that starts below it.
---@param shown branches.Item[]
---@param i integer
---@param top integer
---@return boolean
local function headed(shown, i, top)
  local sec = section(shown[i] --[[@as branches.Item]])
  if HEADERS[sec] == nil or i < top then
    return false
  end
  return i == top or sec ~= section(shown[i - 1] --[[@as branches.Item]])
end

---The row to scroll to the top of the window: the first, unless the section
---headers would push the current row out of view, then the first that keeps
---it in view.
---@param shown branches.Item[]
---@param current integer Index of the current row in `shown`.
---@param height integer Rows in the window.
---@return integer
function M._top(shown, current, height)
  local function fits(top)
    local used = 0
    for i = top, current do
      used = used + 1 + (headed(shown, i, top) and 1 or 0)
    end
    return used <= height
  end
  local top = 1
  while top < current and not fits(top) do
    top = top + 1
  end
  return top
end

---`source.show`: mini.pick's own rendering of the names, then the column
---titles, section headers, icons, and each branch's details around them.
---@param items branches.Item[] Every row the picker holds, which sizes the columns.
---@return fun(buf: integer, shown: branches.Item[], query: string[])
function M._show(items)
  local w = widths(items)
  ---@param buf integer
  ---@param shown branches.Item[]
  ---@param query string[]
  return function(buf, shown, query)
    MiniPick.default_show(buf, shown, query)
    vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
    local win = vim.fn.bufwinid(buf)
    if win == -1 or #shown == 0 then
      return
    end
    vim.wo[win].conceallevel = 2
    -- The picker's cursor sits on the current row, which would otherwise show its name uncut.
    vim.wo[win].concealcursor = "nvic"
    local width = vim.api.nvim_win_get_width(win)

    local current, at = (MiniPick.get_picker_matches() or {}).current, 1
    for i, item in ipairs(shown) do
      at = item == current and i or at
    end

    ---The icon, the dimmed remote, the cut, and the details around one row's
    ---name; or the create row's label.
    ---@param row integer
    ---@param item branches.Item
    local function decorate(row, item)
      -- Under mini.pick's match (200) and current row (201) marks, so both still show.
      local mark = { priority = 199, hl_mode = "combine", virt_text_pos = "inline" }
      local here = item == current
      if item.kind == "create" then
        local label = banded(create_label(table.concat(MiniPick.get_picker_query() or {})), here)
        vim.api.nvim_buf_set_extmark(buf, NS, row, 0, vim.tbl_extend("force", mark, { virt_text = label }))
        return
      end
      local icon = { PAD .. ICONS[item.kind] .. " ", item.kind == "current" and "MiniPickBranchCurrent" or "Comment" }
      vim.api.nvim_buf_set_extmark(
        buf,
        NS,
        row,
        0,
        vim.tbl_extend("force", mark, { virt_text = banded({ icon }, here) })
      )
      local remote = item.kind == "remote" and item.text:match("^[^/]+/")
      if remote then
        vim.api.nvim_buf_set_extmark(buf, NS, row, 0, { end_col = #remote, hl_group = "Comment", priority = 199 })
      end
      local name = vim.api.nvim_strwidth(item.text)
      if name > w.name then
        -- mini.pick shows the text it matches, so a long name is hidden past its
        -- column rather than shortened.
        local cut = #vim.fn.strcharpart(item.text, 0, w.name - 1)
        vim.api.nvim_buf_set_extmark(buf, NS, row, cut, {
          end_col = #item.text,
          conceal = "…",
          hl_group = "Comment",
          priority = 199,
        })
      end
      local room = width - 2 * #PAD - 2 - math.min(name, w.name)
      local details_mark = { virt_text = { { details(item, w, room), "Comment" } } }
      vim.api.nvim_buf_set_extmark(buf, NS, row, #item.text, vim.tbl_extend("force", mark, details_mark))
    end

    local top = M._top(shown, at, vim.api.nvim_win_get_height(win))
    for i, item in ipairs(shown) do
      if headed(shown, i, top) then
        local name = HEADERS[section(item)] --[[@as string]]
        local header = { { PAD .. name, "MiniPickHeader" }, { i == top and titles(w, name) or "", "Comment" } }
        vim.api.nvim_buf_set_extmark(buf, NS, i - 1, 0, { virt_lines = { header }, virt_lines_above = true })
      end
      decorate(i - 1, item)
    end

    -- mini.pick fills the buffer to the window's height, so the headers push the
    -- last few rows out of view; left to Neovim, reaching one scrolls the titles away.
    vim.api.nvim_win_call(win, function()
      vim.fn.winrestview({ topline = top, topfill = headed(shown, top, top) and 1 or 0 })
    end)
  end
end

---`source.match`: mini.pick's fuzzy match over the branches, regrouped so the
---Local section stays above Remote, then the create row unless the query already
---names a local branch.
---@param items branches.Item[]
---@return fun(stritems: string[], inds: integer[], query: string[]): integer[]
function M._match(items)
  local create = #items
  return function(stritems, inds, query)
    local candidates = vim.tbl_filter(function(i)
      return i ~= create
    end, inds)
    local found = MiniPick.default_match(stritems, candidates, query, { sync = true }) or {}
    local out = {}
    for _, wanted in ipairs({ "local", "remote" }) do
      for _, i in ipairs(found) do
        if section(items[i]) == wanted then
          out[#out + 1] = i
        end
      end
    end
    local typed = table.concat(query)
    for i, item in ipairs(items) do
      if section(item) == "local" and stritems[i] == typed then
        return out
      end
    end
    out[#out + 1] = create
    return out
  end
end

---What choosing `item` does, given the query typed when it was chosen.
---@param item branches.Item
---@param query string
---@return branches.Command? command Nil when there is nothing to do.
function M._command(item, query)
  if item.kind == "current" or (item.kind == "create" and query == "") then
    return nil
  elseif item.kind == "create" then
    return { git = { "switch", "-c", query } }
  elseif item.kind == "worktree" then
    return { worktree = item.worktree }
  elseif item.kind == "remote" then
    return { git = { "switch", "--track", item.name } }
  end
  return { git = { "switch", item.name } }
end

---The row the picker starts on: the branch checked out before this one, else
---the newest branch other than the current one.
---@param items branches.Item[]
---@param previous string? Full refname of `@{-1}`, the branch checked out before this one.
---@return integer
function M._start(items, previous)
  for i, item in ipairs(items) do
    if item.ref == previous and item.kind ~= "current" then
      return i
    end
  end
  local first = items[1]
  return first and first.kind == "current" and 2 or 1
end

---Warn and return false while a file buffer holds unsaved changes, which a
---switch would leave describing the wrong branch's files.
---@return boolean
local function all_saved()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == "" and vim.bo[buf].modified then
      vim.notify("branches: save or discard your unsaved changes first", vim.log.levels.WARN)
      return false
    end
  end
  return true
end

---@param command branches.Command
local function run(command)
  if command.worktree then
    require("plugins.projects").switch(command.worktree)
    return
  end
  local _, err = git(assert(command.git, "a command without a worktree runs git"))
  if err then
    vim.notify("branches: " .. err, vim.log.levels.ERROR)
    return
  end
  vim.cmd.checktime()
end

---@param item branches.Item
---@return boolean? keep_open
local function choose(item)
  local command = M._command(item, table.concat(MiniPick.get_picker_query() or {}))
  if not command then
    -- An empty create row has nothing to name the branch, so wait for typing.
    return item.kind == "create"
  end
  -- After the picker closes, so a refusal or git's error isn't drawn under it.
  vim.schedule(function()
    if (item.kind == "local" or item.kind == "remote") and not all_saved() then
      return
    end
    run(command)
  end)
end

---`source.preview`: the branch's recent commits; the create row's are HEAD's,
---which the new branch starts from.
---@param buf integer
---@param item branches.Item
local function preview(buf, item)
  local out, err = git({ "log", "--format=%h %s", "-n", "100", item.ref })
  local lines = vim.split(vim.trim(out or err or ""), "\n")
  if item.worktree then
    table.insert(lines, 1, "Checked out in " .. vim.fn.fnamemodify(item.worktree, ":~"))
  end
  -- A cell in, as the list's rows are.
  local padded = vim.tbl_map(function(line)
    return PAD .. line
  end, lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, padded)
  for i, line in ipairs(lines) do
    local hash = out and line:match("^%x+ ")
    if hash then
      vim.api.nvim_buf_set_extmark(buf, NS, i - 1, #PAD, { end_col = #PAD + #hash - 1, hl_group = "Comment" })
    end
  end
  if item.worktree then
    vim.api.nvim_buf_set_extmark(buf, NS, 0, 0, { end_col = #padded[1], hl_group = "Comment" })
  end
end

---The picker's float: centered, wide enough for the details, one line per row
---and section header.
---@param items branches.Item[]
---@return vim.api.keyset.win_config
local function window(items)
  local w = widths(items)
  local subject, headers = #TITLES.subject, {}
  for _, item in ipairs(items) do
    subject = math.max(subject, vim.api.nvim_strwidth(item.subject))
    headers[section(item)] = HEADERS[section(item)]
  end
  local natural = 2 * #PAD + 2 + w.name + vim.api.nvim_strwidth(columns(w, "", "", "")) + math.min(subject, SUBJECT_MAX)
  local width = math.min(math.max(natural, MIN_WIDTH), math.floor(0.8 * vim.o.columns))
  local height = math.min(#items + vim.tbl_count(headers), math.floor(0.6 * vim.o.lines))
  return {
    anchor = "NW",
    row = math.floor((vim.o.lines - height - 2) / 2),
    col = math.floor((vim.o.columns - width - 2) / 2),
    width = width,
    height = height,
  }
end

---Pick a branch to switch to, or name one to create.
function M.pick()
  local out, err = git(refs.ARGS)
  if not out then
    vim.notify("branches: " .. err, vim.log.levels.ERROR)
    return
  end
  local items = rows(refs.parse(out), os.time())
  local start = M._start(items, vim.trim(git({ "rev-parse", "--symbolic-full-name", "@{-1}" }) or ""))
  -- Starts the picker on the branch you came from, so <CR> flips back to it.
  -- Fires once, as the picker comes up: the first moment its selection can be set.
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniPickStart",
    once = true,
    callback = function()
      MiniPick.set_picker_match_inds({ start }, "current")
    end,
  })
  MiniPick.start({
    source = {
      name = "Branches",
      items = items,
      match = M._match(items),
      show = M._show(items),
      preview = preview,
      choose = choose,
    },
    window = { config = window(items) },
  })
end

return M

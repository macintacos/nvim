local changeset = require("plugins.changeset")
local window = require("plugins.changeset.window")
local Fixture = require("support.git")

---@param count integer
---@param changed table<integer, true>? Lines to rewrite.
---@return string[]
local function numbered(count, changed)
  local lines = {}
  for i = 1, count do
    lines[i] = (changed or {})[i] and ("changed " .. i) or ("line " .. i)
  end
  return lines
end

---A `feature` branch changing lines 2 and 8 of `mod.lua` and the last of `other.lua`,
---beside a `plain.lua` it leaves alone. No server answers in the specs, so every
---hunk is an orphan: `mod.lua` → "Other changes" → L2, L8.
---@param cwd string
local function init_feature_repo(cwd)
  Fixture.init_repo("trunk", cwd)
  vim.fn.writefile(numbered(10), "mod.lua")
  vim.fn.writefile({ "local a = 1", "", "return 1" }, "other.lua")
  vim.fn.writefile({ "return 0" }, "plain.lua")
  Fixture.commit("base", cwd)

  Fixture.git({ "checkout", "-q", "-b", "feature" }, cwd)
  vim.fn.writefile(numbered(10, { [2] = true, [8] = true }), "mod.lua")
  vim.fn.writefile({ "local a = 1", "", "return 2" }, "other.lua")
  Fixture.commit("change", cwd)
end

---@return string[]
local function sidebar_lines()
  return vim.api.nvim_buf_get_lines(assert(window.buf()), 0, -1, false)
end

---Wait for the tree to hold both files with every file's symbols read.
local function settle()
  local settled = vim.wait(10000, function()
    local text = window.buf() and table.concat(sidebar_lines(), "\n") or ""
    return text:find("other.lua", 1, true) and not text:find("reading symbols", 1, true)
  end, 25)
  assert(settled, "the sidebar never settled")
end

---Let the scheduled tracking run.
local function flush()
  local flushed = false
  vim.schedule(function()
    flushed = true
  end)
  vim.wait(1000, function()
    return flushed
  end)
end

---Put the sidebar's cursor on the first line containing `text`, as `j`/`k` would.
---@param text string
local function sidebar_cursor_to(text)
  vim.api.nvim_set_current_win(window.win())
  for i, line in ipairs(sidebar_lines()) do
    if line:find(text, 1, true) then
      vim.api.nvim_win_set_cursor(0, { i, 0 })
      vim.api.nvim_exec_autocmds("CursorMoved", { buffer = window.buf() })
      return
    end
  end
  error("no sidebar line contains " .. text)
end

---Move focus into a new terminal split.
local function focus_terminal()
  vim.cmd("new")
  vim.cmd.terminal()
end

describe("changeset position in a session", function()
  local tmp, previous_dir

  -- The tree resolves its repo from the current buffer, which falls back to the
  -- process cwd, and the fixture writes relative paths, so it has to be entered.
  before_each(function()
    tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp, "p")
    previous_dir = vim.fn.chdir(tmp)
    assert(previous_dir ~= "", "could not enter the fixture directory")
    init_feature_repo(tmp)
    vim.g.ChangesetPosition = nil
  end)

  after_each(function()
    changeset.close()
    vim.cmd("silent! only")
    vim.cmd("silent! %bwipeout!")
    vim.fn.chdir(previous_dir)
    vim.fn.delete(tmp, "rf")
    vim.g.ChangesetPosition = nil
  end)

  it("keeps where you are while focus sits in a terminal", function()
    vim.cmd.edit("mod.lua")
    vim.api.nvim_win_set_cursor(0, { 8, 0 })
    changeset.open()
    settle()

    focus_terminal()

    flush()

    assert.same({ path = "mod.lua", lnum = 8 }, changeset._tree().here)
  end)

  it("records where you are and the sidebar's cursor row in a session global", function()
    vim.cmd.edit("mod.lua")
    vim.api.nvim_win_set_cursor(0, { 8, 0 })
    changeset.open()
    settle()

    sidebar_cursor_to("other.lua")
    flush()

    assert.same({ here = { path = "mod.lua", lnum = 8 }, row = "other.lua" }, vim.json.decode(vim.g.ChangesetPosition))
  end)
end)

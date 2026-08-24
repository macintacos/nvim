---Actions that put something on the `+` register: file paths, git metadata for
---the line under the cursor, and remote links to it.
---
---Everything here is a ready-to-map, zero-argument function so `which-key`'s
---spec stays a list of names rather than a list of closures.

local Paths = require("helpers.paths")

local M = {}

---Run git in `cwd`, returning stdout on success.
---@param args string[] Arguments following `git -C <cwd>`.
---@param cwd string Directory to run git in.
---@return string? stdout nil when git exits non-zero.
local function git(args, cwd)
  local cmd = { "git", "-C", cwd }
  vim.list_extend(cmd, args)
  local result = vim.system(cmd, { text = true }):wait()
  return result.code == 0 and result.stdout or nil
end

---@class helpers.yank.Blame
---@field sha string      Full commit SHA.
---@field author string   Author name.
---@field time integer    Author time, as a Unix timestamp.
---@field summary string  Commit subject line.

---Parse `git blame --porcelain` output covering a single line.
---
---The header line is `<sha> <orig-line> <final-line> <count>`; the fields that
---follow are `key value` pairs. An all-zero SHA is git's marker for a line that
---is not committed yet. Matching the line numbers too keeps git's error output
---(`fatal: ...`) from reading as a short SHA.
---@param out string Raw porcelain output.
---@return helpers.yank.Blame? blame nil when the line has no commit.
local function parse_blame(out)
  local sha = out:match("^(%x+) %d+ %d+")
  if not sha or sha:match("^0+$") then
    return nil
  end
  return {
    sha = sha,
    -- The trailing space keeps these off `author-mail` and `committer`.
    author = out:match("\nauthor ([^\n]+)") or "",
    time = tonumber(out:match("\nauthor%-time (%d+)")) or 0,
    summary = out:match("\nsummary ([^\n]+)") or "",
  }
end

---Blame the cursor line of the current buffer, reporting why when it can't.
---@return helpers.yank.Blame?
local function blame_line()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Buffer has no file", vim.log.levels.WARN)
    return nil
  end
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local range = ("%d,%d"):format(lnum, lnum)
  local out = git({ "blame", "--porcelain", "-L", range, "--", file }, vim.fs.dirname(file))
  local blame = out and parse_blame(out)
  if not blame then
    vim.notify("No commit for this line", vim.log.levels.WARN)
  end
  return blame
end

-- gitbrowse ships no blame pattern. Its per-call options are deep-merged into
-- the defaults, so adding this one key leaves the built-in kinds intact.
local BLAME_PATTERN = {
  url_patterns = {
    ["github%.com"] = { blame = "/blame/{branch}/{file}#L{line_start}-L{line_end}" },
  },
}

---Build a remote URL with snacks.gitbrowse and hand it to `sink` rather than
---opening a browser.
---@param what string Key into gitbrowse's `url_patterns` — "file", "commit", "permalink", "repo", "branch", or "blame".
---@param opts table? Extra snacks.gitbrowse options.
---@param sink fun(url: string) Receives the finished URL.
local function browse(what, opts, sink)
  require("snacks").gitbrowse(vim.tbl_deep_extend("force", {
    what = what,
    notify = false,
    -- Given no commit, gitbrowse probes the word under the cursor and aborts
    -- when it reads as a SHA but isn't one — a hex colour literal, say. Only
    -- "permalink" needs a commit resolved, so skip the probe everywhere else;
    -- none of those patterns interpolate {commit}.
    commit = what ~= "permalink" and "" or nil,
    open = sink,
  }, opts or {}))
end

---Copy the URL that `what` names.
---@param what string
---@param opts table? Extra snacks.gitbrowse options.
---@param label string Short description for the notification.
---@return fun()
local function link_action(what, opts, label)
  return function()
    browse(what, opts, function(url)
      Paths.copy(url, label)
    end)
  end
end

---Copy one field of the cursor line's blame.
---@param field fun(blame: helpers.yank.Blame): string
---@param label string Short description for the notification.
---@return fun()
local function blame_action(field, label)
  return function()
    local blame = blame_line()
    if blame then
      Paths.copy(field(blame), label)
    end
  end
end

---Copy the trimmed output of a git command run at the project root.
---@param args string[] Arguments following `git -C <root>`.
---@param label string Short description for the notification.
---@return fun()
local function git_action(args, label)
  return function()
    local out = git(args, Paths.root(0))
    Paths.copy(out and vim.trim(out), label)
  end
end

---Copy the current buffer's path under `opts`.
---@param opts helpers.paths.Opts
---@param label string Short description for the notification.
---@return fun()
local function path_action(opts, label)
  return function()
    Paths.copy(Paths.path(0, opts), label)
  end
end

---Copy one path per buffer that `bufs` yields, newline-separated.
---@param bufs fun(): integer[]
---@param opts helpers.paths.Opts
---@param label string Short description for the notification.
---@return fun()
local function list_action(bufs, opts, label)
  return function()
    Paths.copy(
      vim.tbl_map(function(buf)
        return Paths.path(buf, opts)
      end, bufs()),
      label
    )
  end
end

-- Paths of the current buffer.
M.rel_path = path_action({}, "relative path")
M.abs_path = path_action({ absolute = true }, "absolute path")
M.rel_line = path_action({ with_line = true }, "relative path:line")
M.abs_line = path_action({ absolute = true, with_line = true }, "absolute path:line")
M.filename = path_action({ basename = true }, "filename")
M.rel_dir = path_action({ dir_only = true }, "relative dir")
M.abs_dir = path_action({ absolute = true, dir_only = true }, "absolute dir")

-- Paths of several buffers at once.
M.window_paths = list_action(Paths.tab_window_buffers, {}, "relative paths")
M.window_paths_abs = list_action(Paths.tab_window_buffers, { absolute = true }, "absolute paths")
M.buffer_paths = list_action(Paths.listed_buffers, {}, "relative paths")
M.buffer_paths_abs = list_action(Paths.listed_buffers, { absolute = true }, "absolute paths")

-- The commit behind the cursor line.
M.commit_hash = blame_action(function(blame)
  return blame.sha:sub(1, 8)
end, "commit hash")
M.commit_hash_full = blame_action(function(blame)
  return blame.sha
end, "full commit hash")
M.commit_date = blame_action(function(blame)
  return os.date("%Y-%m-%d", blame.time) --[[@as string]]
end, "commit date")
M.commit_author = blame_action(function(blame)
  return blame.author
end, "commit author")
M.commit_summary = blame_action(function(blame)
  return blame.summary
end, "commit subject")

-- Remote links.
M.gh_file = link_action("file", nil, "file link")
M.gh_permalink = link_action("permalink", nil, "permalink")
M.gh_blame = link_action("blame", BLAME_PATTERN, "blame link")
M.gh_repo = link_action("repo", nil, "repo link")

-- The repository's current state.
M.head_sha = git_action({ "rev-parse", "HEAD" }, "HEAD sha")
M.branch = git_action({ "rev-parse", "--abbrev-ref", "HEAD" }, "branch")

---Copy a link to the commit that last touched the cursor line.
function M.gh_commit()
  local blame = blame_line()
  if blame then
    browse("commit", { commit = blame.sha }, function(url)
      Paths.copy(url, "commit link")
    end)
  end
end

---Copy a markdown link labelled `path:line`, pointing at a permalink.
function M.markdown_link()
  local label = Paths.path(0, { with_line = true })
  if not label then
    vim.notify("Buffer has no file", vim.log.levels.WARN)
    return
  end
  browse("permalink", nil, function(url)
    Paths.copy(("[%s](%s)"):format(label, url), "markdown link")
  end)
end

---Copy the whole buffer's text.
function M.buffer_text()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  -- Joined here rather than handed over as a list: `Paths.copy` drops empty
  -- entries, which would swallow the buffer's blank lines.
  Paths.copy(table.concat(lines, "\n"), "buffer text")
end

---Copy the working directory.
function M.cwd()
  Paths.copy(vim.fs.normalize(assert(vim.uv.cwd())), "working directory")
end

---Copy the diagnostic messages on the cursor line.
function M.diagnostics()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  Paths.copy(
    vim.tbl_map(function(diagnostic)
      return diagnostic.message
    end, vim.diagnostic.get(0, { lnum = lnum })),
    "diagnostics"
  )
end

-- Exposed for unit tests.
M._parse_blame = parse_blame

return M

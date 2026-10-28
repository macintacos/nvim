---Reads the repo's branches out of `git for-each-ref`.

local M = {}

---@alias branches.Kind "current"|"local"|"worktree"|"remote"

---@class branches.Branch
---@field kind branches.Kind `worktree` is a local branch checked out in another worktree.
---@field name string What `git switch` takes: the local name, or `<remote>/<branch>`.
---@field ref string The full refname, such as `refs/heads/trunk`.
---@field worktree string? Where a `worktree` branch is checked out.
---@field ahead integer Commits it has that its upstream lacks.
---@field behind integer Commits its upstream has that it lacks.
---@field gone boolean Whether its upstream was deleted.
---@field time integer Unix time of its last commit.
---@field author string
---@field subject string

local FIELDS = {
  "%(refname)",
  "%(refname:lstrip=2)",
  "%(refname:lstrip=3)",
  "%(HEAD)",
  "%(worktreepath)",
  "%(upstream:track,nobracket)",
  "%(committerdate:unix)",
  "%(authorname)",
  "%(subject)",
}

-- Newest first, so each section lists its branches by recency. Fields split on
-- the unit separator (`%1f`): Vimscript's system() mangles a NUL.
---@type string[]
M.ARGS =
  { "for-each-ref", "--sort=-committerdate", "--format=" .. table.concat(FIELDS, "%1f"), "refs/heads", "refs/remotes" }

---@param refname string
---@param head string `*` on the branch checked out here.
---@param worktree string Where the branch is checked out, or "".
---@return branches.Kind
local function kind(refname, head, worktree)
  if refname:find("^refs/remotes/") then
    return "remote"
  elseif head == "*" then
    return "current"
  elseif worktree ~= "" then
    return "worktree"
  end
  return "local"
end

---@param digits string?
---@return integer
local function int(digits)
  return math.floor(tonumber(digits) or 0)
end

---@param line string One line of `M.ARGS`' output.
---@return branches.Branch
---@return string branch A remote ref's branch, without its remote.
local function branch(line)
  local f = vim.split(line, "\31", { plain = true }) --[[@as [string, string, string, string, string, string, string, string, string] ]]
  local track = f[6]
  local k = kind(f[1], f[4], f[5])
  return {
    kind = k,
    name = f[2],
    ref = f[1],
    worktree = k == "worktree" and f[5] or nil,
    ahead = int(track:match("ahead (%d+)")),
    behind = int(track:match("behind (%d+)")),
    gone = track == "gone",
    time = int(f[7]),
    author = f[8],
    subject = f[9],
  },
    f[3]
end

---The current branch, the other local branches, then the remote branches no local
---branch shares a name with.
---@param output string Stdout of `git` run with `M.ARGS`.
---@return branches.Branch[]
function M.parse(output)
  local listed, remotes, taken = {}, {}, {}
  for _, line in ipairs(vim.split(output, "\n", { trimempty = true })) do
    local b, remote_branch = branch(line)
    if b.kind == "remote" then
      remotes[#remotes + 1] = { b, remote_branch }
    else
      taken[b.name] = true
      table.insert(listed, b.kind == "current" and 1 or #listed + 1, b)
    end
  end
  for _, r in ipairs(remotes) do
    if r[2] ~= "HEAD" and not taken[r[2]] then
      listed[#listed + 1] = r[1]
    end
  end
  return listed
end

local UNITS = { { 31536000, "y" }, { 2592000, "mo" }, { 604800, "w" }, { 86400, "d" }, { 3600, "h" }, { 60, "m" } }

---How long `seconds` is, in the largest whole unit: `3h`, `2d`, `4mo`.
---@param seconds integer
---@return string
function M.age(seconds)
  for _, unit in ipairs(UNITS) do
    if seconds >= unit[1] then
      return math.floor(seconds / unit[1]) .. unit[2]
    end
  end
  return "now"
end

return M

local M = {}

---@class pack-pr.PR
---@field repo string The "owner/repo" the PR belongs to.
---@field number integer The PR number.
---@field title string The PR title.
---@field branch string The PR head branch (`headRefName`).
---@field author string The PR author's login, or "?" when unknown.
---@field url string The PR's web URL.

---Parse `gh pr list --json number,title,headRefName,author,url` output for one
---repo into PR rows. Empty, nil, or unparseable input yields an empty list, so
---callers can aggregate across repos without special-casing failures.
---@param json string? Raw stdout from `gh` (a JSON array).
---@param repo string The "owner/repo" the PRs belong to.
---@return pack-pr.PR[]
function M.parse(json, repo)
  if not json or json == "" then
    return {}
  end
  local ok, decoded = pcall(vim.json.decode, json)
  if not ok or type(decoded) ~= "table" then
    return {}
  end
  local prs = {}
  for _, pr in ipairs(decoded) do
    prs[#prs + 1] = {
      repo = repo,
      number = pr.number,
      title = pr.title,
      branch = pr.headRefName,
      author = pr.author and pr.author.login or "?",
      url = pr.url,
    }
  end
  return prs
end

---Spawn `gh pr list` for one repo and pass the vim.system result to `cb`.
---@param repo string The "owner/repo" gh query target.
---@param cb fun(res: table) Receives a vim.system completion (code/stdout/stderr).
local function default_runner(repo, cb)
  vim.system(
    { "gh", "pr", "list", "--repo", repo, "--json", "number,title,headRefName,author,url" },
    { text = true },
    vim.schedule_wrap(function(res)
      cb(res)
    end)
  )
end

local runner = default_runner

---Run `gh` for every repo and aggregate their open PRs. A non-zero exit is
---collected as a per-repo error rather than aborting the whole gather, so one
---unauthenticated or empty repo never blocks the others. The callback fires
---once, after every repo has reported.
---@param repos pack-pr.Repo[]
---@param cb fun(prs: pack-pr.PR[], errors: { repo: string, message: string }[])
function M.gather(repos, cb)
  local prs, errors = {}, {}
  local remaining = #repos
  if remaining == 0 then
    cb(prs, errors)
    return
  end
  for _, repo in ipairs(repos) do
    runner(repo.repo, function(res)
      if res.code == 0 then
        vim.list_extend(prs, M.parse(res.stdout, repo.repo))
      else
        local stderr = vim.trim(res.stderr or "")
        errors[#errors + 1] = {
          repo = repo.repo,
          message = stderr ~= "" and stderr or ("gh exited " .. tostring(res.code)),
        }
      end
      remaining = remaining - 1
      if remaining == 0 then
        cb(prs, errors)
      end
    end)
  end
end

---Override the gh runner (test seam).
---@param fn fun(repo: string, cb: fun(res: table))
function M._set_runner(fn)
  runner = fn
end

---Restore the default gh runner (test seam).
function M._reset()
  runner = default_runner
end

return M

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

return M

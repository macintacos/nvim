local prs = require("plugins.pack-pr.prs")
local spec = require("plugins.pack-pr.spec")

local M = {}

---Resolve a registry `spec_file` to an absolute path. Absolute paths pass
---through (used by tests); relative paths are anchored at the nvim config dir.
---@param spec_file string
---@return string
local function resolve(spec_file)
  if spec_file:sub(1, 1) == "/" then
    return spec_file
  end
  return vim.fs.joinpath(vim.fn.stdpath("config"), spec_file)
end

---Build picker items: one per open PR, plus a "reset to default branch"
---sentinel per managed repo. PRs whose repo is not in `repos` are skipped.
---@param prlist pack-pr.PR[]
---@param repos pack-pr.Repo[]
---@return table[] items Snacks picker items (each carries `entry`, `branch`, `kind`).
function M._build_items(prlist, repos)
  local by_repo = {}
  for _, r in ipairs(repos) do
    by_repo[r.repo] = r
  end
  local items = {}
  for _, pr in ipairs(prlist) do
    local entry = by_repo[pr.repo]
    if entry then
      items[#items + 1] = {
        text = string.format("%s #%d %s  %s  @%s", pr.repo, pr.number, pr.title, pr.branch, pr.author),
        kind = "pr",
        entry = entry,
        branch = pr.branch,
        pr = pr,
      }
    end
  end
  for _, r in ipairs(repos) do
    items[#items + 1] = {
      text = string.format("reset %s → default branch", r.repo),
      kind = "reset",
      entry = r,
      branch = nil,
    }
  end
  return items
end

---Apply a selection: rewrite the entry's spec file to track `branch` (or reset
---to the default branch when nil), then refresh the plugin via vim.pack.update.
---@param entry pack-pr.Repo
---@param branch string?
function M._apply(entry, branch)
  local path = resolve(entry.spec_file)
  if vim.fn.filereadable(path) == 0 then
    vim.notify(("pack-pr: spec file not found: %s"):format(entry.spec_file), vim.log.levels.ERROR)
    return
  end
  local content = table.concat(vim.fn.readfile(path), "\n")
  local new, changed = spec.rewrite(content, entry.src, branch)
  if not changed then
    -- No write needed: either the source isn't in this file, or it already
    -- matches the target state (e.g. resetting a spec already on default).
    if content:find(vim.pesc(entry.src)) then
      vim.notify(("pack-pr: %s already up to date"):format(entry.name), vim.log.levels.INFO)
    else
      vim.notify(("pack-pr: no spec for %s in %s"):format(entry.src, entry.spec_file), vim.log.levels.WARN)
    end
    return
  end
  vim.fn.writefile(vim.split(new, "\n"), path)
  local ok, err = pcall(vim.pack.update, { entry.name })
  if not ok then
    vim.notify(
      ("pack-pr: %s spec rewritten but vim.pack.update failed: %s"):format(entry.name, err),
      vim.log.levels.ERROR
    )
    return
  end
  if branch then
    vim.notify(
      ("pack-pr: %s now tracks %s (restart or :lua vim.pack.update to load)"):format(entry.name, branch),
      vim.log.levels.INFO
    )
  else
    vim.notify(("pack-pr: %s reset to its default branch"):format(entry.name), vim.log.levels.INFO)
  end
end

---Open the PR-branch picker: gather open PRs across `repos`, present them (plus
---a reset sentinel per repo) in a snacks picker, and apply the selection.
---@param repos pack-pr.Repo[]? Defaults to the configured registry.
function M.open(repos)
  repos = repos or require("plugins.pack-pr").registry()
  if vim.fn.executable("gh") == 0 then
    vim.notify("pack-pr: `gh` not found on PATH", vim.log.levels.ERROR)
    return
  end
  prs.gather(repos, function(prlist, errors)
    for _, err in ipairs(errors) do
      vim.notify(("pack-pr: %s: %s"):format(err.repo, err.message), vim.log.levels.WARN)
    end
    local items = M._build_items(prlist, repos)
    if #items == 0 then
      vim.notify("pack-pr: no managed repos configured", vim.log.levels.INFO)
      return
    end
    if #prlist == 0 and #errors == 0 then
      vim.notify("pack-pr: no open PRs found — showing reset options only", vim.log.levels.INFO)
    end
    Snacks.picker.pick({
      source = "pack_pr",
      title = "vim.pack PR branches",
      items = items,
      format = function(item)
        return { { item.text } }
      end,
      confirm = function(p, item)
        if not item then
          return
        end
        p:close()
        M._apply(item.entry, item.branch)
      end,
    })
  end)
end

return M

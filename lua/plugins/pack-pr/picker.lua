local install = require("plugins.pack-pr.install")
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
---@return table[] items Picker items (each carries `text`, `entry`, `branch`, `kind`).
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

---Ask to restart into the freshly installed `target`.
---@param name string
---@param target string
local function offer_restart(name, target)
  if vim.fn.confirm(("pack-pr: %s is on %s. Restart now?"):format(name, target), "&Yes\n&No", 1) == 1 then
    vim.cmd("restart +confirm\\ qall")
    return
  end
  vim.notify(("pack-pr: %s is on %s; restart to load it"):format(name, target), vim.log.levels.INFO)
end

---Apply a selection: rewrite the entry's spec file to track `branch` (or the
---default branch when nil) if needed, install it headlessly, then offer a restart.
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
  if not changed and not content:find(vim.pesc(entry.src)) then
    vim.notify(("pack-pr: no spec for %s in %s"):format(entry.src, entry.spec_file), vim.log.levels.WARN)
    return
  end
  if changed then
    vim.fn.writefile(vim.split(new, "\n"), path)
  end
  local target = branch or "its default branch"
  vim.notify(("pack-pr: installing %s for %s…"):format(target, entry.name), vim.log.levels.INFO)
  install.run(entry, branch, function(ok)
    if not ok then
      if changed then
        vim.fn.writefile(vim.split(content, "\n"), path)
      end
      vim.notify(("pack-pr: %s did not reach %s"):format(entry.name, target), vim.log.levels.ERROR)
      return
    end
    offer_restart(entry.name, target)
  end)
end

---Open the PR-branch picker: gather open PRs across `repos`, present them (plus
---a reset sentinel per repo) in a picker, and apply the selection.
---@param repos pack-pr.Repo[]? Defaults to the discovered repos.
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
      vim.notify("pack-pr: no matching vim.pack plugins found", vim.log.levels.INFO)
      return
    end
    if #prlist == 0 and #errors == 0 then
      vim.notify("pack-pr: no open PRs found — showing reset options only", vim.log.levels.INFO)
    end
    -- mini.pick matches on each item's `text` field and calls `choose` after
    -- the picker has already closed, so no explicit close is needed here.
    MiniPick.start({
      source = {
        name = "vim.pack PR branches",
        items = items,
        -- Items are plain tables with no `path`, so the default preview would
        -- dump vim.inspect output. Show the PR's own fields instead.
        preview = function(buf_id, item)
          local lines
          if item.kind == "pr" then
            local pr = item.pr
            lines = {
              ("%s #%d"):format(pr.repo, pr.number),
              pr.title,
              "",
              ("branch  %s"):format(pr.branch),
              ("author  @%s"):format(pr.author),
              ("url     %s"):format(pr.url),
            }
          else
            lines = { ("Reset %s to its default branch"):format(item.entry.repo) }
          end
          vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
        end,
        choose = function(item)
          if not item then
            return
          end
          M._apply(item.entry, item.branch)
        end,
      },
    })
  end)
end

return M

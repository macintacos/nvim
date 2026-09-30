local M = {}

---argv for a headless Nvim that re-sources the config (so vim.pack registers the
---rewritten spec), force-updates `name`, and quits before VimEnter.
---@param name string
---@return string[]
function M._update_cmd(name)
  return {
    vim.v.progpath,
    "--headless",
    "-i",
    "NONE",
    ("+lua vim.pack.update({ %q }, { force = true })"):format(name),
    "+qa",
  }
end

---argv printing HEAD and the ref vim.pack checks out for `branch` (default branch when nil).
---@param path string
---@param branch string?
---@return string[]
function M._verify_cmd(path, branch)
  return { "git", "-C", path, "rev-parse", "HEAD", "origin/" .. (branch or "HEAD") }
end

---Whether a `_verify_cmd` result shows HEAD at the target.
---@param res { code: integer, stdout: string? }
---@return boolean
function M._verified(res)
  local shas = vim.split(vim.trim(res.stdout or ""), "\n")
  return res.code == 0 and #shas == 2 and shas[1] == shas[2]
end

---@param cmd string[]
---@param cb fun(res: { code: integer, stdout: string? })
local function default_runner(cmd, cb)
  vim.system(cmd, { text = true }, vim.schedule_wrap(cb))
end

local runner = default_runner

---Check out the version `entry`'s spec file names, then report whether HEAD reached it.
---@param entry pack-pr.Repo
---@param branch string?
---@param cb fun(ok: boolean)
function M.run(entry, branch, cb)
  -- The child exits 0 even when vim.pack's update fails, so only the rev-parse decides.
  runner(M._update_cmd(entry.name), function()
    runner(M._verify_cmd(entry.path, branch), function(res)
      cb(M._verified(res))
    end)
  end)
end

---@param fn fun(cmd: string[], cb: fun(res: { code: integer, stdout: string? }))
function M._set_runner(fn)
  runner = fn
end

function M._reset()
  runner = default_runner
end

return M

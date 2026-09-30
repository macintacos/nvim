local M = {}

---Argv for a headless Nvim that sources the config (registering the rewritten
---spec), force-updates `name`, and quits before VimEnter, so no session is read.
---No named buffer is open, so sessions.lua skips its VimLeavePre write.
---`-i NONE` keeps the child off the running session's ShaDa.
---@param name string
---@return string[]
function M._update_cmd(name)
  return {
    vim.v.progpath,
    "--headless",
    "-i",
    "NONE",
    ("+lua vim.pack.update({ %q }, { force = true })"):format(name),
    "+qa!",
  }
end

---Argv printing HEAD and the ref vim.pack checks out for `branch` (default branch when nil).
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

---Spawn `cmd` and pass its result to `cb` on the main loop.
---@param cmd string[]
---@param cb fun(res: { code: integer, stdout: string? })
local function default_runner(cmd, cb)
  -- An inherited GIT_DIR/GIT_WORK_TREE overrides `-C`; vim.pack clears them for the same reason.
  local env = vim.fn.environ()
  env.GIT_DIR, env.GIT_WORK_TREE = nil, nil
  vim.system(cmd, { text = true, env = env, clear_env = true }, vim.schedule_wrap(cb))
end

local runner = default_runner

---Install the version `entry`'s spec file now names in a headless Nvim, then
---report whether HEAD reached `branch` (the default branch when nil).
---@param entry pack-pr.Repo
---@param branch string? Must match the spec file: the ref to verify, nil for the default branch.
---@param cb fun(ok: boolean, reason: string?) `reason` says why when not `ok`.
function M.run(entry, branch, cb)
  -- The child exits 0 even when vim.pack's update fails, so only the rev-parse decides.
  runner(M._update_cmd(entry.name), function()
    runner(M._verify_cmd(entry.path, branch), function(res)
      if res.code ~= 0 then
        cb(false, branch and ("origin/%s not found (fork PR?)"):format(branch) or "origin/HEAD not found")
      elseif M._verified(res) then
        cb(true)
      else
        -- A forced vim.pack.update reports per-plugin errors only in its log.
        cb(false, "see " .. vim.fs.joinpath(vim.fn.stdpath("log"), "nvim-pack.log"))
      end
    end)
  end)
end

---Override the process runner (test seam).
---@param fn fun(cmd: string[], cb: fun(res: { code: integer, stdout: string? }))
function M._set_runner(fn)
  runner = fn
end

---Restore the default process runner (test seam).
function M._reset()
  runner = default_runner
end

return M

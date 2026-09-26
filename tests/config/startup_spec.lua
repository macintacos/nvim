local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")

-- Runs inside the booted Neovim once the scheduled and deferred plugin setup has had
-- a moment to run, then writes what it saw to the path substituted for %q.
local collector = [[
vim.defer_fn(function()
  local notices = {}
  for _, notice in pairs(MiniNotify and MiniNotify.get_all() or {}) do
    if notice.level == "ERROR" or notice.level == "WARN" then
      table.insert(notices, notice.level .. " " .. notice.msg)
    end
  end
  local messages = vim.api.nvim_exec2("messages", { output = true }).output
  vim.fn.writefile({ vim.json.encode({ messages = messages, notices = notices }) }, %q)
  vim.cmd("qa!")
end, 1500)
]]

---Boot this checkout's whole config headless, editing a Lua file so the plugins
---that load on FileType run too.
---@param dir string Scratch directory, also the booted Neovim's cwd.
---@return { stderr: string, messages: string, notices: string[] }
local function boot(dir)
  local report = dir .. "/report.json"
  vim.fn.writefile(vim.split(collector:format(report), "\n"), dir .. "/collect.lua")
  local config = vim.fn.stdpath("config")
  local rtp = ("lua vim.opt.rtp:remove({ %q, %q }); vim.opt.rtp:prepend(%q); vim.opt.rtp:append(%q)"):format(
    config,
    config .. "/after",
    root,
    root .. "/after"
  )
  -- minimal_init moved XDG_STATE_HOME to a temp dir, where mise's shims would find
  -- no trust record and refuse to run the tools the config starts.
  local env = vim.fn.environ()
  env.XDG_STATE_HOME = nil

  local result = vim
    .system({
      vim.v.progpath,
      "--headless",
      "-i",
      "NONE",
      "-n",
      "--cmd",
      rtp,
      "-u",
      root .. "/init.lua",
      "-c",
      "luafile " .. dir .. "/collect.lua",
      dir .. "/probe.lua",
    }, { cwd = dir, env = env, clear_env = true, text = true })
    :wait(30000)
  assert.equal(0, result.code, result.stderr)

  local seen = vim.json.decode(table.concat(vim.fn.readfile(report), "\n"))
  return { stderr = result.stderr, messages = seen.messages, notices = seen.notices }
end

describe("startup", function()
  local dir

  before_each(function()
    -- A temp cwd is also one mini.sessions never writes a session for.
    dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
  end)

  after_each(function()
    vim.fn.delete(dir, "rf")
  end)

  it("loads the whole config without an error or warning", function()
    local seen = boot(dir)

    assert.equal("", seen.stderr)
    assert.equal("", seen.messages)
    assert.same({}, seen.notices)
  end)
end)

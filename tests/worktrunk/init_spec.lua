local projects = require("plugins.projects")
local worktrunk = require("plugins.worktrunk")

---@return integer
local function window_count()
  return #vim.api.nvim_tabpage_list_wins(0)
end

describe("worktrunk._run", function()
  local switch, notify, relaunched, warnings, errors
  ---@type string
  local start
  ---@type string
  local elsewhere

  before_each(function()
    switch = projects.switch
    notify = vim.notify
    relaunched, warnings, errors = {}, {}, {}
    projects.switch = function(dir)
      relaunched[#relaunched + 1] = { dir = dir }
    end
    vim.notify = function(msg, level)
      if level == vim.log.levels.WARN then
        warnings[#warnings + 1] = msg
      elseif level == vim.log.levels.ERROR then
        errors[#errors + 1] = msg
      end
    end
    start = vim.fn.tempname()
    elsewhere = vim.fn.tempname()
    vim.fn.mkdir(start, "p")
    vim.fn.mkdir(elsewhere, "p")
    vim.fn.chdir(start)
  end)

  after_each(function()
    projects.switch = switch
    vim.notify = notify
    require("helpers.windows").close_all_floating_wins()
    vim.fn.delete(start, "rf")
    vim.fn.delete(elsewhere, "rf")
  end)

  ---Run `argv` in the float and wait for it, and its exit handling, to finish.
  ---@param argv string[]
  ---@return integer float The float it ran in.
  local function run_argv(argv)
    worktrunk._run("test", argv)
    local float = vim.api.nvim_get_current_win()
    local job = vim.bo[vim.api.nvim_win_get_buf(float)].channel
    assert.are_not.same({ -1 }, vim.fn.jobwait({ job }, 5000))
    return float
  end

  ---@param script string Run by sh; it reports a directory as the fish runner would.
  ---@return integer float
  local function run(script)
    return run_argv({ "sh", "-c", script })
  end

  it("relaunches Neovim in the directory the command ends in", function()
    local float = run(('cd %q && pwd -P >"$NVIM_WT_LANDED"'):format(elsewhere))
    assert.same({ { dir = vim.uv.fs_realpath(elsewhere) } }, relaunched)
    assert.is_false(vim.api.nvim_win_is_valid(float))
    assert.same({}, warnings)
  end)

  it("relaunches where an interactive fish command leaves the shell", function()
    run_argv(worktrunk._fish("cd " .. vim.fn.shellescape(elsewhere)))
    assert.same({ { dir = vim.uv.fs_realpath(elsewhere) } }, relaunched)
  end)

  it("reports why Neovim couldn't quit to relaunch", function()
    projects.switch = function()
      error("E212: Can't open file for writing")
    end
    run(('cd %q && pwd -P >"$NVIM_WT_LANDED"'):format(elsewhere))
    assert.equal(1, #errors)
  end)

  it("warns when Neovim stays behind in a worktree the command removed", function()
    projects.switch = function()
      error("E212: Can't open file for writing")
    end
    run(('cd %q && rmdir %q && pwd -P >"$NVIM_WT_LANDED"'):format(elsewhere, start))
    assert.equal(1, #warnings)
  end)

  it("closes quietly when the command ends where it started and printed nothing", function()
    local float = run('pwd -P >"$NVIM_WT_LANDED"')
    assert.same({}, relaunched)
    assert.is_false(vim.api.nvim_win_is_valid(float))
  end)

  it("keeps the float open to read when the command printed and stayed put", function()
    local float = run('echo "wt refused"; pwd -P >"$NVIM_WT_LANDED"')
    assert.same({}, relaunched)
    assert.is_true(vim.api.nvim_win_is_valid(float))
  end)

  it("stays put when the command never reports a directory", function()
    run("exit 1")
    assert.same({}, relaunched)
  end)
end)

describe("worktrunk destructive actions", function()
  local confirm, notify, jobstart, asked, answer, warnings
  ---@type string[]
  local started
  ---@type string
  local dir

  before_each(function()
    confirm = vim.fn.confirm
    notify = vim.notify
    jobstart = vim.fn.jobstart
    asked, answer, warnings, started = 0, 2, {}, {}
    vim.fn.confirm = function()
      asked = asked + 1
      return answer
    end
    -- Nothing here may run a real wt command, whatever the code under test does.
    ---@param cmd string|string[]
    vim.fn.jobstart = function(cmd)
      started[#started + 1] = vim.inspect(cmd)
      return 1
    end
    vim.notify = function(msg, level)
      if level == vim.log.levels.WARN then
        warnings[#warnings + 1] = msg
      end
    end
    dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    vim.fn.chdir(dir)
  end)

  after_each(function()
    vim.fn.confirm = confirm
    vim.notify = notify
    vim.fn.jobstart = jobstart
    require("helpers.windows").close_all_floating_wins()
    vim.cmd("silent! %bwipeout!")
    vim.fn.delete(dir, "rf")
  end)

  for _, action in ipairs({ "remove", "merge" }) do
    it(action .. " refuses while a file has unsaved changes", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "unsaved" })
      local windows = window_count()
      worktrunk[action]()
      assert.equal(0, asked)
      assert.equal(1, #warnings)
      assert.equal(windows, window_count())
    end)

    it(action .. " does nothing when the confirmation is declined", function()
      local windows = window_count()
      worktrunk[action]()
      assert.equal(1, asked)
      assert.same({}, started)
      assert.equal(windows, window_count())
    end)

    it(action .. " runs wt " .. action .. " once confirmed", function()
      answer = 1
      worktrunk[action]()
      assert.equal(1, #started)
      assert.truthy(assert(started[1]):find("wt " .. action, 1, true))
    end)
  end

  it("remove still asks for confirmation while a terminal is open", function()
    vim.cmd.terminal("sleep 5")
    vim.cmd.enew()
    worktrunk.remove()
    assert.equal(1, asked)
  end)
end)

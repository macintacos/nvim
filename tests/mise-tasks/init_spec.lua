vim.opt.rtp:prepend(require("support.deps").path("mini.pick"))
require("mini.pick").setup()

local mise_tasks = require("plugins.mise-tasks")

---Write an executable shell script.
---@param path string
---@param body string
local function script(path, body)
  vim.fn.writefile(vim.list_extend({ "#!/bin/sh" }, vim.split(body, "\n")), path)
  vim.fn.setfperm(path, "rwxr-xr-x")
end

---@param name string
---@param description string
---@return mise-tasks.Task
local function task(name, description)
  return { name = name, description = description, text = name }
end

describe("mise-tasks._command", function()
  ---@type string
  local bin

  before_each(function()
    bin = vim.fn.tempname()
    vim.fn.mkdir(bin, "p")
    script(bin .. "/mise", 'printf "%s|" "$@"')
  end)

  after_each(function()
    vim.fn.delete(bin, "rf")
  end)

  it("runs the task with no arguments", function()
    assert.are.same({ "mise", "run", "test" }, mise_tasks._command("test", nil))
    assert.are.same({ "mise", "run", "test" }, mise_tasks._command("test", "  "))
  end)

  it("hands typed arguments to mise quoted as at a prompt", function()
    local command = mise_tasks._command("lint:fix", '--only "a b"')
    local out = vim.system(command, { env = { PATH = bin .. ":" .. vim.env.PATH }, text = true }):wait()
    assert.are.equal("run|lint:fix|--only|a b|", out.stdout)
  end)
end)

describe("mise-tasks._layout", function()
  local items = {
    task("test", "Run the specs"),
    task("preflight", "Lint, then test"),
  }

  it("centers the list over the preview, as one block", function()
    local layout = mise_tasks._layout(items, 200, 50)
    local list, preview = layout.list, layout.preview

    assert.are.equal(2, list.height)
    assert.are.equal(list.col, preview.col)
    assert.are.equal(list.width, preview.width)
    assert.are.equal(list.row + list.height + 2, preview.row)

    local top, bottom = list.row, preview.row + preview.height + 2
    assert.is_true(math.abs(top - (50 - bottom)) <= 1)
    assert.is_true(math.abs(list.col - (200 - list.col - list.width - 2)) <= 1)
  end)

  it("is wide enough for a description after the widest name", function()
    local layout = mise_tasks._layout({
      task(("a"):rep(30), ""),
      task("b", ("x"):rep(40)),
    }, 200, 50)
    assert.is_true(layout.list.width >= 2 + 30 + 2 + 40)
  end)

  it("fits a small editor", function()
    local many = {}
    for i = 1, 100 do
      many[i] = task("task" .. i, ("x"):rep(300))
    end
    local layout = mise_tasks._layout(many, 60, 20)

    assert.is_true(layout.list.width <= 60 - 2)
    assert.is_true(layout.preview.row + layout.preview.height + 2 <= 20)
    assert.is_true(layout.list.row >= 0)
  end)
end)

describe("mise-tasks.pick", function()
  ---@type string, table<string, string?>
  local bin, saved

  before_each(function()
    saved = { PATH = vim.env.PATH, REX_BIN_DIR = vim.env.REX_BIN_DIR, REX_SESSION = vim.env.REX_SESSION }
    bin = vim.fn.tempname()
    vim.fn.mkdir(bin, "p")
    script(
      bin .. "/mise",
      table.concat({
        'if [ "$2" = ls ]; then',
        -- Outlasts drive's first step, as a slow mise would, so the specs below must wait for the picker.
        "  sleep 0.1",
        [[  echo '[{"name":"build","description":"Build it"},{"name":"test","description":"Run specs"}]']],
        "else",
        '  echo "Task: $3"',
        "fi",
      }, "\n")
    )
    script(bin .. "/rex", 'cat > "$(dirname "$0")/payload.json"')
    vim.env.PATH = bin .. ":" .. vim.env.PATH
    vim.env.REX_BIN_DIR = bin
    vim.env.REX_SESSION = "session:test"
  end)

  after_each(function()
    if MiniPick.is_picker_active() then
      MiniPick.stop()
    end
    vim.env.PATH, vim.env.REX_BIN_DIR, vim.env.REX_SESSION = saved.PATH, saved.REX_BIN_DIR, saved.REX_SESSION
    vim.fn.delete(bin, "rf")
  end)

  ---Every float but the picker's own window.
  ---@return integer[]
  local function side_floats()
    local main = assert(MiniPick.get_picker_state()).windows.main
    return vim.tbl_filter(function(win)
      local buf = vim.api.nvim_win_get_buf(win)
      return win ~= main and vim.api.nvim_win_get_config(win).relative ~= "" and vim.bo[buf].filetype ~= "incline"
    end, vim.api.nvim_list_wins())
  end

  ---Wait for the INFO float, the last thing `pick` opens: `pick` lists the tasks
  ---before it starts the picker, so `drive`'s first step can run before the
  ---picker has its items or that float.
  local function started()
    vim.wait(2000, function()
      return #side_floats() > 0
    end)
  end

  it("shows the current task's info beneath the list until the picker stops", function()
    ---@type integer[], integer, vim.api.keyset.win_config, vim.api.keyset.win_config, string[]
    local floats, win, picker_config, info_config, lines
    require("support.pick").drive(mise_tasks.pick, {
      function()
        started()
        floats = side_floats()
        win = floats[1] or -1
        local state = MiniPick.get_picker_state()
        picker_config = state and vim.api.nvim_win_get_config(state.windows.main) or {}
        info_config = vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win) or {}
        lines = vim.api.nvim_win_is_valid(win)
            and vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
          or {}
      end,
    })

    assert.are.equal(1, #floats)
    assert.is_true(info_config.row > picker_config.row)
    assert.are.same({ " Task: build" }, lines)
    assert.is_false(vim.api.nvim_win_is_valid(win))
  end)

  it("runs the chosen task in a Rex pane that stays open", function()
    require("support.pick").drive(mise_tasks.pick, {
      function()
        started()
        assert(MiniPick.get_picker_opts()).source.choose(assert(MiniPick.get_picker_matches()).current)
      end,
    })
    local path = bin .. "/payload.json"
    assert.is_true(vim.wait(2000, function()
      return vim.fn.filereadable(path) == 1 and vim.fn.getfsize(path) > 0
    end))
    local options = vim.json.decode(table.concat(vim.fn.readfile(path), "\n")).layout.block.options
    assert.are.same({ "mise", "run", "build" }, options.command)
    assert.are.equal(vim.fn.getcwd(), options.cwd)
    assert.is_false(options.exit.on_completion)
  end)

  it("leaves the next picker alone when its own didn't start", function()
    -- MiniPick.start declines from the command-line window; stand in for that.
    local start = MiniPick.start
    MiniPick.start = function() end
    mise_tasks.pick()
    MiniPick.start = start

    ---@type integer[]
    local floats
    require("support.pick").drive(function()
      MiniPick.start({ source = { items = { "x" } } })
    end, {
      function()
        floats = side_floats()
      end,
    })
    assert.are.same({}, floats)
  end)
end)

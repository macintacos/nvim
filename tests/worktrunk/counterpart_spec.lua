local counterpart = require("plugins.worktrunk.counterpart")
local git = require("support.git")

describe("counterpart._parse", function()
  it("reads each worktree's path, and its branch unless HEAD is detached", function()
    local porcelain = table.concat({
      "worktree /repo",
      "HEAD 1111111111111111111111111111111111111111",
      "branch refs/heads/main",
      "",
      "worktree /wt/repo/feature+x",
      "HEAD 2222222222222222222222222222222222222222",
      "branch refs/heads/feature/x",
      "",
      "worktree /wt/repo/detached",
      "HEAD 3333333333333333333333333333333333333333",
      "detached",
      "",
    }, "\n")
    assert.same({
      { path = "/repo", branch = "main" },
      { path = "/wt/repo/feature+x", branch = "feature/x" },
      { path = "/wt/repo/detached" },
    }, counterpart._parse(porcelain))
  end)
end)

describe("counterpart", function()
  local select, notify, warnings, errors
  ---@type string
  local tmp
  ---@type string
  local main
  ---@type string
  local feature
  ---@type worktrunk.Worktree[]?
  local offered

  ---@param path string
  ---@param lines string[]
  local function write(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile(lines, path)
  end

  before_each(function()
    select = vim.ui.select
    notify = vim.notify
    offered, warnings, errors = nil, {}, {}
    vim.ui.select = function(items, _, on_choice)
      offered = items
      on_choice(items[1])
    end
    vim.notify = function(msg, level)
      if level == vim.log.levels.WARN then
        warnings[#warnings + 1] = msg
      elseif level == vim.log.levels.ERROR then
        errors[#errors + 1] = msg
      end
    end

    tmp = vim.fn.tempname()
    main = vim.fs.joinpath(tmp, "main")
    feature = vim.fs.joinpath(tmp, "feature")
    vim.fn.mkdir(main, "p")
    git.init_repo("main", main)
    write(vim.fs.joinpath(main, "src", "a.lua"), { "main" })
    git.commit("add a", main)
    git.git({ "worktree", "add", "-q", "-b", "feature", feature }, main)
    write(vim.fs.joinpath(feature, "src", "a.lua"), { "feature" })
  end)

  after_each(function()
    vim.ui.select = select
    vim.notify = notify
    vim.cmd("silent! diffoff!")
    vim.cmd("silent! only!")
    vim.cmd("silent! %bwipeout!")
    vim.fn.delete(tmp, "rf")
  end)

  it("offers every worktree but the current one", function()
    local third = vim.fs.joinpath(tmp, "third")
    git.git({ "worktree", "add", "-q", "-b", "third", third }, main)
    vim.cmd.edit(vim.fs.joinpath(feature, "src", "a.lua"))
    counterpart.split()
    local offered_paths = vim.tbl_map(function(tree)
      return tree.path
    end, assert(offered))
    table.sort(offered_paths)
    assert.same({ vim.uv.fs_realpath(main), vim.uv.fs_realpath(third) }, offered_paths)
  end)

  it("opens the file's copy from the chosen worktree beside it", function()
    vim.cmd.edit(vim.fs.joinpath(main, "src", "a.lua"))
    counterpart.split()
    assert.equal(2, #vim.api.nvim_tabpage_list_wins(0))
    assert.equal(
      vim.uv.fs_realpath(vim.fs.joinpath(feature, "src", "a.lua")),
      vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0))
    )
  end)

  it("diffs the file against its copy in the chosen worktree", function()
    vim.cmd.edit(vim.fs.joinpath(main, "src", "a.lua"))
    counterpart.diff()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    assert.equal(2, #wins)
    for _, win in ipairs(wins) do
      assert.is_true(vim.wo[win].diff)
    end
  end)

  it("warns instead of opening when the chosen worktree lacks the file", function()
    write(vim.fs.joinpath(main, "only-here.lua"), { "main" })
    vim.cmd.edit(vim.fs.joinpath(main, "only-here.lua"))
    counterpart.split()
    assert.equal(1, #warnings)
    assert.equal(1, #vim.api.nvim_tabpage_list_wins(0))
  end)

  it("warns without offering anything from a buffer that isn't a file in a repository", function()
    vim.cmd.enew()
    counterpart.split()
    assert.is_nil(offered)
    assert.equal(1, #warnings)
  end)

  it("warns without offering anything from a terminal opened inside a repository", function()
    vim.fn.chdir(main)
    vim.cmd.terminal("sleep 5")
    counterpart.split()
    assert.is_nil(offered)
    assert.equal(1, #warnings)
  end)

  it("finds a symlinked file's copy by the link's own path", function()
    local outside = vim.fs.joinpath(tmp, "outside.lua")
    write(outside, { "outside" })
    vim.uv.fs_symlink(outside, vim.fs.joinpath(main, "linked.lua"))
    write(vim.fs.joinpath(feature, "linked.lua"), { "feature" })
    vim.cmd.edit(vim.fs.joinpath(main, "linked.lua"))
    counterpart.split()
    assert.equal(
      vim.uv.fs_realpath(vim.fs.joinpath(feature, "linked.lua")),
      vim.uv.fs_realpath(vim.api.nvim_buf_get_name(0))
    )
  end)

  it("reports git's error when the worktrees can't be listed", function()
    local broken = vim.fs.joinpath(tmp, "broken")
    write(vim.fs.joinpath(broken, ".git"), { "gitdir: " .. vim.fs.joinpath(tmp, "missing") })
    write(vim.fs.joinpath(broken, "a.lua"), { "a" })
    vim.cmd.edit(vim.fs.joinpath(broken, "a.lua"))
    counterpart.split()
    assert.is_nil(offered)
    assert.equal(1, #errors)
    assert.same({}, warnings)
  end)
end)

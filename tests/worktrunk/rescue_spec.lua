local git = require("support.git")
local rescue = require("plugins.worktrunk.rescue")

describe("worktrunk.rescue", function()
  ---@type string
  local tmp

  before_each(function()
    tmp = vim.fn.resolve(vim.fn.tempname())
  end)

  after_each(function()
    vim.cmd.cd("/")
    vim.fn.delete(tmp, "rf")
  end)

  it("moves into the primary worktree once the linked worktree under it is removed", function()
    local primary, linked = tmp .. "/repo", tmp .. "/repo.feature"
    vim.fn.mkdir(primary, "p")
    git.init_repo("main", primary)
    git.git({ "worktree", "add", "-q", "-b", "feature", linked }, primary)
    vim.cmd.cd(linked)
    rescue.setup()
    assert.is_true(vim.wait(5000, rescue._armed))

    git.git({ "worktree", "remove", linked }, primary)

    assert.is_true(vim.wait(5000, function()
      return vim.fn.getcwd() == primary
    end))
    assert.is_true(rescue.rescued())
  end)
end)

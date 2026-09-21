local Git = require("helpers.git")
local Fixture = require("support.git")

local git, init_repo = Fixture.git, Fixture.init_repo

describe("helpers.git", function()
  local tmp, cwd

  before_each(function()
    tmp, cwd = Fixture.tempdir()
  end)

  after_each(function()
    vim.fn.chdir(cwd)
    vim.fn.delete(tmp, "rf")
  end)

  describe("default_base", function()
    it("picks the conventional branch that exists", function()
      init_repo("trunk")
      assert.equal("trunk", Git.default_base())
    end)

    it("prefers origin/HEAD over the conventional names", function()
      init_repo("main")
      git({ "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/mainline" })
      assert.equal("mainline", Git.default_base())
    end)

    it("falls back to main when nothing matches", function()
      init_repo("weird")
      assert.equal("main", Git.default_base())
    end)
  end)

  describe("merge_base", function()
    it("returns the fork point and the branch it forked from", function()
      local fork = init_repo("trunk")
      git({ "checkout", "-q", "-b", "feature" })
      git({ "commit", "-q", "--allow-empty", "-m", "work" })

      local sha, branch = Git.merge_base()
      assert.equal(fork, sha)
      assert.equal("trunk", branch)
    end)

    it("names the remote ref it measured against when one exists", function()
      local fork = init_repo("trunk")
      git({ "update-ref", "refs/remotes/origin/trunk", fork })
      git({ "checkout", "-q", "-b", "feature" })

      local _, _, ref = Git.merge_base()
      assert.equal("origin/trunk", ref)
    end)

    it("names the local branch when there is no remote to measure against", function()
      init_repo("trunk")
      git({ "checkout", "-q", "-b", "feature" })

      local _, _, ref = Git.merge_base()
      assert.equal("trunk", ref)
    end)

    it("measures the repo it is given rather than the one Neovim sits in", function()
      local fork = init_repo("trunk")
      git({ "checkout", "-q", "-b", "feature" })
      vim.fn.chdir(cwd)

      assert.equal(fork, (Git.merge_base(tmp)))
    end)

    it("returns nil outside a repo", function()
      assert.is_nil(Git.merge_base())
    end)
  end)
end)

local pack_updates = require("config.pack-updates")

describe("build_queue", function()
  local pack_dir

  before_each(function()
    pack_dir = vim.fn.tempname()
    vim.fn.mkdir(pack_dir .. "/foo.nvim/.git", "p")
    vim.fn.writefile({ "bbbb" }, pack_dir .. "/foo.nvim/.git/HEAD")
  end)

  after_each(function()
    vim.fn.delete(pack_dir, "rf")
  end)

  it("compares against the checked-out revision when the lockfile lags it", function()
    local lock = { ["foo.nvim"] = { src = "https://example.com/foo.nvim", rev = "aaaa" } }
    assert.same({ { src = "https://example.com/foo.nvim", rev = "bbbb" } }, pack_updates._build_queue(lock, pack_dir))
  end)
end)

local pack_updates = require("plugins.pack-updates")

describe("build_queue", function()
  ---@type string
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

describe("recheck_on_update", function()
  local checks, saved_check

  before_each(function()
    checks = {}
    saved_check = pack_updates.check
    pack_updates.check = function(force)
      table.insert(checks, force)
    end
    pack_updates.recheck_on_update()
  end)

  after_each(function()
    pack_updates.check = saved_check
  end)

  ---Emit the event vim.pack sends after checking out a plugin.
  ---@param name string
  local function update_plugin(name)
    local path = "/pack/opt/" .. name
    vim.api.nvim_exec_autocmds("PackChanged", {
      pattern = path,
      data = {
        active = true,
        kind = "update",
        path = path,
        spec = { name = name, src = "https://example.com/" .. name },
      },
    })
  end

  ---Emit the progress message vim.pack sends when a batch finishes.
  local function finish_batch()
    vim.api.nvim_echo(
      { { "Applying updates (2/2)" } },
      false,
      { kind = "progress", source = "vim.pack", title = "vim.pack", status = "success", percent = 100 }
    )
  end

  it("forces one re-check when a batch that updated plugins finishes", function()
    update_plugin("foo.nvim")
    update_plugin("bar.nvim")
    assert.same({}, checks)

    finish_batch()
    finish_batch()
    assert.same({ true }, checks)
  end)

  it("leaves the count alone when a batch only downloaded", function()
    finish_batch()
    assert.same({}, checks)
  end)
end)

describe("cache_is_valid", function()
  before_each(function()
    vim.fn.mkdir(vim.fn.fnamemodify(pack_updates._cache_path, ":h"), "p")
  end)

  after_each(function()
    vim.fn.delete(pack_updates._cache_path)
  end)

  it("accepts a fresh cache object", function()
    vim.fn.writefile({ vim.json.encode({ checked_at = os.time(), count = 2 }) }, pack_updates._cache_path)
    local valid, cache = pack_updates._cache_is_valid()
    assert.is_true(valid)
    assert.equal(2, assert(cache).count)
  end)

  it("treats a cache file that does not decode to an object as absent", function()
    vim.fn.writefile({ "5" }, pack_updates._cache_path)
    local valid = pack_updates._cache_is_valid()
    assert.is_false(valid)
  end)

  it("treats a cache object without a numeric checked_at as absent", function()
    vim.fn.writefile({ "{}" }, pack_updates._cache_path)
    local valid = pack_updates._cache_is_valid()
    assert.is_false(valid)
  end)
end)

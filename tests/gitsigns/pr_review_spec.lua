local support = require("support.git")

local data = vim.fn.stdpath("data") .. "/site/pack/"
vim.opt.rtp:prepend(vim.fn.glob(data .. "*/opt/gitsigns.nvim", false, true)[1])

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
-- The plugin file registers an un-grouped autocmd and keeps its branch memo at
-- file scope, so it is sourced once, and each case works on a branch of its own.
local pack_add = vim.pack.add
vim.pack.add = function() end
local ok, err = pcall(dofile, root .. "/plugin/gitsigns.lua")
vim.pack.add = pack_add
assert(ok, err)

local Obj = require("gitsigns.git").Obj
local in_flight, moves = 0, 0
local change_revision = Obj.change_revision
Obj.change_revision = function(...)
  in_flight, moves = in_flight + 1, moves + 1
  local result = change_revision(...)
  in_flight = in_flight - 1
  return result
end

---@param buf integer
---@return string? revision nil while gitsigns has not cached the buffer.
local function revision(buf)
  local bcache = require("gitsigns.cache").cache[buf]
  return bcache and bcache.git_obj.revision
end

---@param bufs integer[]
---@param pred fun(buf: integer): boolean
---@param timeout integer
---@return boolean
local function await_all(bufs, pred, timeout)
  return vim.wait(timeout, function()
    for _, buf in ipairs(bufs) do
      if not pred(buf) then
        return false
      end
    end
    return true
  end, 20)
end

---@param bufs integer[]
---@param want string?
---@param timeout integer
---@return boolean
local function await(bufs, want, timeout)
  return await_all(bufs, function(buf)
    return revision(buf) == want
  end, timeout)
end

---@param bufs integer[]
---@return boolean
local function await_cached(bufs)
  return await_all(bufs, function(buf)
    return require("gitsigns.cache").cache[buf] ~= nil
  end, 5000)
end

---Wait until no base change is in flight and every buffer sits on gitsigns' base.
---@return boolean
local function settle()
  return vim.wait(10000, function()
    return in_flight == 0
      and vim.iter(pairs(require("gitsigns.cache").cache)):all(function(buf)
        return revision(buf) == require("gitsigns.config").config.base
      end)
  end, 20)
end

---@param files string[]
---@return integer[]
local function edit(files)
  local bufs = {}
  for _, name in ipairs(files) do
    vim.cmd.edit(name)
    bufs[#bufs + 1] = vim.api.nvim_get_current_buf()
  end
  return bufs
end

describe("PR Review Mode", function()
  local dir, cwd

  ---A repo on `main` with `files` committed, and `branch` carrying a change to each.
  ---@param branch string
  ---@param files string[]
  local function fixture(branch, files)
    for _, name in ipairs(files) do
      vim.fn.writefile({ "one" }, dir .. "/" .. name)
    end
    support.commit("base", dir)
    support.git({ "switch", "-q", "-c", branch }, dir)
    for _, name in ipairs(files) do
      vim.fn.writefile({ "one", "two" }, dir .. "/" .. name)
    end
    support.commit("change", dir)
  end

  ---@return string
  local function merge_base()
    return support.git({ "merge-base", "HEAD", "main" }, dir)
  end

  before_each(function()
    cwd = vim.fn.getcwd()
    dir = vim.fn.resolve(vim.fn.tempname())
    vim.fn.mkdir(dir, "p")
    support.init_repo("main", dir)
    vim.o.hidden = true
  end)

  after_each(function()
    -- Let every base change in flight land before its repo is deleted under it.
    settle()
    vim.cmd("silent! %bwipeout!")
    -- The next fixture is another repo, where this one's merge base does not exist
    -- and every attach against it would fail.
    require("gitsigns").reset_base(true)
    vim.fn.chdir(cwd)
    vim.fn.delete(dir, "rf")
  end)

  it("diffs a single edited file against the merge base", function()
    fixture("single", { "a.txt" })
    vim.fn.chdir(dir)

    local bufs = edit({ "a.txt" })

    assert.is_true(await(bufs, merge_base(), 5000))
  end)

  it("gives every buffer loaded in the same tick the merge base", function()
    fixture("burst", { "a.txt", "b.txt", "c.txt" })
    vim.fn.chdir(dir)

    local bufs = edit({ "a.txt", "b.txt", "c.txt" })

    assert.is_true(await(bufs, merge_base(), 5000))
  end)

  it("moves attached buffers to the new merge base after an external branch switch", function()
    local files = { "a.txt", "b.txt", "c.txt", "d.txt" }
    fixture("switched", files)
    support.git({ "switch", "-q", "main" }, dir)
    vim.fn.chdir(dir)

    local bufs = edit(files)
    assert.is_true(await_cached(bufs))

    support.git({ "switch", "-q", "switched" }, dir)

    assert.is_true(await(bufs, merge_base(), 10000))
  end)

  it("keeps a lone buffer on the merge base after an external branch switch", function()
    vim.fn.chdir(dir)
    for i = 1, 5 do
      vim.fn.writefile({ "base " .. i }, dir .. "/a.txt")
      support.commit("base " .. i, dir)
      support.git({ "switch", "-q", "-c", "lone-" .. i }, dir)
      vim.fn.writefile({ "base " .. i, "change" }, dir .. "/a.txt")
      support.commit("change " .. i, dir)
      support.git({ "switch", "-q", "main" }, dir)

      local bufs = edit({ "a.txt" })
      assert.is_true(await_cached(bufs))
      assert.is_true(await(bufs, nil, 5000))

      support.git({ "switch", "-q", "lone-" .. i }, dir)
      local mb = merge_base()
      assert.is_true(await(bufs, mb, 10000), "iteration " .. i)
      assert.is_false(vim.wait(2000, function()
        return revision(bufs[1]) ~= mb
      end, 20))

      vim.cmd("silent! %bwipeout!")
      support.git({ "switch", "-q", "main" }, dir)
    end
  end)

  it("leaves a base set by hand alone", function()
    vim.fn.writefile({ "one" }, dir .. "/a.txt")
    vim.fn.writefile({ "one" }, dir .. "/b.txt")
    support.commit("base", dir)
    local parent = support.git({ "rev-parse", "HEAD~1" }, dir)
    vim.fn.chdir(dir)

    local bufs = edit({ "a.txt", "b.txt" })
    assert.is_true(await_cached(bufs))
    vim.api.nvim_buf_call(bufs[1], function()
      require("gitsigns").change_base(parent)
    end)
    assert.is_true(await({ bufs[1] }, parent, 5000))

    vim.api.nvim_buf_set_lines(bufs[2], 0, -1, false, { "edited" })

    assert.is_false(vim.wait(1500, function()
      return revision(bufs[1]) ~= parent
    end, 20))
  end)

  it("moves each buffer onto a new base once", function()
    local files = {}
    for i = 1, 18 do
      files[i] = i .. ".txt"
    end
    fixture("counted", files)
    support.git({ "switch", "-q", "main" }, dir)
    vim.fn.chdir(dir)

    local bufs = edit(vim.list_slice(files, 1, 12))
    assert.is_true(await_cached(bufs))
    assert.is_true(await(bufs, nil, 5000))

    local before = moves

    support.git({ "switch", "-q", "counted" }, dir)
    local mb = merge_base()
    -- The first buffer reaching the base marks the start of the global walk; the
    -- rest attach while it runs.
    assert.is_true(vim.wait(10000, function()
      return revision(bufs[1]) == mb
    end, 1))
    vim.list_extend(bufs, edit(vim.list_slice(files, 13, 18)))

    assert.is_true(await(bufs, mb, 10000))
    assert.is_true(settle())
    assert.is_true(moves - before <= 20, moves - before .. " base changes")
  end)
end)

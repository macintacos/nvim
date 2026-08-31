local scratch = require("plugins.scratch")

describe("scratch.float", function()
  local cwd
  local tmpdir

  before_each(function()
    cwd = vim.fn.getcwd()
    tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")
    vim.cmd.cd(tmpdir)
  end)

  after_each(function()
    vim.cmd.cd(cwd)
    vim.fn.delete(tmpdir, "rf")
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        vim.api.nvim_win_close(win, true)
      end
    end
  end)

  ---Count floats in the current tabpage.
  ---@return integer
  local function float_count()
    local n = 0
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        n = n + 1
      end
    end
    return n
  end

  it("creates .tmp/scratch.md under the cwd", function()
    scratch.float()
    assert.equal(1, vim.fn.filereadable(vim.fs.joinpath(tmpdir, ".tmp", "scratch.md")))
  end)

  it("reuses the open float instead of stacking a second one", function()
    scratch.float()
    local win = vim.api.nvim_get_current_win()
    assert.equal(1, float_count())

    -- Move focus out of the float, then re-invoke: we should land back in it.
    vim.api.nvim_set_current_win(vim.fn.win_getid(1))
    scratch.float()
    assert.equal(1, float_count())
    assert.equal(win, vim.api.nvim_get_current_win())
  end)

  it("sizes the float to 80% of the editor", function()
    scratch.float()
    local cfg = vim.api.nvim_win_get_config(0)
    assert.equal(math.floor(vim.o.columns * 0.8), cfg.width)
    assert.equal(math.floor(vim.o.lines * 0.8), cfg.height)
  end)
end)

local scratch = require("plugins.scratch")

describe("scratch", function()
  local cwd
  ---@type string
  local tmpdir
  ---@type string
  local dir
  local select, input
  ---Items the last picker offered, or nil when no picker opened.
  ---@type string[]?
  local offered
  ---Index of the offered item the picker answers with; nil cancels it.
  ---@type integer?
  local pick
  ---What the name prompt answers with; nil cancels it.
  ---@type string?
  local typed

  ---@param win integer
  ---@return boolean
  local function is_float(win)
    return vim.api.nvim_win_get_config(win).relative ~= ""
  end

  ---Count floats in the current tabpage.
  ---@return integer
  local function float_count()
    local n = 0
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if is_float(win) then
        n = n + 1
      end
    end
    return n
  end

  ---Write a scratch file and backdate its mtime.
  ---@param name string
  ---@param mtime integer
  ---@param lines? string[]
  ---@return string path
  local function write(name, mtime, lines)
    vim.fn.mkdir(dir, "p")
    local path = vim.fs.joinpath(dir, name)
    vim.fn.writefile(lines or {}, path)
    vim.uv.fs_utime(path, mtime, mtime)
    return path
  end

  ---Run what scratch deferred until the picker closed: callbacks run in the
  ---order they were scheduled, so theirs have run once this marker has.
  local function settle()
    local done = false
    vim.schedule(function()
      done = true
    end)
    assert.is_true(vim.wait(1000, function()
      return done
    end))
  end

  before_each(function()
    cwd = vim.fn.getcwd()
    tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")
    vim.cmd.cd(tmpdir)
    dir = vim.fs.joinpath(vim.fn.getcwd(), ".tmp", "scratch")

    offered, pick, typed = nil, nil, nil
    select, input = vim.ui.select, vim.ui.input
    -- Answers the way mini.pick does: on_choice runs inside a win_call on the
    -- window the picker opened from while the picker's own window is current,
    -- then focus lands wherever on_choice left it.
    vim.ui.select = function(items, _, on_choice)
      offered = items
      local target = vim.api.nvim_get_current_win()
      local picker = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, {
        relative = "editor",
        row = 0,
        col = 0,
        width = 1,
        height = 1,
      })
      local landed = target
      vim.api.nvim_win_call(target, function()
        on_choice(pick and items[pick])
        landed = vim.api.nvim_get_current_win()
      end)
      vim.api.nvim_set_current_win(landed)
      vim.api.nvim_win_close(picker, true)
    end
    vim.ui.input = function(_, on_confirm)
      on_confirm(typed)
    end
  end)

  after_each(function()
    vim.ui.select, vim.ui.input = select, input
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if is_float(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
    vim.cmd("silent! %bwipeout!")
    vim.cmd.cd(cwd)
    vim.fn.delete(tmpdir, "rf")
  end)

  describe("open", function()
    it("edits a new .tmp/scratch/scratch.md without asking when the project has none", function()
      scratch.open()
      assert.is_nil(offered)
      assert.equal(vim.fs.joinpath(dir, "scratch.md"), vim.api.nvim_buf_get_name(0))
      assert.equal(1, vim.fn.filereadable(vim.fs.joinpath(dir, "scratch.md")))
    end)

    it("offers a new file first, then the scratch files newest first", function()
      local old = write("old.md", 100)
      local new = write("new.md", 300)
      local mid = write("mid.md", 200)
      scratch.open()
      ---@cast offered -nil
      assert.equal(4, #offered)
      assert.same({ new, mid, old }, vim.list_slice(offered, 2))
    end)

    it("edits the picked scratch file in the current window", function()
      write("a.md", 200)
      local b = write("b.md", 100)
      local win = vim.api.nvim_get_current_win()
      pick = 3
      scratch.open()
      settle()
      assert.equal(win, vim.api.nvim_get_current_win())
      assert.equal(b, vim.api.nvim_buf_get_name(0))
    end)

    it("creates a markdown scratch file with the typed name", function()
      write("scratch.md", 100)
      pick, typed = 1, "api-notes"
      scratch.open()
      settle()
      assert.equal(vim.fs.joinpath(dir, "api-notes.md"), vim.api.nvim_buf_get_name(0))
      assert.equal(1, vim.fn.filereadable(vim.fs.joinpath(dir, "api-notes.md")))
    end)

    it("keeps the extension of a typed name that has one", function()
      write("scratch.md", 100)
      pick, typed = 1, "notes.txt"
      scratch.open()
      settle()
      assert.equal(vim.fs.joinpath(dir, "notes.txt"), vim.api.nvim_buf_get_name(0))
    end)

    it("opens an existing scratch file of the typed name without emptying it", function()
      write("scratch.md", 100)
      write("notes.md", 200, { "keep" })
      pick, typed = 1, "notes"
      scratch.open()
      settle()
      assert.equal(vim.fs.joinpath(dir, "notes.md"), vim.api.nvim_buf_get_name(0))
      assert.same({ "keep" }, vim.fn.readfile(vim.fs.joinpath(dir, "notes.md")))
    end)

    it("numbers a new scratch file past the taken names when no name is typed", function()
      write("scratch.md", 100)
      write("scratch-2.md", 200)
      pick, typed = 1, ""
      scratch.open()
      settle()
      assert.equal(vim.fs.joinpath(dir, "scratch-3.md"), vim.api.nvim_buf_get_name(0))
    end)

    it("leaves the window alone when the picker is cancelled", function()
      write("scratch.md", 100)
      local name = vim.api.nvim_buf_get_name(0)
      scratch.open()
      settle()
      assert.equal(name, vim.api.nvim_buf_get_name(0))
    end)

    it("creates nothing when the name prompt is cancelled", function()
      write("scratch.md", 100)
      local name = vim.api.nvim_buf_get_name(0)
      pick = 1
      scratch.open()
      settle()
      assert.equal(name, vim.api.nvim_buf_get_name(0))
      assert.equal(1, #vim.fn.readdir(dir))
    end)
  end)

  describe("float", function()
    it("shows a new .tmp/scratch/scratch.md in a float when the project has none", function()
      scratch.float()
      assert.is_true(is_float(0))
      assert.equal(vim.fs.joinpath(dir, "scratch.md"), vim.api.nvim_buf_get_name(0))
    end)

    it("shows the picked scratch file in a float", function()
      write("a.md", 200)
      local b = write("b.md", 100)
      pick = 3
      scratch.float()
      settle()
      assert.is_true(is_float(0))
      assert.equal(b, vim.api.nvim_buf_get_name(0))
    end)

    it("hands focus back to the window it was opened from when the float closes", function()
      write("a.md", 100)
      vim.cmd("vsplit | wincmd l")
      local win = vim.api.nvim_get_current_win()
      pick = 2
      scratch.float()
      settle()
      vim.cmd.close()
      assert.equal(win, vim.api.nvim_get_current_win())
    end)

    it("reuses the open float instead of stacking a second one", function()
      scratch.float()
      local win = vim.api.nvim_get_current_win()
      assert.equal(1, float_count())

      -- Move focus out of the float, then re-invoke: we should land back in it.
      vim.api.nvim_set_current_win(vim.fn.win_getid(1))
      pick = 2
      scratch.float()
      settle()
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
end)

vim.opt.rtp:prepend(require("support.deps").path("mini.pick"))
require("mini.pick").setup()
require("plugins.mini-pickers.preview").setup()

local scratch = require("plugins.scratch")

describe("scratch", function()
  local cwd
  ---@type string
  local tmpdir
  ---@type string
  local dir
  local input
  ---What the name prompt answers with; nil cancels it.
  ---@type string?
  local typed
  ---Whether a picker opened.
  local asked

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

  ---The side preview float of the open picker, skipping the picker's own window
  ---and the filename labels incline draws over floats.
  ---@return integer?
  local function preview_win()
    local main = assert(MiniPick.get_picker_state()).windows.main
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if win ~= main and is_float(win) and vim.bo[buf].filetype ~= "incline" then
        return win
      end
    end
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

  ---Call `start`, which may open the picker, and run `steps` against it.
  ---
  ---The picker blocks `start` until it stops, so each step runs from a timer
  ---the picker's key loop fires while it waits for input. A step is keys to
  ---type or a function to call. A picker still open after the last step, or
  ---after a step fails, is stopped so the spec can't hang on it.
  ---@param start fun()
  ---@param steps (string|fun())[]
  local function drive(start, steps)
    local i, returned = 0, false
    ---@type any
    local err
    local function step()
      i = i + 1
      local s = steps[i]
      if returned then
        return
      elseif s == nil then
        return MiniPick.stop()
      end
      local ok, e = pcall(function()
        if type(s) == "string" then
          vim.api.nvim_input(s)
        else
          s()
        end
      end)
      if not ok then
        err = e
        return MiniPick.stop()
      end
      vim.defer_fn(step, 50)
    end
    vim.defer_fn(step, 50)
    start()
    returned = true
    settle()
    if err then
      error(err, 0)
    end
  end

  before_each(function()
    cwd = vim.fn.getcwd()
    tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")
    vim.cmd.cd(tmpdir)
    dir = vim.fs.joinpath(vim.fn.getcwd(), ".tmp", "scratch")

    typed, asked = nil, false
    input = vim.ui.input
    vim.ui.input = function(_, on_confirm)
      on_confirm(typed)
    end
    vim.api.nvim_create_autocmd("User", {
      group = vim.api.nvim_create_augroup("scratch_spec", { clear = true }),
      pattern = "MiniPickStart",
      callback = function()
        asked = true
      end,
    })
  end)

  after_each(function()
    vim.ui.input = input
    vim.api.nvim_del_augroup_by_name("scratch_spec")
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if is_float(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
    vim.cmd("silent! tabonly!")
    vim.cmd("silent! only!")
    vim.cmd("silent! %bwipeout!")
    vim.cmd.cd(cwd)
    vim.fn.delete(tmpdir, "rf")
  end)

  describe("open", function()
    it("edits a new .tmp/scratch/scratch.md without asking when the project has none", function()
      drive(scratch.open, {})
      assert.is_false(asked)
      assert.equal(vim.fs.joinpath(dir, "scratch.md"), vim.api.nvim_buf_get_name(0))
      assert.equal(1, vim.fn.filereadable(vim.fs.joinpath(dir, "scratch.md")))
    end)

    it("offers a new file first, then the scratch files newest first", function()
      local old = write("old.md", 100)
      local new = write("new.md", 300)
      local mid = write("mid.md", 200)
      ---@type scratch.Item[]
      local items = {}
      drive(scratch.open, {
        function()
          items = assert(MiniPick.get_picker_items())
        end,
      })
      assert.equal(4, #items)
      assert.is_nil(assert(items[1]).path)
      assert.same(
        { new, mid, old },
        vim.tbl_map(function(item)
          return item.path
        end, vim.list_slice(items, 2))
      )
    end)

    it("previews the scratch file under the cursor", function()
      write("notes.md", 100, { "first line" })
      local seen = {}
      drive(scratch.open, {
        function()
          local win = assert(preview_win(), "no preview float")
          seen.new = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
        end,
        "<C-n>",
        function()
          local win = assert(preview_win(), "no preview float")
          seen.file = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, 1, false)[1]
        end,
      })
      assert.same({ "" }, seen.new)
      assert.equal("first line", seen.file)
    end)

    it("edits the picked scratch file in the window it was opened from", function()
      write("a.md", 200)
      local b = write("b.md", 100)
      vim.cmd("vsplit | wincmd l")
      local win = vim.api.nvim_get_current_win()
      drive(scratch.open, { "<C-n><C-n><CR>" })
      assert.equal(win, vim.api.nvim_get_current_win())
      assert.equal(b, vim.api.nvim_buf_get_name(0))
    end)

    it("creates a markdown scratch file with the typed name", function()
      write("scratch.md", 100)
      typed = "api-notes"
      drive(scratch.open, { "<CR>" })
      assert.equal(vim.fs.joinpath(dir, "api-notes.md"), vim.api.nvim_buf_get_name(0))
      assert.equal(1, vim.fn.filereadable(vim.fs.joinpath(dir, "api-notes.md")))
    end)

    it("keeps the extension of a typed name that has one", function()
      write("scratch.md", 100)
      typed = "notes.txt"
      drive(scratch.open, { "<CR>" })
      assert.equal(vim.fs.joinpath(dir, "notes.txt"), vim.api.nvim_buf_get_name(0))
    end)

    it("opens an existing scratch file of the typed name without emptying it", function()
      write("scratch.md", 100)
      write("notes.md", 200, { "keep" })
      typed = "notes"
      drive(scratch.open, { "<CR>" })
      assert.equal(vim.fs.joinpath(dir, "notes.md"), vim.api.nvim_buf_get_name(0))
      assert.same({ "keep" }, vim.fn.readfile(vim.fs.joinpath(dir, "notes.md")))
    end)

    it("numbers a new scratch file past the taken names when no name is typed", function()
      write("scratch.md", 100)
      write("scratch-2.md", 200)
      typed = ""
      drive(scratch.open, { "<CR>" })
      assert.equal(vim.fs.joinpath(dir, "scratch-3.md"), vim.api.nvim_buf_get_name(0))
    end)

    it("leaves the window alone when the picker is cancelled", function()
      write("scratch.md", 100)
      local name = vim.api.nvim_buf_get_name(0)
      drive(scratch.open, { "<Esc>" })
      assert.equal(name, vim.api.nvim_buf_get_name(0))
    end)

    it("creates nothing when the name prompt is cancelled", function()
      write("scratch.md", 100)
      local name = vim.api.nvim_buf_get_name(0)
      drive(scratch.open, { "<CR>" })
      assert.equal(name, vim.api.nvim_buf_get_name(0))
      assert.equal(1, #vim.fn.readdir(dir))
    end)
  end)

  describe("float", function()
    it("shows a new .tmp/scratch/scratch.md in a float when the project has none", function()
      drive(scratch.float, {})
      assert.is_true(is_float(0))
      assert.equal(vim.fs.joinpath(dir, "scratch.md"), vim.api.nvim_buf_get_name(0))
    end)

    it("shows the picked scratch file in a float", function()
      write("a.md", 200)
      local b = write("b.md", 100)
      drive(scratch.float, { "<C-n><C-n><CR>" })
      assert.is_true(is_float(0))
      assert.equal(b, vim.api.nvim_buf_get_name(0))
    end)

    it("hands focus back to the window it was opened from when the float closes", function()
      write("a.md", 100)
      vim.cmd("vsplit | wincmd l")
      local win = vim.api.nvim_get_current_win()
      drive(scratch.float, { "<C-n><CR>" })
      vim.cmd.close()
      assert.equal(win, vim.api.nvim_get_current_win())
    end)

    it("reuses the open float instead of stacking a second one", function()
      drive(scratch.float, {})
      local win = vim.api.nvim_get_current_win()
      assert.equal(1, float_count())

      -- Move focus out of the float, then re-invoke: we should land back in it.
      vim.api.nvim_set_current_win(vim.fn.win_getid(1))
      drive(scratch.float, { "<C-n><CR>" })
      assert.equal(1, float_count())
      assert.equal(win, vim.api.nvim_get_current_win())
    end)

    it("sizes the float to 80% of the editor", function()
      drive(scratch.float, {})
      local cfg = vim.api.nvim_win_get_config(0)
      assert.equal(math.floor(vim.o.columns * 0.8), cfg.width)
      assert.equal(math.floor(vim.o.lines * 0.8), cfg.height)
    end)
  end)

  describe("tab", function()
    it("edits the picked scratch file in a new tab", function()
      local first = vim.api.nvim_get_current_tabpage()
      drive(scratch.tab, {})
      assert.equal(2, #vim.api.nvim_list_tabpages())
      assert.are_not.equal(first, vim.api.nvim_get_current_tabpage())
      assert.equal(vim.fs.joinpath(dir, "scratch.md"), vim.api.nvim_buf_get_name(0))
    end)

    it("goes to the window already showing the picked file instead of opening another tab", function()
      drive(scratch.tab, {})
      local win = vim.api.nvim_get_current_win()
      vim.cmd.tabfirst()
      drive(scratch.tab, { "<C-n><CR>" })
      assert.equal(2, #vim.api.nvim_list_tabpages())
      assert.equal(win, vim.api.nvim_get_current_win())
    end)
  end)

  describe("is_scratch", function()
    it("tells a file under a project's .tmp/scratch/ from any other", function()
      assert.is_true(scratch.is_scratch(vim.fs.joinpath(dir, "notes.md")))
      assert.is_false(scratch.is_scratch(vim.fs.joinpath(tmpdir, "notes.md")))
    end)
  end)
end)

local windows = require("helpers.windows")

describe("windows.reveal_cursor", function()
  local buf, win

  before_each(function()
    buf = vim.api.nvim_create_buf(false, true)
    local lines = {}
    for i = 1, 200 do
      lines[i] = "line " .. i
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    win = vim.api.nvim_open_win(buf, true, { relative = "editor", row = 0, col = 0, width = 40, height = 20 })
    vim.wo[win].scrolloff = 0
    vim.wo[win].foldmethod = "manual"
  end)

  after_each(function()
    vim.api.nvim_win_close(win, true)
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  ---Reveal line `lnum` of the 20-line window.
  ---@param lnum integer
  ---@return integer[] view The window's top line and the cursor's screen row.
  local function reveal(lnum)
    vim.api.nvim_win_set_cursor(win, { lnum, 0 })
    windows.reveal_cursor()
    return { vim.fn.line("w0"), vim.fn.winline() }
  end

  it("puts the cursor line 30% down the window", function()
    assert.same({ 95, 6 }, reveal(100))
  end)

  it("counts a closed fold above the cursor as one screen line", function()
    vim.cmd("90,98fold")

    assert.same({ 87, 6 }, reveal(100))
  end)

  it("keeps 'scrolloff' lines above the cursor when 30% is fewer", function()
    vim.wo[win].scrolloff = 8

    assert.same({ 92, 9 }, reveal(100))
  end)

  it("stops at the top of the buffer", function()
    assert.same({ 1, 3 }, reveal(3))
  end)

  it("scrolls without feeding keys, which on_key listeners would take for typing", function()
    local ns = vim.api.nvim_create_namespace("windows_spec")
    local keys = {}
    vim.on_key(function(key)
      table.insert(keys, key)
    end, ns)

    reveal(100)
    vim.on_key(nil, ns)

    assert.same({}, keys)
  end)
end)

describe("windows.resize", function()
  before_each(function()
    vim.o.laststatus = 3
  end)

  after_each(function()
    vim.cmd("only")
  end)

  ---Three columns of three windows each, cursor in the top-left one.
  local function grid()
    vim.cmd("vsplit | vsplit")
    for _ = 1, 3 do
      vim.cmd("split | split | wincmd l")
    end
    vim.cmd("wincmd t")
  end

  ---The current window's outermost rows and columns.
  ---@return table<string, integer>
  local function edges()
    local row, col = unpack(vim.api.nvim_win_get_position(0))
    return {
      top = row,
      bottom = row + vim.api.nvim_win_get_height(0) - 1,
      left = col,
      right = col + vim.api.nvim_win_get_width(0) - 1,
    }
  end

  ---How far each edge of the current window moves when `dir` is resized.
  ---@param dir string
  ---@return table<string, integer>
  local function moved(dir)
    local before = edges()
    windows.resize(dir)
    local after = edges()
    local delta = {}
    for edge, pos in pairs(after) do
      if pos ~= before[edge] then
        delta[edge] = pos - before[edge]
      end
    end
    return delta
  end

  for dir, want in pairs({ h = { left = -1 }, j = { bottom = 1 }, k = { top = -1 }, l = { right = 1 } }) do
    it(("%s pushes the edge on that side outward when a window lies there"):format(dir), function()
      grid()
      vim.cmd("wincmd j | wincmd l")

      assert.same(want, moved(dir))
    end)
  end

  for dir, want in pairs({ h = { right = -1 }, j = { top = 1 }, k = { bottom = -1 }, l = { left = 1 } }) do
    it(("%s pulls the opposite edge along at the screen's %s border"):format(dir, dir), function()
      grid()
      vim.cmd(({ h = "wincmd t", k = "wincmd t", j = "wincmd b", l = "wincmd b" })[dir])

      assert.same(want, moved(dir))
    end)
  end

  it("leaves a lone window and 'cmdheight' as they are", function()
    local cmdheight = vim.o.cmdheight

    for _, dir in ipairs({ "h", "j", "k", "l" }) do
      assert.same({}, moved(dir))
    end
    assert.equal(cmdheight, vim.o.cmdheight)
  end)
end)

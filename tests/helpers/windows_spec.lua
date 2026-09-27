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

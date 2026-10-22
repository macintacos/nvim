describe("cursorline", function()
  before_each(function()
    require("config.cursorline")
    vim.o.columns = 40
    vim.wo.breakindent = true
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "    " .. string.rep("word ", 20) })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
  end)

  it("paints the breakindent of a wrapped cursor line", function()
    vim.wo.cursorline = true
    vim.cmd("redraw!")
    assert.equal(vim.fn.screenattr(2, 5), vim.fn.screenattr(2, 1))
  end)

  it("leaves the breakindent bare without 'cursorline'", function()
    vim.wo.cursorline = false
    vim.cmd("redraw!")
    assert.equal(0, vim.fn.screenattr(2, 1))
  end)

  -- Needs a fresh Neovim, splitting in its first command: any earlier command
  -- draws the screen, and only a split before that first draw shows the bug.
  it("skips a window drawn mid-split, before its cursor has a line", function()
    local root = vim.fn.fnamemodify(assert(debug.getinfo(1, "S")).source:sub(2), ":p:h:h:h")
    local split = [[lua require("config.cursorline")
      vim.o.cursorline = true
      vim.api.nvim_create_autocmd("WinLeave", { command = "redraw" })
      vim.cmd.split()]]
    local cmd = { vim.v.progpath, "-u", "NONE", "-i", "NONE", "--headless", "--cmd", "set rtp^=" .. root }
    vim.list_extend(cmd, { "-c", split, "-c", "qa!" })
    local result = vim.system(cmd, { text = true }):wait(10000)
    assert.equal("", result.stderr)
  end)
end)

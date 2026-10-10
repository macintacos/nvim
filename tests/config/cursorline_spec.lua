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
end)

require("config.keymaps")

---Press keys through the real mappings and report any error they raised.
---@param keys string
---@return string errmsg
local function press(keys)
  vim.v.errmsg = ""
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "x", false)
  return vim.v.errmsg
end

---@param cursor integer Line to start on
local function buffer(cursor)
  vim.cmd("enew!")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b", "c" })
  vim.fn.cursor(cursor, 1)
end

describe("move lines", function()
  it("does nothing at the bottom of the buffer", function()
    buffer(3)
    assert.equal("", press("J"))
    assert.same({ "a", "b", "c" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)

  it("does nothing at the top of the buffer", function()
    buffer(1)
    assert.equal("", press("K"))
    assert.same({ "a", "b", "c" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)

  it("does nothing for a selection at the bottom of the buffer", function()
    buffer(3)
    assert.equal("", press("VJ<Esc>"))
    assert.same({ "a", "b", "c" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)

  it("does nothing for a selection at the top of the buffer", function()
    buffer(1)
    assert.equal("", press("VK<Esc>"))
    assert.same({ "a", "b", "c" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)

  it("stops at the bottom when the count overshoots it", function()
    buffer(1)
    assert.equal("", press("5J"))
    assert.same({ "b", "c", "a" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)

  it("still swaps neighbouring lines", function()
    buffer(1)
    assert.equal("", press("J"))
    assert.same({ "b", "a", "c" }, vim.api.nvim_buf_get_lines(0, 0, -1, false))
  end)
end)

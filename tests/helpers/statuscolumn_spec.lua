local statuscolumn = require("helpers.statuscolumn")

---Fill the current window with a single line long enough to wrap `rows` times.
---@param rows integer
local function wrap_line_over(rows)
  vim.wo.wrap = true
  vim.wo.number, vim.wo.signcolumn, vim.wo.foldcolumn = false, "no", "0"
  local width = vim.api.nvim_win_get_width(0)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { string.rep("x", width * rows - 1) })
end

describe("statuscolumn.wrap_mark", function()
  before_each(function()
    vim.cmd("enew!")
  end)

  it("stems every wrapped row but the last, which gets the elbow", function()
    wrap_line_over(3)
    assert.equal("│", statuscolumn.wrap_mark(1, 1))
    assert.equal("╰", statuscolumn.wrap_mark(1, 2))
  end)

  it("puts the elbow on the last text row, not on trailing virtual lines", function()
    wrap_line_over(3)
    local ns = vim.api.nvim_create_namespace("statuscolumn_spec")
    vim.api.nvim_buf_set_extmark(0, ns, 0, 0, { virt_lines = { { { "virt" } } } })
    assert.equal("╰", statuscolumn.wrap_mark(1, 2))
  end)
end)

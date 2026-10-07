local statuscolumn = require("helpers.statuscolumn")

---Fill the current window with one line long enough to wrap several times.
---@return integer last Index of the line's last wrapped row (a |v:virtnum|)
local function wrapped_line()
  vim.wo.wrap = true
  vim.wo.number, vim.wo.signcolumn, vim.wo.foldcolumn = true, "no", "0"
  local width = vim.api.nvim_win_get_width(0)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { string.rep("x", width * 3) })
  local height = vim.api.nvim_win_text_height(0, { start_row = 0, end_row = 0 })
  return height.all - height.fill - 1
end

describe("statuscolumn.line_number", function()
  before_each(function()
    vim.cmd("enew!")
    vim.wo.relativenumber = false
  end)

  it("pads to 'numberwidth' less the space and separator the column adds around it", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b" })
    vim.wo.numberwidth = 7

    assert.equal("    2", statuscolumn.line_number(2, 0))
  end)

  it("grows to fit the buffer's highest line number while 'numberwidth' is short of it", function()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.fn["repeat"]({ "x" }, 1000))
    vim.wo.numberwidth = 4

    assert.equal("   12", statuscolumn.line_number(12, 0))
  end)
end)

describe("statuscolumn.numberwidth", function()
  it("fits the highest line number and a space, plus the space and separator the column adds", function()
    assert.same(
      { 4, 6, 7 },
      { statuscolumn.numberwidth(1), statuscolumn.numberwidth(863), statuscolumn.numberwidth(1000) }
    )
  end)
end)

describe("statuscolumn.wrap_mark", function()
  before_each(function()
    vim.cmd("enew!")
  end)

  it("stems every wrapped row but the last, which gets the elbow", function()
    local last = wrapped_line()
    assert.is_true(last >= 2)
    assert.equal("│", statuscolumn.wrap_mark(1, last - 1))
    assert.equal("╰", statuscolumn.wrap_mark(1, last))
  end)

  it("puts the elbow on the last text row, not on trailing virtual lines", function()
    local last = wrapped_line()
    local ns = vim.api.nvim_create_namespace("statuscolumn_spec")
    vim.api.nvim_buf_set_extmark(0, ns, 0, 0, { virt_lines = { { { "virt" } } } })
    assert.equal("╰", statuscolumn.wrap_mark(1, last))
  end)
end)

describe("statuscolumn.fold", function()
  local OPEN, CLOSED = "%#FoldColumn#v%*", "%#FoldColumn#>%*"

  -- An open fold over lines 1 and 2, a closed one over lines 3 and 4, and line 5 in neither.
  before_each(function()
    vim.cmd("enew!")
    vim.opt.fillchars:append({ foldopen = "v", foldclose = ">" })
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b", "c", "d", "e" })
    vim.wo.foldmethod = "manual"
    vim.cmd("1,2fold | 3,4fold | 1foldopen")
  end)

  after_each(function()
    package.loaded.changeset = nil
  end)

  it("draws each fold's chevron on its first line, in FoldColumn over the row's own background", function()
    assert.same({ OPEN, CLOSED }, { statuscolumn.fold(1, 0), statuscolumn.fold(3, 0) })
  end)

  it("draws a blank, which takes the row's number highlight, on a line no fold starts on", function()
    assert.same({ " ", " " }, { statuscolumn.fold(2, 0), statuscolumn.fold(5, 0) })
  end)

  it("draws the chevron when changeset isn't loaded", function()
    assert.equal(OPEN, statuscolumn.fold(1, 0))
  end)

  it("draws the chevron when changeset has no bubble lookup", function()
    package.loaded.changeset = {}
    assert.equal(OPEN, statuscolumn.fold(1, 0))
  end)

  it("draws a line's review comment bubble in its highlight", function()
    package.loaded.changeset = {
      bubble = function(buf, lnum)
        if buf == 0 and lnum == 3 then
          return "󰍩", "ChangesetReviewComment"
        end
      end,
    }
    assert.equal("%#ChangesetReviewComment#󰍩%*", statuscolumn.fold(3, 0))
    assert.equal(OPEN, statuscolumn.fold(1, 0))
  end)

  it("draws a blank on a wrapped row of a line with a bubble and a chevron", function()
    package.loaded.changeset = {
      bubble = function()
        return "󰍩", "ChangesetReviewComment"
      end,
    }
    assert.equal(" ", statuscolumn.fold(1, 1))
  end)
end)

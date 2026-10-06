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
  after_each(function()
    package.loaded.changeset = nil
  end)

  it("draws the fold marker when changeset isn't loaded", function()
    assert.equal("%C", statuscolumn.fold(1, 0))
  end)

  it("draws the fold marker when changeset has no bubble lookup", function()
    package.loaded.changeset = {}
    assert.equal("%C", statuscolumn.fold(1, 0))
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
    assert.equal("%C", statuscolumn.fold(2, 0))
  end)

  it("draws the fold marker on a wrapped row of a line with a bubble", function()
    package.loaded.changeset = {
      bubble = function()
        return "󰍩", "ChangesetReviewComment"
      end,
    }
    assert.equal("%C", statuscolumn.fold(3, 1))
  end)
end)

local render = require("plugins.mini-pickers.render")

---A float holding `lines`, with a `virt_lines_above` mark on its first line.
---@param lines string[]
---@return integer win, integer buf
local function float_with_trail(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = 1,
    col = 1,
    width = 40,
    height = 6,
    style = "minimal",
  })
  vim.wo[win].wrap = false
  vim.wo[win].scrolloff = 0
  vim.api.nvim_buf_set_extmark(buf, render.ns, 0, 0, {
    virt_lines = { { { "trail", "Comment" } } },
    virt_lines_above = true,
  })
  return win, buf
end

---@param win integer
---@return integer
local function topfill(win)
  return vim.api.nvim_win_call(win, function()
    return vim.fn.winsaveview().topfill
  end)
end

describe("mini-pickers.render", function()
  describe("reserve_trail_row", function()
    it("reserves the display row Neovim would otherwise clip the trail into, before returning", function()
      local win, buf = float_with_trail({ "one", "two", "three" })
      -- Neovim draws no filler above the topline on its own, which is exactly
      -- why a trail on the first row goes missing.
      assert.equal(0, topfill(win))

      -- Checked straight away: mini.pick draws the frame as soon as `source.show`
      -- returns, so a reservation that lands any later paints the list a row
      -- off first.
      render.reserve_trail_row(win, true)

      assert.equal(1, topfill(win))
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("releases the row when the first line carries no trail", function()
      local win, buf = float_with_trail({ "one", "two", "three" })
      render.reserve_trail_row(win, true)
      render.reserve_trail_row(win, false)

      assert.equal(0, topfill(win))
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("does not error once the window is gone", function()
      local win, buf = float_with_trail({ "one" })
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, { force = true })

      assert.has_no.errors(function()
        render.reserve_trail_row(win, true)
      end)
    end)
  end)
end)

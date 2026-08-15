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

---`reserve_trail_row` defers its work, so let the scheduled callback run.
---@param win integer
---@param want integer
local function wait_for_topfill(win, want)
  vim.wait(500, function()
    return topfill(win) == want
  end, 10)
end

describe("mini-pickers.render", function()
  describe("reserve_trail_row", function()
    it("reserves the display row Neovim would otherwise clip the trail into", function()
      local win, buf = float_with_trail({ "one", "two", "three" })
      -- Neovim draws no filler above the topline on its own, which is exactly
      -- why a trail on the first row goes missing.
      assert.equal(0, topfill(win))

      render.reserve_trail_row(win, true)
      wait_for_topfill(win, 1)

      assert.equal(1, topfill(win))
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("releases the row when the first line carries no trail", function()
      local win, buf = float_with_trail({ "one", "two", "three" })
      render.reserve_trail_row(win, true)
      wait_for_topfill(win, 1)

      render.reserve_trail_row(win, false)
      wait_for_topfill(win, 0)

      assert.equal(0, topfill(win))
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("does not error once the window is gone", function()
      local win, buf = float_with_trail({ "one" })
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, { force = true })

      render.reserve_trail_row(win, true)
      assert.has_no.errors(function()
        vim.wait(50, function()
          return false
        end, 10)
      end)
    end)
  end)
end)

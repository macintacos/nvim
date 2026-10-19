vim.opt.rtp:prepend(require("support.deps").path("mini.pick"))
require("mini.pick").setup()

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

      assert.has_no_error(function()
        render.reserve_trail_row(win, true)
      end)
    end)
  end)

  describe("show_paths", function()
    ---What a list `width` cells wide shows for `path`, its icon column left off.
    ---@param path string
    ---@param width integer
    ---@return string
    local function shown(path, width)
      local buf = vim.api.nvim_create_buf(false, true)
      local win = vim.api.nvim_open_win(buf, false, {
        relative = "editor",
        row = 1,
        col = 1,
        width = width,
        height = 1,
        style = "minimal",
      })
      render.show_paths(buf, { path }, {})

      local line = assert(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
      if vim.wo[win].conceallevel > 0 then
        for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, render.ns, 0, -1, { details = true })) do
          local details = assert(mark[4])
          if details.conceal then
            line = line:sub(1, mark[3]) .. details.conceal .. line:sub(assert(details.end_col) + 1)
          end
        end
      end
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, { force = true })
      -- mini.pick pads a path with no file behind it with a blank icon.
      return line:sub(3)
    end

    it("shows a path that fits as it is", function()
      assert.equal("lua/init.lua", shown("lua/init.lua", 20))
    end)

    it("cuts the middle of the directories so the filename stays whole", function()
      assert.equal("aaa…ccc/name.lua", shown("aaaa/bbbb/cccc/name.lua", 18))
    end)

    it("keeps the end of a filename too long to fit beside any directory", function()
      assert.equal("…gname.lua", shown("dir/averyverylongname.lua", 12))
    end)

    it("measures the path in display cells, not bytes", function()
      assert.equal("ññ…ñññ/x.lua", shown("ñññññ/ñññññ/x.lua", 14))
    end)
  end)
end)

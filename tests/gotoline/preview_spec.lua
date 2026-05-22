local preview = require("plugins.gotoline.preview")

local NS = vim.api.nvim_create_namespace("gotoline")

local function with_tempfile(contents, ext, fn)
  local path = vim.fn.tempname() .. (ext or "")
  vim.fn.writefile(contents, path)
  local ok, err = pcall(fn, path)
  vim.fn.delete(path)
  assert(ok, err)
end

local function with_buf(fn)
  local buf = vim.api.nvim_create_buf(false, true)
  local ok, err = pcall(fn, buf)
  vim.api.nvim_buf_delete(buf, { force = true })
  assert(ok, err)
end

describe("gotoline.preview", function()
  it("populates the buffer with the file contents", function()
    with_buf(function(buf)
      with_tempfile({ "first", "second", "third" }, ".txt", function(path)
        preview.render(buf, path, 1)
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        assert.same({ "first", "second", "third" }, lines)
      end)
    end)
  end)

  it("sets the buffer filetype based on extension", function()
    with_buf(function(buf)
      with_tempfile({ "local M = {}" }, ".lua", function(path)
        preview.render(buf, path, 1)
        assert.equal("lua", vim.bo[buf].filetype)
      end)
    end)
  end)

  it("places an extmark on the target line", function()
    with_buf(function(buf)
      with_tempfile({ "a", "b", "c", "d", "e" }, ".txt", function(path)
        preview.render(buf, path, 3)
        local marks = vim.api.nvim_buf_get_extmarks(buf, NS, 0, -1, {})
        local rows = {}
        for _, m in ipairs(marks) do
          rows[#rows + 1] = m[2]
        end
        assert.is_true(vim.tbl_contains(rows, 2), "extmark on row 2 (0-indexed)")
      end)
    end)
  end)

  it("returns target_row matching the requested line when in range", function()
    with_buf(function(buf)
      with_tempfile({ "1", "2", "3", "4", "5" }, ".txt", function(path)
        local result = preview.render(buf, path, 4)
        assert.equal(4, result.target_row)
      end)
    end)
  end)

  it("clamps target_row to the last line when line exceeds file length", function()
    with_buf(function(buf)
      with_tempfile({ "1", "2", "3" }, ".txt", function(path)
        local result = preview.render(buf, path, 99)
        assert.equal(3, result.target_row)
      end)
    end)
  end)

  it("handles a missing file gracefully", function()
    with_buf(function(buf)
      local missing = vim.fn.tempname() .. ".nope"
      local result = preview.render(buf, missing, 1)
      assert.is_false(result.ok)
      assert.same({ "" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    end)
  end)
end)

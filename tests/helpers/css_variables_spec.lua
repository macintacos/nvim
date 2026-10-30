local css_variables = require("helpers.css_variables")

---A scratch buffer of `filetype` holding `lines`.
---@param filetype string
---@param lines string[]
---@return integer
local function buffer(filetype, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = filetype
  return buf
end

---The labels `transform_items` keeps from one css_variables item and one other
---client's, with the cursor at `row` (1-based) and `col` (0-based) in `buf`.
---@param buf integer
---@param row integer
---@param col integer
---@return string[]
local function kept(buf, row, col)
  -- Only the fields transform_items reads.
  ---@type any
  local items = {
    { label = "--gap", client_name = "css_variables" },
    { label = "count", client_name = "svelte" },
  }
  ---@type any
  local ctx = { bufnr = buf, cursor = { row, col } }
  return vim.tbl_map(function(item)
    return item.label
  end, css_variables.transform_items(ctx, items))
end

describe("css_variables.transform_items", function()
  local component = {
    "<script>",
    "  let count = 1",
    "</script>",
    "<p>hi</p>",
    "<style>",
    "  p { gap: 1px }",
    "</style>",
  }

  after_each(function()
    vim.cmd("silent! %bwipeout!")
  end)

  it("drops the server's items in a component's script", function()
    assert.same({ "count" }, kept(buffer("svelte", component), 2, 6))
  end)

  it("drops the server's items in a component's markup", function()
    assert.same({ "count" }, kept(buffer("svelte", component), 4, 4))
  end)

  it("keeps them in a component's <style>", function()
    assert.same({ "--gap", "count" }, kept(buffer("svelte", component), 6, 8))
  end)

  it("keeps them at the very end of a style attribute's CSS", function()
    assert.same({ "--gap", "count" }, kept(buffer("svelte", { '<p style="color: var(--">' }), 1, 23))
  end)

  it("keeps them in a stylesheet of any CSS dialect", function()
    for _, filetype in ipairs({ "css", "scss", "less" }) do
      assert.same({ "--gap", "count" }, kept(buffer(filetype, { "p { gap: 1px }" }), 1, 8))
    end
  end)
end)

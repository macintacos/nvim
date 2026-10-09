local palette = require("helpers.palette")

---@param content string
---@return string
local function file_with(content)
  local path = vim.fn.tempname()
  vim.fn.writefile(vim.split(content, "\n"), path)
  return path
end

describe("palette.overrides", function()
  it("is empty when the palette file is missing", function()
    assert.same({}, palette.overrides(vim.fn.tempname()))
  end)

  it("is empty when the palette file is not valid JSON", function()
    assert.same({}, palette.overrides(file_with("{ not json")))
  end)

  it("passes each fox's palette keys and moves its diff backgrounds into the spec", function()
    local path = file_with(vim.json.encode({
      duskfox = {
        bg1 = "#232136",
        red = { base = "#ff9cb4", bright = "#feb2c5", dim = "#fe86a2" },
        ansi = { "#393552" },
        diff = { add = "#3d4148", delete = "#4f3a4f", change = "#344158", text = "#314c63" },
      },
    }))

    assert.same({
      palettes = {
        duskfox = { bg1 = "#232136", red = { base = "#ff9cb4", bright = "#feb2c5", dim = "#fe86a2" } },
      },
      specs = {
        duskfox = { diff = { add = "#3d4148", delete = "#4f3a4f", change = "#344158", text = "#314c63" } },
      },
    }, palette.overrides(path))
  end)
end)

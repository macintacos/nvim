local fixture = require("support.palette")
local palette = require("helpers.palette")

---@param group string
---@param attr string
---@return string?
local function hl(group, attr)
  local value = vim.api.nvim_get_hl(0, { name = group, link = false })[attr]
  return value and ("#%06x"):format(value)
end

---@param background "dark"|"light"
local function paint(background)
  vim.o.background = background
  vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "dracula-pro" })
end

describe("highlights", function()
  local dir, path

  before_each(function()
    dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    path = palette.PATH
    palette.PATH = fixture.write(dir)
    vim.o.termguicolors = true
    require("config.highlights")
  end)

  after_each(function()
    palette.PATH = path
    vim.fn.delete(dir, "rf")
  end)

  it("sinks Van Helsing's floats and menus below the editor", function()
    paint("dark")

    assert.equal(fixture.dark.bg0, hl("NormalFloat", "bg"))
    assert.equal(fixture.dark.bg0, hl("FloatBorder", "bg"))
    assert.equal(fixture.dark.bg0, hl("Pmenu", "bg"))
  end)

  it("keeps Alucard's floats and menus on the editor background", function()
    paint("light")

    assert.equal(fixture.light.bg1, hl("NormalFloat", "bg"))
    assert.equal(fixture.light.bg1, hl("FloatBorder", "bg"))
    assert.equal(fixture.light.bg1, hl("Pmenu", "bg"))
    assert.equal(fixture.light.bg1, hl("PmenuSbar", "bg"))
    assert.equal(fixture.light.bg1, hl("PmenuMatch", "bg"))
  end)

  it("keeps Van Helsing's strings and characters on the yellow role", function()
    paint("dark")

    assert.equal(fixture.dark.yellow.base, hl("String", "fg"))
    assert.equal(fixture.dark.yellow.base, hl("Character", "fg"))
  end)

  it("draws Alucard's strings and characters in teal", function()
    paint("light")

    assert.equal("#108881", hl("String", "fg"))
    assert.equal("#108881", hl("Character", "fg"))
  end)
end)

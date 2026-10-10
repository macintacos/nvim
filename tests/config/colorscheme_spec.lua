local fixture = require("support.palette")
local palette = require("helpers.palette")

-- Stands in for the vendored Dracula Pro scheme, which this public repo cannot ship.
-- Like Pro's base it reads g:dracula_pro#palette, names itself and forces a dark
-- background; its variants set a marker instead of loading the base.
local pro = {
  ["dracula-pro-base.vim"] = {
    "highlight clear",
    "let g:colors_name = 'dracula-pro'",
    "execute 'highlight Normal guibg=' . g:dracula_pro#palette.bg[0]",
    "set background=dark",
  },
  ["dracula-pro-van-helsing.vim"] = { "let g:pro_variant = 'van-helsing'", "set background=dark" },
  ["dracula-pro-alucard.vim"] = { "let g:pro_variant = 'alucard'", "set background=dark" },
}

---@param group string
---@param attr string
---@return string?
local function hl(group, attr)
  local value = vim.api.nvim_get_hl(0, { name = group, link = false })[attr]
  return value and ("#%06x"):format(value)
end

describe("dracula-pro colorscheme", function()
  ---@type string
  local dir
  local path, packpath

  before_each(function()
    dir = vim.fn.tempname()
    vim.fn.mkdir(dir .. "/colors", "p")
    for name, lines in pairs(pro) do
      vim.fn.writefile(lines, dir .. "/colors/" .. name)
    end
    vim.opt.rtp:append(dir)
    -- Keeps a Dracula Pro the dotfiles deployed into the real data directory out of reach.
    packpath = vim.o.packpath
    vim.o.packpath = dir
    path = palette.PATH
    palette.PATH = fixture.write(dir)
    vim.o.termguicolors = true
    vim.g.colors_name = nil
    vim.g.pro_variant = nil
  end)

  after_each(function()
    palette.PATH = path
    vim.o.packpath = packpath
    vim.opt.rtp:remove(dir)
    vim.fn.delete(dir, "rf")
  end)

  it("keeps a light background, which Pro's base forces to dark", function()
    vim.o.background = "light"
    vim.cmd.colorscheme("dracula-pro")

    assert.equal("light", vim.o.background)
  end)

  it("reloads in the other variant when the background flips", function()
    vim.o.background = "dark"
    vim.cmd.colorscheme("dracula-pro")
    vim.o.background = "light"

    assert.equal(fixture.light.bg1, hl("Normal", "bg"))
  end)

  it("loads Dracula Pro's own variant when there is no palette file", function()
    palette.PATH = vim.fn.tempname()
    vim.o.background = "light"
    vim.cmd.colorscheme("dracula-pro")

    assert.equal("alucard", vim.g.pro_variant)
    assert.equal("light", vim.o.background)
  end)

  it("falls back to the default scheme without Dracula Pro", function()
    vim.opt.rtp:remove(dir)
    vim.o.background = "dark"
    vim.api.nvim_set_hl(0, "Normal", { fg = "#123456" })
    vim.cmd.colorscheme("dracula-pro")

    assert.equal(vim.api.nvim_get_color_by_name("NvimLightGrey2"), vim.api.nvim_get_hl(0, { name = "Normal" }).fg)
  end)
end)

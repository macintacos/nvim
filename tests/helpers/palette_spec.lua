local palette = require("helpers.palette")
local fixture = require("support.palette")

---@param content string
---@return string
local function file_with(content)
  local path = vim.fn.tempname()
  vim.fn.writefile(vim.split(content, "\n"), path)
  return path
end

describe("palette.read", function()
  it("is nil when the palette file is missing", function()
    assert.is_nil(palette.read(vim.fn.tempname()))
  end)

  it("is nil when the palette file is not valid JSON", function()
    assert.is_nil(palette.read(file_with("{ not json")))
  end)

  it("returns the dark and light variants", function()
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    assert.same({ dark = fixture.dark, light = fixture.light }, palette.read(fixture.write(dir)))
    vim.fn.delete(dir, "rf")
  end)
end)

describe("palette.blend", function()
  it("mixes the given fraction of the second colour into the first", function()
    assert.equal("#404040", palette.blend("#000000", "#ffffff", 0.25))
    assert.equal("#bf4000", palette.blend("#ff0000", "#00ff00", 0.25))
  end)

  it("rejects a colour that is not hex", function()
    assert.has_error(function()
      palette.blend("not-a-colour", "#ffffff", 0.5)
    end, "not a hex colour: not-a-colour")
  end)
end)

describe("palette.dracula_pro", function()
  it("lays the dark variant onto Van Helsing's keys", function()
    local d = fixture.dark
    assert.same({
      fg = { d.fg1, "NONE" },
      bg = { d.bg1, "NONE" },
      bgdark = { d.bg0, "NONE" },
      bgdarker = { d.bg0, "NONE" },
      bglight = { d.bg2, "NONE" },
      bglighter = { d.bg3, "NONE" },
      subtle = { d.bg3, "NONE" },
      selection = { d.sel0, "NONE" },
      comment = { d.comment, "NONE" },
      red = { d.red.base, "NONE" },
      orange = { d.orange.base, "NONE" },
      yellow = { d.yellow.base, "NONE" },
      green = { d.green.base, "NONE" },
      cyan = { d.cyan.base, "NONE" },
      purple = { d.purple.base, "NONE" },
      pink = { d.pink.base, "NONE" },
      color_0 = d.ansi[1],
      color_1 = d.ansi[2],
      color_2 = d.ansi[3],
      color_3 = d.ansi[4],
      color_4 = d.ansi[5],
      color_5 = d.ansi[6],
      color_6 = d.ansi[7],
      color_7 = d.ansi[8],
      color_8 = d.ansi[9],
      color_9 = d.ansi[10],
      color_10 = d.ansi[11],
      color_11 = d.ansi[12],
      color_12 = d.ansi[13],
      color_13 = d.ansi[14],
      color_14 = d.ansi[15],
      color_15 = d.ansi[16],
    }, palette.dracula_pro(d, "dark"))
  end)

  it("lays the light variant onto Alucard's keys, whose floats and status line sit on white", function()
    local l = fixture.light
    local pro = palette.dracula_pro(l, "light")
    assert.same({ bg = l.bg1, bgdark = l.bg2, bgdarker = l.bg4, bglight = l.bg1, bglighter = l.bg0, subtle = l.bg3 }, {
      bg = pro.bg[1],
      bgdark = pro.bgdark[1],
      bgdarker = pro.bgdarker[1],
      bglight = pro.bglight[1],
      bglighter = pro.bglighter[1],
      subtle = pro.subtle[1],
    })
  end)
end)

---The tuned Duskfox/Dawnfox palette and the colours derived from it.
local M = {}

---@type string
M.PATH = vim.fn.expand("~/.config/palette/nightfox.json")

---nightfox.nvim `setup()` overrides from the palette file at `path`: each fox's
---palette, with its precomputed diff backgrounds moved into the spec. Empty, so
---the stock foxes load, when the file is missing or unreadable.
---@param path string
---@return { palettes?: table<string, table>, specs?: table<string, table> }
function M.overrides(path)
  local ok, data = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  end)
  if not ok or type(data) ~= "table" then
    return {}
  end
  local palettes, specs = {}, {}
  for fox, pal in pairs(data) do
    specs[fox] = { diff = pal.diff }
    palettes[fox] = vim.deepcopy(pal)
    palettes[fox].ansi, palettes[fox].diff = nil, nil
  end
  return { palettes = palettes, specs = specs }
end

---The fox matching 'background'.
---@return "dawnfox"|"duskfox"
function M.fox()
  return vim.o.background == "light" and "dawnfox" or "duskfox"
end

---The active fox's palette and spec, overrides included.
---@return table palette, table spec
function M.active()
  local spec = require("nightfox.spec").load(M.fox())
  return spec.palette, spec
end

---Mix `f` of colour `b` into colour `a`.
---@param a string
---@param b string
---@param f number
---@return string
function M.blend(a, b, f)
  local C = require("nightfox.lib.color")
  -- nightfox annotates its colour methods but never declares the Color class.
  ---@diagnostic disable-next-line: undefined-field
  return C.from_hex(a):blend(C.from_hex(b), f):to_css()
end

return M

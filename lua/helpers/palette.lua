---The shared palette's colour roles: Dracula Pro's Van Helsing (dark) and Alucard
---(light), as the dotfiles deploy them.
local M = {}

---@class palette.Hue
---@field base string
---@field bright string
---@field dim string

---@class palette.Roles
---@field bg0 string Floats, popups, status and title bars.
---@field bg1 string Editor background.
---@field bg2 string Colour column, folds, inactive bars.
---@field bg3 string Cursor line.
---@field bg4 string Borders, dividers, non-text.
---@field fg0 string
---@field fg1 string Body text.
---@field fg2 string
---@field fg3 string Line numbers and gutter text.
---@field sel0 string Selection.
---@field sel1 string Search matches.
---@field comment string
---@field red palette.Hue
---@field orange palette.Hue
---@field yellow palette.Hue
---@field green palette.Hue
---@field cyan palette.Hue
---@field purple palette.Hue
---@field pink palette.Hue
---@field diff { add: string, delete: string, change: string, text: string, add_text: string, delete_text: string }
---@field ansi string[]

---@type string
M.PATH = vim.fn.expand("~/.config/palette/palette.json") --[[@as string]]

---Both variants from the palette file at `path`, or nil when it is missing or
---unreadable.
---@param path string
---@return { dark: palette.Roles, light: palette.Roles }?
function M.read(path)
  local ok, data = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  end)
  if ok and type(data) == "table" then
    return data
  end
end

---The variant matching 'background', or nil without a palette file.
---@return palette.Roles?
function M.active()
  local variants = M.read(M.PATH)
  return variants and variants[vim.o.background]
end

---Mix `f` of colour `b` into colour `a`.
---@param a string
---@param b string
---@param f number
---@return string
function M.blend(a, b, f)
  local x = assert(tonumber(a:sub(2), 16), "not a hex colour: " .. a)
  local y = assert(tonumber(b:sub(2), 16), "not a hex colour: " .. b)
  local out = 0
  for _, shift in ipairs({ 65536, 256, 1 }) do
    local ca, cb = math.floor(x / shift) % 256, math.floor(y / shift) % 256
    out = out * 256 + math.floor(ca * (1 - f) + cb * f + 0.5)
  end
  return ("#%06x"):format(out)
end

---`g:dracula_pro#palette` for one variant, so Pro's own scheme draws in the palette's
---colours. Its background keys mean different roles per variant: Alucard raises
---floats and the status line (`bglighter`) to white, above the editor.
---@param roles palette.Roles
---@param background "dark"|"light"
---@return table<string, string[]|string>
function M.dracula_pro(roles, background)
  local dark = background == "dark"
  local colours = {
    fg = roles.fg1,
    bg = roles.bg1,
    bgdark = dark and roles.bg0 or roles.bg2,
    bgdarker = dark and roles.bg0 or roles.bg4,
    bglight = dark and roles.bg2 or roles.bg1,
    bglighter = dark and roles.bg3 or roles.bg0,
    subtle = roles.bg3,
    selection = roles.sel0,
    comment = roles.comment,
  }
  for _, hue in ipairs({ "red", "orange", "yellow", "green", "cyan", "purple", "pink" }) do
    colours[hue] = roles[hue].base
  end
  ---@type table<string, string[]|string>
  local pro = {}
  -- Pro pairs each colour with a cterm number; 'termguicolors' makes it unused.
  for key, colour in pairs(colours) do
    pro[key] = { colour, "NONE" }
  end
  for i, colour in ipairs(roles.ansi) do
    pro["color_" .. (i - 1)] = colour
  end
  return pro
end

return M

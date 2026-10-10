---A synthetic palette shaped like `~/.config/palette/palette.json`, which the dotfiles
---deploy. Every colour is distinct, so a spec can tell which role a highlight took.

---@param lead string First hex digit, keeping the two variants apart.
---@return palette.Roles
local function variant(lead)
  local count = 0
  local function colour()
    count = count + 1
    return ("#%s%05x"):format(lead, count)
  end
  local v = {}
  for _, role in ipairs({ "bg0", "bg1", "bg2", "bg3", "bg4", "fg0", "fg1", "fg2", "fg3", "sel0", "sel1", "comment" }) do
    v[role] = colour()
  end
  for _, hue in ipairs({ "red", "orange", "yellow", "green", "cyan", "purple", "pink" }) do
    v[hue] = { base = colour(), bright = colour(), dim = colour() }
  end
  v.diff = {
    add = colour(),
    delete = colour(),
    change = colour(),
    text = colour(),
    add_text = colour(),
    delete_text = colour(),
  }
  v.ansi = {}
  for i = 1, 16 do
    v.ansi[i] = colour()
  end
  return v --[[@as palette.Roles]]
end

local M = { dark = variant("1"), light = variant("2") }

---Write the palette as JSON into `dir`.
---@param dir string
---@return string path
function M.write(dir)
  local path = dir .. "/palette.json"
  vim.fn.writefile({ vim.json.encode({ dark = M.dark, light = M.light }) }, path)
  return path
end

return M

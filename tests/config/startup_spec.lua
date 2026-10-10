local root = vim.fn.fnamemodify(assert(debug.getinfo(1, "S")).source:sub(2), ":p:h:h:h")

-- Runs inside the booted Neovim once the scheduled and deferred plugin setup has had
-- a moment to run, then writes what it saw to the path substituted for %q.
local collector = [[
vim.defer_fn(function()
  local notices = {}
  for _, notice in pairs(MiniNotify and MiniNotify.get_all() or {}) do
    if notice.level == "ERROR" or notice.level == "WARN" then
      table.insert(notices, notice.level .. " " .. notice.msg)
    end
  end
  local messages = vim.api.nvim_exec2("messages", { output = true }).output
  vim.fn.writefile({ vim.json.encode({ messages = messages, notices = notices }) }, %q)
  vim.cmd("qa!")
end, 1500)
]]

---A collector that reports what `expr`, a Lua expression, evaluates to in the booted
---Neovim, as the report's `value`.
---@param expr string
---@return string
local function reporting(expr)
  return ([[
vim.defer_fn(function()
  vim.fn.writefile({ vim.json.encode({ value = %s }) }, %%q)
  vim.cmd("qa!")
end, 1500)
]]):format(expr)
end

---Boot this checkout's whole config headless, editing a Lua file so the plugins
---that load on FileType run too. Its palette file is `dir`'s `palette.json`.
---@param dir string Scratch directory, also the booted Neovim's cwd.
---@param probe? string Collector to run instead of the default; `%q` is the report path.
---@param args? string[] Startup arguments, run before the collector.
---@return table report
local function boot(dir, probe, args)
  local report = dir .. "/report.json"
  vim.fn.writefile(vim.split((probe or collector):format(report), "\n"), dir .. "/collect.lua")
  local config = vim.fn.stdpath("config")
  local rtp = ("lua vim.opt.rtp:remove({ %q, %q }); vim.opt.rtp:prepend(%q); vim.opt.rtp:append(%q)"):format(
    config,
    config .. "/after",
    root,
    root .. "/after"
  )
  -- minimal_init moved XDG_STATE_HOME to a temp dir, where mise's shims would find
  -- no trust record and refuse to run the tools the config starts.
  local env = vim.fn.environ()
  env.XDG_STATE_HOME = nil

  local cmd = {
    vim.v.progpath,
    "--headless",
    "-i",
    "NONE",
    "-n",
    "--cmd",
    rtp,
    "--cmd",
    ("lua require('helpers.palette').PATH = %q"):format(dir .. "/palette.json"),
    "-u",
    root .. "/init.lua",
  }
  vim.list_extend(cmd, args or {})
  vim.list_extend(cmd, { "-c", "luafile " .. dir .. "/collect.lua", dir .. "/probe.lua" })

  local result = vim.system(cmd, { cwd = dir, env = env, clear_env = true, text = true }):wait(30000)
  assert.equal(0, result.code, result.stderr)

  local seen = vim.json.decode(table.concat(vim.fn.readfile(report), "\n"))
  seen.stderr = result.stderr
  return seen
end

-- Pairs each highlight attribute the config paints with the palette role it should
-- carry (or a colour per background, where a variant leaves the palette), as startup
-- leaves it and under both backgrounds, so a palette retune or a scheme swap cannot
-- drift them apart. The synthetic palette sits in the booted
-- Neovim's cwd.
local palette_probe = [[
vim.defer_fn(function()
  local function hex(n) return type(n) == "number" and ("#%%06x"):format(n) or tostring(n or "none") end
  local variants = vim.json.decode(table.concat(vim.fn.readfile(vim.fn.getcwd() .. "/palette.json"), "\n"))
  local checks = {
    { "MiniPickMatchCurrent", "bg", "sel0" },
    { "MiniPickMatchRanges", "fg", "cyan.base" },
    { "LinkHover", "bg", "sel0" },
    { "LinkHoverIcon", "fg", "cyan.base" },
    { "FlashYank", "bg", "green.base" },
    { "FlashPaste", "bg", "purple.base" },
    { "ModesInsertCursor", "bg", "green.base" },
    { "ModesReplaceCursor", "bg", "orange.base" },
    { "ModesVisualCursor", "bg", "pink.base" },
    { "MiniStatuslineModeVisual", "fg", "bg1" },
    { "MiniStatuslineModeVisual", "bg", "pink.base" },
    { "ModesVisualVisual", "bg", "sel0" },
    { "LineNr", "fg", "fg3" },
    { "FoldColumn", "fg", "fg3" },
    { "NonText", "fg", "bg4" },
    { "WinSeparator", "fg", "bg4" },
    { "FloatBorder", "fg", "bg4" },
    { "StatusLine", "bg", "bg0" },
    { "Search", "bg", "sel1" },
    { "DiffAdd", "bg", "diff.add" },
    { "DiffText", "bg", "diff.text" },
    { "GitSignsAdd", "fg", "green.base" },
    { "@markup.heading", "fg", "purple.base" },
    { "@markup.heading", "bold", true },
    { "@markup.strong", "fg", "orange.base" },
    { "@markup.strong", "bold", true },
    { "@markup.italic", "fg", "yellow.base" },
    { "@markup.italic", "italic", true },
    { "@markup.raw", "fg", "green.base" },
    { "@markup.link.label", "fg", "pink.base" },
    { "@markup.link.url", "fg", "cyan.base" },
    { "@markup.list", "fg", "cyan.base" },
    { "RenderMarkdownBullet", "fg", "cyan.base" },
    { "String", "fg", { dark = "yellow.base", light = "#108881" } },
    { "@string", "fg", { dark = "yellow.base", light = "#108881" } },
    { "Character", "fg", { dark = "yellow.base", light = "#108881" } },
    { "@character", "fg", { dark = "yellow.base", light = "#108881" } },
    { "@string.regexp", "fg", "red.base" },
    { "@string.regex", "fg", "red.base" },
    { "@exception", "fg", "pink.base" },
    { "@lsp.type.namespace", "fg", "pink.base" },
    { "@lsp.type.typeParameter", "fg", "cyan.base" },
    { "@lsp.type.typeParameter", "italic", true },
    { "BlinkCmpLabelMatch", "fg", "cyan.base" },
    { "BlinkCmpMenuBorder", "fg", "bg4" },
    { "BlinkCmpDocBorder", "fg", "bg4" },
    { "BlinkCmpSignatureHelpBorder", "fg", "bg4" },
    { "ColorColumn", "bg", "bg2" },
    { "Folded", "bg", "bg2" },
    { "TabLine", "bg", "bg2" },
    { "TabLineFill", "bg", "bg2" },
    { "PmenuThumb", "bg", "bg4" },
    { "RenderMarkdownDash", "fg", "comment" },
    { "Added", "fg", "green.base" },
    { "Removed", "fg", "red.base" },
    { "@property.json", "fg", "cyan.base" },
    { "@keyword.json5", "fg", "cyan.base" },
    { "@property.yaml", "fg", "cyan.base" },
    { "@property.toml", "fg", "cyan.base" },
    { "@property.git_config", "fg", "cyan.base" },
    { "@property.kdl", "fg", "cyan.base" },
    { "@string.special.url", "fg", "cyan.base" },
    { "@string.special.url", "underline", true },
    { "@function.macro", "fg", "green.base" },
    { "@lsp.type.macro", "fg", "green.base" },
  }
  ---A parsed scratch buffer in `filetype`.
  local function parsed(filetype, lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
    vim.bo[buf].filetype = filetype
    vim.treesitter.get_parser(buf):parse(true)
    return buf
  end
  local diff = parsed("diff", { "--- a/f.lua", "+++ b/f.lua", "@@ -1 +1 @@", "-a = 1", "+a = 2" })
  local json = parsed("json", { '{ "key": 1 }' })
  local toml = parsed("toml", { '"quoted key" = 1' })
  -- A character as treesitter draws it.
  local drawn_checks = {
    { "diff ---", diff, 0, 0, "fg", "fg0" },
    { "diff ---", diff, 0, 0, "bold", true },
    { "diff +++", diff, 1, 0, "fg", "fg0" },
    { "diff +++", diff, 1, 0, "bold", true },
    { "diff @@", diff, 2, 0, "fg", "cyan.base" },
    { "diff @@", diff, 2, 0, "italic", true },
    { "diff -", diff, 3, 0, "fg", "red.base" },
    { "diff +", diff, 4, 0, "fg", "green.base" },
    { "json key", json, 0, 3, "fg", "cyan.base" },
    { "toml quoted key", toml, 0, 0, "fg", "cyan.base" },
  }
  -- The highest-priority capture at a position, which draws over the others.
  local function drawn(buf, row, col)
    local top, name
    for _, capture in ipairs(vim.treesitter.get_captures_at_pos(buf, row, col)) do
      local priority = tonumber(capture.metadata.priority) or vim.hl.priorities.treesitter
      if not top or priority >= top then
        top, name = priority, "@" .. capture.capture .. "." .. capture.lang
      end
    end
    return vim.api.nvim_get_hl(0, { name = name, link = false })
  end

  local pairs_seen = { { "scheme at startup", tostring(vim.g.colors_name), "dracula-pro" } }
  local function expect(label, got, want, bg)
    if type(want) == "table" then
      want = want[bg]
    end
    if type(want) == "string" and not vim.startswith(want, "#") then
      want = vim.tbl_get(variants[bg], unpack(vim.split(want, ".", { plain = true })))
    end
    table.insert(pairs_seen, { label, hex(got), tostring(want):lower() })
  end
  local function check_all(label, bg)
    for _, check in ipairs(checks) do
      local group, attr, want = unpack(check)
      expect(label .. " " .. group .. "." .. attr, vim.api.nvim_get_hl(0, { name = group, link = false })[attr], want, bg)
    end
    for _, check in ipairs(drawn_checks) do
      local what, buf, row, col, attr, want = unpack(check)
      expect(label .. " " .. what .. " " .. attr, drawn(buf, row, col)[attr], want, bg)
    end
  end

  check_all("startup " .. vim.o.background, vim.o.background)
  for _, bg in ipairs({ "dark", "light" }) do
    vim.o.background = bg
    vim.cmd.colorscheme("dracula-pro")
    check_all(bg, bg)
  end
  local heading_bgs = require("render-markdown.state").get(0).heading.backgrounds
  table.insert(pairs_seen, { "render-markdown heading backgrounds", vim.inspect(heading_bgs), "{}" })
  vim.fn.writefile({ vim.json.encode({ pairs = pairs_seen }) }, %q)
  vim.cmd("qa!")
end, 1500)
]]

-- Whether each yank, paste and link-hover feedback group draws a background.
local feedback_probe = reporting([[
vim.iter({ "FlashYank", "FlashPaste", "LinkHover", "LinkHoverIcon" }):fold({}, function(drawn, group)
  drawn[group] = vim.api.nvim_get_hl(0, { name = group, link = false }).bg ~= nil
  return drawn
end)
]])

describe("startup", function()
  ---@type string
  local dir

  before_each(function()
    -- A temp cwd is also one mini.sessions never writes a session for.
    dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
  end)

  after_each(function()
    vim.fn.delete(dir, "rf")
  end)

  it("loads the whole config without an error or warning", function()
    local seen = boot(dir)

    assert.equal("", seen.stderr)
    assert.equal("", seen.messages)
    assert.same({}, seen.notices)
  end)

  it("keeps a colorscheme chosen on the command line", function()
    local seen = boot(dir, reporting("vim.g.colors_name"), { "-c", "colorscheme default" })

    assert.equal("default", seen.value)
  end)

  it("flashes yanks and pastes and tints a hovered link without a palette file", function()
    local seen = boot(dir, feedback_probe)

    assert.same({ FlashYank = true, FlashPaste = true, LinkHover = true, LinkHoverIcon = true }, seen.value)
  end)

  it("paints its own and plugin highlights from the palette's roles", function()
    require("support.palette").write(dir)
    local wrong = {}
    for _, pair in ipairs(boot(dir, palette_probe).pairs) do
      if pair[2] ~= pair[3] then
        table.insert(wrong, ("%s: %s, want %s"):format(unpack(pair)))
      end
    end
    assert.same({}, wrong)
  end)
end)

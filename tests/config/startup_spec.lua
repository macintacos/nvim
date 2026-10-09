local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")

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

---Boot this checkout's whole config headless, editing a Lua file so the plugins
---that load on FileType run too.
---@param dir string Scratch directory, also the booted Neovim's cwd.
---@param probe? string Collector to run instead of the default; `%q` is the report path.
---@return table report
local function boot(dir, probe)
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

  local result = vim
    .system({
      vim.v.progpath,
      "--headless",
      "-i",
      "NONE",
      "-n",
      "--cmd",
      rtp,
      "-u",
      root .. "/init.lua",
      "-c",
      "luafile " .. dir .. "/collect.lua",
      dir .. "/probe.lua",
    }, { cwd = dir, env = env, clear_env = true, text = true })
    :wait(30000)
  assert.equal(0, result.code, result.stderr)

  local seen = vim.json.decode(table.concat(vim.fn.readfile(report), "\n"))
  seen.stderr = result.stderr
  return seen
end

-- Pairs each highlight attribute the config paints with the palette role it should
-- carry, under both backgrounds, so a fox swap or retune cannot drift them apart.
local palette_probe = [[
vim.defer_fn(function()
  local function hex(n) return type(n) == "number" and ("#%%06x"):format(n) or tostring(n or "none") end
  local pairs_seen = {}
  for _, bg in ipairs({ "dark", "light" }) do
    vim.o.background = bg
    local p, spec = require("helpers.palette").active()
    local function check(group, attr, want)
      local got = vim.api.nvim_get_hl(0, { name = group, link = false })[attr]
      table.insert(pairs_seen, { bg .. " " .. group .. "." .. attr, hex(got), tostring(want):lower() })
    end
    check("PmenuSel", "bg", spec.sel0)
    check("PmenuSel", "fg", spec.fg1)
    check("MiniPickMatchCurrent", "bg", spec.sel0)
    check("MiniPickMatchRanges", "fg", p.blue.base)
    check("LinkHover", "bg", spec.sel0)
    check("LinkHoverIcon", "bg", spec.sel0)
    check("ModesInsertCursor", "bg", p.green.base)
    check("ModesReplaceCursor", "bg", p.red.base)
    local syn = spec.syntax
    check("@markup.heading", "fg", syn.func)
    check("@markup.heading", "bold", true)
    check("@markup.strong", "fg", spec.fg1)
    check("@markup.strong", "bold", true)
    check("@markup.italic", "italic", true)
    check("@markup.raw", "fg", p.cyan.base)
    check("@markup.link.label", "fg", syn.func)
    check("@markup.link.url", "fg", syn.const)
    check("@markup.list", "fg", syn.builtin1)
    check("RenderMarkdownBullet", "fg", syn.builtin1)
    check("@attribute", "fg", syn.preproc)
    check("@attribute.builtin", "fg", syn.preproc)
    for level = 1, 6 do
      check("RenderMarkdownH" .. level .. "Bg", "bg", require("helpers.palette").blend(spec.bg1, syn.func, 0.15))
    end
  end
  vim.fn.writefile({ vim.json.encode({ pairs = pairs_seen }) }, %q)
  vim.cmd("qa!")
end, 1500)
]]

describe("startup", function()
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

  it("paints selection, match, link, mode, markdown and attribute colours from the fox's palette roles", function()
    for _, pair in ipairs(boot(dir, palette_probe).pairs) do
      assert.equal(pair[3], pair[2], pair[1])
    end
  end)
end)

local server = require("plugins.svelte-css.server")
local svelte_css = require("plugins.svelte-css")

---@return vim.lsp.Client
local function client()
  return assert(vim.lsp.get_clients({ bufnr = 0, name = "svelte_css" })[1])
end

---Send `method` for the cursor at `row`/`col` in the current buffer and return the
---svelte_css client's result.
---@param method vim.lsp.protocol.Method.ClientToServer.Request
---@param row integer 0-based
---@param col integer 0-based
---@param extra? table Merged into the params
---@return any
local function request(method, row, col, extra)
  local params = vim.tbl_extend("force", {
    textDocument = { uri = vim.uri_from_bufnr(0) },
    position = { line = row, character = col },
  }, extra or {})
  local response = assert(client():request_sync(method, params, 2000, 0))
  assert.is_nil(response.err)
  assert.same({}, client().requests)
  return response.result
end

---@param row integer 0-based
---@param col integer 0-based
---@return string?
local function hover_text(row, col)
  local hover = request("textDocument/hover", row, col)
  return hover and hover.contents.value
end

---The svelte_css client's references for the cursor at `row`/`col`, each as
---`"<file>:<row>"`.
---@param row integer 0-based
---@param col integer 0-based
---@param include_declaration boolean
---@return string[]
local function references(row, col, include_declaration)
  local context = { includeDeclaration = include_declaration }
  return vim.tbl_map(function(location)
    return vim.fs.basename(vim.uri_to_fname(location.uri)) .. ":" .. location.range.start.line
  end, request("textDocument/references", row, col, { context = context }) or {})
end

---@return integer
local function client_count()
  return #vim.lsp.get_clients({ name = "svelte_css" })
end

describe("svelte-css server", function()
  local card = "styles/atoms.css:1\n```css\n.card { i: j }\n```"

  ---@type string
  local dir

  before_each(function()
    dir = vim.fn.tempname()
    vim.fn.mkdir(dir .. "/styles", "p")
    vim.fn.writefile({ "export default {}" }, dir .. "/svelte.config.js")
    vim.fn.writefile({
      '<div class="card own unstyled"></div>',
      "<style>",
      "  .own { a: b }",
      "</style>",
    }, dir .. "/A.svelte")
    vim.fn.writefile({ ".card { i: j }" }, dir .. "/styles/atoms.css")
    svelte_css.setup()
    vim.cmd.edit(dir .. "/A.svelte")
    assert.is_true(vim.wait(2000, function()
      return #vim.lsp.get_clients({ bufnr = 0, name = "svelte_css" }) > 0
    end))
  end)

  after_each(function()
    for _, each in ipairs(vim.lsp.get_clients({ name = "svelte_css" })) do
      each:stop(true)
    end
    vim.wait(1000, function()
      return client_count() == 0
    end)
    vim.cmd("%bwipeout!")
    vim.fn.delete(dir, "rf")
  end)

  it("hovers each rule under its root-relative path and line", function()
    local hover = request("textDocument/hover", 0, 12)
    assert.same({ kind = "markdown", value = card }, hover.contents)
  end)

  it("hovers nothing on a class no rule defines", function()
    assert.is_nil(request("textDocument/hover", 0, 22))
  end)

  it("reads an open buffer's unsaved edits", function()
    request("textDocument/hover", 0, 17)
    vim.api.nvim_buf_set_lines(0, 2, 3, false, { "  .own { a: c }" })
    assert.equal("A.svelte:3\n```css\n.own { a: c }\n```", hover_text(0, 17))
  end)

  it("re-reads a closed stylesheet that changed on disk", function()
    request("textDocument/hover", 0, 12)
    vim.fn.writefile({ ".card { changed: yes }" }, dir .. "/styles/atoms.css")
    assert.equal("styles/atoms.css:1\n```css\n.card { changed: yes }\n```", hover_text(0, 12))
  end)

  it("skips stylesheets under node_modules", function()
    vim.fn.mkdir(dir .. "/node_modules/lib", "p")
    vim.fn.writefile({ ".card { z: z }" }, dir .. "/node_modules/lib/x.css")
    assert.equal(card, hover_text(0, 12))
  end)

  it("skips ignored stylesheets outside a git repository", function()
    vim.fn.writefile({ "vendor/" }, dir .. "/.gitignore")
    vim.fn.mkdir(dir .. "/vendor", "p")
    vim.fn.writefile({ ".card { z: z }" }, dir .. "/vendor/x.css")
    assert.equal(card, hover_text(0, 12))
  end)

  it("locates the definition at the class in its selector", function()
    assert.same({
      {
        uri = vim.uri_from_bufnr(0),
        range = { start = { line = 2, character = 3 }, ["end"] = { line = 2, character = 6 } },
      },
    }, request("textDocument/definition", 0, 17))
  end)

  it("adds the rules to the references only when asked for declarations", function()
    assert.same({ "A.svelte:0" }, references(0, 12, false))
    assert.same({ "atoms.css:0", "A.svelte:0" }, references(0, 12, true))
  end)

  it("declares every rule that names the class, whether or not it styles the element", function()
    vim.fn.writefile({
      '<div class="wrapper"></div>',
      "<style>",
      "  .wrapper :global(p) { a: b }",
      "</style>",
    }, dir .. "/W.svelte")
    vim.cmd.edit(dir .. "/W.svelte")
    assert.same({ "W.svelte:2", "W.svelte:0" }, references(0, 13, true))
  end)

  it("leaves the client list once force-stopped", function()
    client():stop(true)
    assert.is_true(vim.wait(1000, function()
      return client_count() == 0
    end))
  end)
end)

describe("svelte-css outside a Svelte project", function()
  ---@type string
  local dir

  before_each(function()
    dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    vim.fn.writefile({ "{}" }, dir .. "/package.json")
    vim.fn.writefile({ ".card { i: j }" }, dir .. "/atoms.css")
    svelte_css.setup()
  end)

  after_each(function()
    vim.cmd("%bwipeout!")
    vim.fn.delete(dir, "rf")
  end)

  it("starts no client for a stylesheet in a project with no svelte.config", function()
    vim.cmd.edit(dir .. "/atoms.css")
    assert.same({}, vim.lsp.get_clients({ bufnr = 0, name = "svelte_css" }))
  end)
end)

describe("svelte-css server.start", function()
  it("answers a request whose handler fails with an InternalError", function()
    local noop = function() end
    local rpc =
      server.start({ notification = noop, server_request = noop, on_exit = noop, on_error = noop }, vim.uv.cwd())
    local err
    assert.has_no_error(function()
      rpc.request("textDocument/hover", {}, function(e)
        err = e
      end)
    end)
    assert.equal(vim.lsp.protocol.ErrorCodes.InternalError, err and err.code)
  end)
end)

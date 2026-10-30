---An in-process language server over a project's components and stylesheets. It
---reads each file from its loaded buffer when open, else from disk, and answers
---hover, definition, and references through the pure parse and resolve modules.
local parse = require("plugins.svelte-css.parse")
local resolve = require("plugins.svelte-css.resolve")

local M = {}

---@class svelte_css.Cached
---@field version string Buffer changedtick or file mtime the classes were parsed at
---@field classes svelte_css.Classes

---@class svelte_css.Server
---@field root string
---@field cache table<string, svelte_css.Cached> Keyed by absolute path

-- utf-8 because Tree-sitter columns are bytes.
---@type lsp.ServerCapabilities
local CAPABILITIES = {
  positionEncoding = "utf-8",
  hoverProvider = true,
  definitionProvider = true,
  referencesProvider = true,
}

---@return table<string, integer> bufnr by file name
local function loaded_buffers()
  local bufs = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      bufs[vim.api.nvim_buf_get_name(buf)] = buf
    end
  end
  return bufs
end

---Every component and stylesheet under `root` that `.gitignore` admits, outside
---`node_modules`.
---@param root string
---@return string[]
local function project_files(root)
  local rg = vim
    .system({
      "rg",
      "--files",
      -- A root can be a `package.json` with no repository around it yet.
      "--no-require-git",
      "--glob",
      "*.svelte",
      "--glob",
      "*.css",
      "--glob",
      "!**/node_modules/**",
    }, { cwd = root, text = true })
    :wait()
  return vim.tbl_map(function(file)
    return vim.fs.joinpath(root, file)
  end, vim.split(rg.stdout or "", "\n", { trimempty = true }))
end

---@param path string
---@return string?
local function read_file(path)
  local file = io.open(path, "rb")
  if not file then
    return nil
  end
  local text = file:read("*a")
  file:close()
  return text
end

---The classes in `path`, parsed afresh only when its buffer or file has changed.
---@param path string
---@param buf integer? The file's loaded buffer
---@param cache table<string, svelte_css.Cached>
---@return svelte_css.Classes?
local function file_classes(path, buf, cache)
  local version
  if buf then
    version = "buf" .. buf .. ":" .. vim.api.nvim_buf_get_changedtick(buf)
  else
    local stat = vim.uv.fs_stat(path)
    if not stat then
      return nil
    end
    version = stat.mtime.sec .. "." .. stat.mtime.nsec .. ":" .. stat.size
  end
  local cached = cache[path]
  if cached and cached.version == version then
    return cached.classes
  end
  local text = buf and table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") or read_file(path)
  if not text then
    return nil
  end
  local classes = parse.parse(text, vim.endswith(path, ".css") and "css" or "svelte")
  cache[path] = { version = version, classes = classes }
  return classes
end

---@param server svelte_css.Server
---@param origin string The requesting file, which counts even where rg would skip it
---@return svelte_css.Project
local function load_project(server, origin)
  local bufs = loaded_buffers()
  local paths = project_files(server.root)
  table.insert(paths, origin)
  local project = {}
  for _, path in ipairs(paths) do
    project[path] = project[path] or file_classes(path, bufs[path], server.cache)
  end
  return project
end

---@param server svelte_css.Server
---@param params lsp.TextDocumentPositionParams
---@return svelte_css.Project
---@return svelte_css.Target?
local function target(server, params)
  local path = vim.uri_to_fname(params.textDocument.uri)
  local project = load_project(server, path)
  return project, resolve.at(project, path, params.position.line, params.position.character)
end

---@param hits svelte_css.Hit[]
---@return lsp.Location[]?
local function locations(hits)
  if #hits == 0 then
    return nil
  end
  return vim.tbl_map(function(hit)
    local r = hit.site.range
    return {
      uri = vim.uri_from_fname(hit.path),
      range = { start = { line = r[1], character = r[2] }, ["end"] = { line = r[3], character = r[4] } },
    }
  end, hits)
end

---@param hits svelte_css.RuleHit[]
---@param root string
---@return string
local function hover_markdown(hits, root)
  return table.concat(
    vim.tbl_map(function(hit)
      local path = vim.fs.relpath(root, hit.path) or hit.path
      return ("%s:%d\n```css\n%s\n```"):format(path, hit.site.range[1] + 1, hit.site.rule)
    end, hits),
    "\n\n"
  )
end

---@type table<string, fun(server: svelte_css.Server, params: any): any>
local handlers = {
  initialize = function()
    return { capabilities = CAPABILITIES }
  end,
  shutdown = function()
    return nil
  end,
  ["textDocument/hover"] = function(server, params)
    local project, at = target(server, params)
    local hits = at and resolve.definitions(project, at) or {}
    if #hits == 0 then
      return nil
    end
    return { contents = { kind = "markdown", value = hover_markdown(hits, server.root) } }
  end,
  ["textDocument/definition"] = function(server, params)
    local project, at = target(server, params)
    return at and locations(resolve.definitions(project, at))
  end,
  ["textDocument/references"] = function(server, params)
    local project, at = target(server, params)
    if not at then
      return nil
    end
    local hits = params.context.includeDeclaration and resolve.rules(project, at) or {}
    return locations(vim.list_extend(hits, resolve.references(project, at)))
  end,
}

---The handler's result for `method`, or an error response when it has none or fails:
---raised, the error would escape into `vim.lsp.buf.*` and drop other servers' answers.
---@param server svelte_css.Server
---@param method string
---@param params any
---@return any result
---@return lsp.ResponseError? err
local function answer(server, method, params)
  local handler = handlers[method]
  if not handler then
    return nil, vim.lsp.rpc.rpc_response_error(vim.lsp.protocol.ErrorCodes.MethodNotFound)
  end
  local ok, result = pcall(handler, server, params)
  if not ok then
    return nil, vim.lsp.rpc.rpc_response_error(vim.lsp.protocol.ErrorCodes.InternalError, result)
  end
  return result
end

---Start a server for the project at `root`, in the form `vim.lsp.Config.cmd` returns.
---@param dispatchers vim.lsp.rpc.Dispatchers
---@param root string
---@return vim.lsp.rpc.PublicClient
function M.start(dispatchers, root)
  local server = { root = root, cache = {} }
  local closing, request_id = false, 0
  local function exit()
    if not closing then
      closing = true
      dispatchers.on_exit(0, 0)
    end
  end
  return {
    request = function(method, params, callback, notify_reply_callback)
      request_id = request_id + 1
      local result, err = answer(server, method, params)
      callback(err, result, request_id)
      -- Answered synchronously, so the client must not wait on it as pending.
      if notify_reply_callback then
        notify_reply_callback(request_id)
      end
      return true, request_id
    end,
    notify = function(method)
      if method == "exit" then
        exit()
      end
      return true
    end,
    is_closing = function()
      return closing
    end,
    terminate = exit,
  }
end

return M

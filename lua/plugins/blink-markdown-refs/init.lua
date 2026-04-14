---@module 'blink.cmp'
---@class blink.cmp.Source
local source = {}

local search = require("plugins.blink-markdown-refs.search")
local util = require("plugins.blink-markdown-refs.util")

---@class blink_md_refs.Config
---@field projects table<string, string> Resolved project name → path mappings
local config = { projects = {} }

---@type string Path to the MRU persistence file
local mru_path = vim.fn.stdpath("state") .. "/blink-markdown-refs-mru.json"

---@type string[]? In-memory cache of the MRU list (nil = not yet loaded)
local mru_cache = nil

---@type integer Maximum number of entries to keep in the MRU list
local MRU_MAX = 50

---Read the MRU list from disk (or return the cached copy).
---@return string[]
local function read_mru()
  if mru_cache then
    return mru_cache
  end
  local f = io.open(mru_path, "r")
  if not f then
    mru_cache = {}
    return mru_cache
  end
  local data = f:read("*a")
  f:close()
  local ok, decoded = pcall(vim.json.decode, data)
  mru_cache = (ok and decoded.mru) or {}
  return mru_cache
end

---Write the MRU list to disk and update the in-memory cache.
---Encodes JSON before opening the file to avoid truncating on encode failure.
---@param list string[]
local function write_mru(list)
  mru_cache = list
  local ok, json = pcall(vim.json.encode, { mru = list })
  if not ok then
    return
  end
  local f = io.open(mru_path, "w")
  if not f then
    return
  end
  f:write(json)
  f:close()
end

---Move a project name to the front of the MRU list, deduplicating.
---@param name string Project name to promote
local function add_to_mru(name)
  local list = read_mru()
  list = vim.list_slice(list, 1)
  for i, v in ipairs(list) do
    if v == name then
      table.remove(list, i)
      break
    end
  end
  table.insert(list, 1, name)
  while #list > MRU_MAX do
    table.remove(list)
  end
  write_mru(list)
end

-- Exposed for testing only
source._read_mru = read_mru
source._write_mru = write_mru
source._add_to_mru = add_to_mru

---Override the MRU file path (for testing). Pass nil to reset to default.
---@param path? string
function source._set_mru_path(path)
  mru_path = path or (vim.fn.stdpath("state") .. "/blink-markdown-refs-mru.json")
  mru_cache = nil
end

---Scan directories and collect their immediate subdirectories as name=path pairs.
---@param dirs string[] Parent directories to scan
---@return table<string, string>
local function expand_paths(dirs)
  local result = {}
  for _, dir in ipairs(dirs) do
    local expanded = vim.fn.expand(dir)
    if vim.fn.isdirectory(expanded) == 1 then
      for _, entry in ipairs(vim.fn.readdir(expanded)) do
        local full = expanded .. "/" .. entry
        if vim.fn.isdirectory(full) == 1 then
          result[entry] = full
        end
      end
    end
  end
  return result
end

---Configure the plugin with optional settings.
---`paths` entries are expanded first, then `projects` entries override on name collision.
---@param opts? { projects?: table<string, string>, paths?: string[] }
function source.setup(opts)
  opts = opts or {}
  local projects = opts.projects or {}
  if opts.paths then
    projects = vim.tbl_extend("force", expand_paths(opts.paths), projects)
  end
  config = vim.tbl_extend("force", config, { projects = projects })
end

---@type integer Namespace for match-highlight extmarks in the documentation window
local hl_ns = vim.api.nvim_create_namespace("blink-markdown-refs")
vim.api.nvim_set_hl(0, "BlinkCmpDocMatchLine", { default = true, bg = "#1a1c30" })
vim.api.nvim_set_hl(0, "BlinkCmpDocMatchChars", { default = true, bold = true, fg = "#ff9e64", bg = "#252840" })

---@type { items: lsp.CompletionItem[], is_incomplete_forward: boolean, is_incomplete_backward: boolean }
local EMPTY_RESPONSE = { items = {}, is_incomplete_forward = false, is_incomplete_backward = false }

---@return blink.cmp.Source
function source.new()
  return setmetatable({}, { __index = source })
end

---Only activate for markdown buffers.
---@return boolean
function source:enabled()
  return vim.bo.filetype == "markdown"
end

---@return string[]
function source:get_trigger_characters()
  return { "@" }
end

---Dispatch completion based on the parsed line mode.
---@param ctx { line: string, cursor: integer[], bufnr: integer }
---@param callback fun(response: { items: lsp.CompletionItem[], is_incomplete_forward: boolean, is_incomplete_backward: boolean })
---@return fun()? cancel
function source:get_completions(ctx, callback)
  local line_before = ctx.line:sub(1, ctx.cursor[2])
  local parsed = util.parse_line(line_before)

  if parsed.mode == "none" then
    callback(EMPTY_RESPONSE)
    return
  end

  if parsed.mode == "project_select" then
    local prefix = parsed.query:lower()
    local mru = read_mru()
    local mru_rank = {}
    for i, name in ipairs(mru) do
      mru_rank[name] = i
    end
    local items = {}
    for name, path in pairs(config.projects) do
      if prefix == "" or name:lower():sub(1, #prefix) == prefix then
        local rank = mru_rank[name]
        items[#items + 1] = {
          label = name,
          kind = 9, -- Module
          insertText = "!" .. name .. "@",
          filterText = "!" .. name,
          sortText = (rank and string.format("0_%04d_%s", rank, name) or "1_" .. name),
          labelDetails = { description = path },
          data = { type = "project", project_name = name, project_path = path },
        }
      end
    end
    callback({ items = items, is_incomplete_forward = true, is_incomplete_backward = false })
    return
  end

  local buf_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.bufnr), ":h")

  if parsed.mode == "project_search" then
    local project_path = config.projects[parsed.project]
    if not project_path then
      callback(EMPTY_RESPONSE)
      return
    end
    local project_name = parsed.project
    return search.search(parsed.query, project_path, buf_dir, function(response)
      for _, item in ipairs(response.items) do
        item.data.project = project_name
      end
      callback(response)
    end)
  end

  -- Normal mode: search in current project root
  local root = util.get_root(ctx.bufnr)
  return search.search(parsed.query, root, buf_dir, callback)
end

---Generate a documentation preview with syntax-highlighted file context.
---For content and heading matches, highlights the matched line and query text
---using extmarks in a custom draw function.
---@param item lsp.CompletionItem
---@param callback fun(item: lsp.CompletionItem)
function source:resolve(item, callback)
  item = vim.deepcopy(item)

  if not item.data or not item.data.path then
    callback(item)
    return
  end

  local path = item.data.path
  local target_line = item.data.line or 1
  local start_line = math.max(1, target_line - 5)
  local end_line = target_line + 15

  local lines = vim.fn.readfile(path, "", end_line)
  if #lines >= start_line then
    local slice = vim.list_slice(lines, start_line, end_line)
    local ext = vim.fn.fnamemodify(path, ":e")
    local is_match_type = item.data.type == "content" or item.data.type == "heading"
    local match_idx = is_match_type and (target_line - start_line + 1) or nil
    local query = item.data.query or ""

    item.documentation = {
      kind = "markdown",
      value = table.concat(slice, "\n"),
      draw = function(opts)
        local bufnr = opts.window:get_buf()

        -- Set buffer content directly — no code fences means no top padding
        vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, slice)
        vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
        vim.api.nvim_set_option_value("modified", false, { buf = bufnr })

        -- Apply treesitter syntax highlighting for the file's language
        local lang = vim.treesitter.language.get_lang(ext) or ext
        local ok, docs = pcall(require, "blink.cmp.lib.window.docs")
        if ok then
          pcall(docs.highlight_with_treesitter, bufnr, lang, 0, #slice)
        end

        -- For content/heading matches, highlight the matched line and query text
        if match_idx and match_idx >= 1 and match_idx <= #slice then
          local buf_line = match_idx - 1
          vim.api.nvim_buf_clear_namespace(bufnr, hl_ns, 0, -1)
          vim.api.nvim_buf_set_extmark(bufnr, hl_ns, buf_line, 0, {
            line_hl_group = "BlinkCmpDocMatchLine",
            priority = 200,
          })

          local col_start = util.smart_find(query, slice[match_idx])
          if col_start then
            vim.api.nvim_buf_set_extmark(bufnr, hl_ns, buf_line, col_start - 1, {
              end_col = col_start - 1 + #query,
              hl_group = "BlinkCmpDocMatchChars",
              priority = 201,
            })
          end
        end
      end,
    }
  end
  callback(item)
end

---Replace text in the buffer from start_col to the cursor position.
---@param ctx { cursor: integer[], bufnr: integer }
---@param start_col integer 0-based byte column to start replacing from
---@param text string Replacement text
---@param callback fun()
local function replace_range(ctx, start_col, text, callback)
  local row = ctx.cursor[1] - 1
  vim.api.nvim_buf_set_text(ctx.bufnr, row, start_col, row, ctx.cursor[2], { text })
  callback()
end

---Handle completion acceptance. Tracks MRU for project items, strips the
---`!project@` routing prefix for project-search results, and supports
---Shift+Enter to strip the leading `@`.
---@param ctx { line: string, cursor: integer[], bufnr: integer }
---@param item lsp.CompletionItem
---@param callback fun()
---@param default_implementation fun()
function source:execute(ctx, item, callback, default_implementation)
  if item.data and item.data.type == "project" and item.data.project_name then
    add_to_mru(item.data.project_name)
  end

  local line_before = ctx.line:sub(1, ctx.cursor[2])

  -- Strip the !project@ routing prefix for items from project search
  if item.data and item.data.project then
    local outer_at = line_before:match(".*()@!" .. vim.pesc(item.data.project) .. "@")
    if outer_at then
      replace_range(ctx, outer_at - 1, "@" .. (item.data.raw_path or item.insertText or ""), callback)
      return
    end
  end

  -- Strip the leading @ when Shift+Enter was used
  local strip = vim.b[ctx.bufnr].blink_md_refs_strip_at
  if strip then
    vim.b[ctx.bufnr].blink_md_refs_strip_at = nil
    local at_pos = line_before:match(".*()@")
    if at_pos and item.data and item.data.raw_path then
      replace_range(ctx, at_pos - 1, item.data.raw_path, callback)
      return
    end
  end

  default_implementation()
  callback()
end

return source

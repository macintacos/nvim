local M = {}

-- `app.command("pkg.module:attr", ...)`: a command cyclopts imports on first use.
local LAZY_COMMAND = [[
(call
  function: (attribute attribute: (identifier) @_method (#eq? @_method "command"))
  arguments: (argument_list . (string) @import_path))
]]

---Whether `lines` import cyclopts.
---@param lines string[]
---@return boolean
local function imports_cyclopts(lines)
  return vim.tbl_contains(lines, function(line)
    return line:match("^%s*from%s+cyclopts[%s.]") ~= nil or line:match("^%s*import%s+cyclopts%f[^%w_]") ~= nil
  end, { predicate = true })
end

---The module and attribute of the lazy command import path at `pos` in Python
---`buf`, when `buf` imports cyclopts.
---@param buf integer
---@param pos [integer, integer] 0-based row and byte column
---@return string? module
---@return string? attribute
local function import_path(buf, pos)
  if vim.bo[buf].filetype ~= "python" or not imports_cyclopts(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) then
    return nil
  end
  local parser = vim.treesitter.get_parser(buf, "python")
  if not parser then
    return nil
  end
  local tree = assert(parser:parse({ pos[1], pos[1] + 1 }))[1]
  local query = vim.treesitter.query.parse("python", LAZY_COMMAND)
  for id, node in query:iter_captures(tree:root(), buf, pos[1], pos[1] + 1) do
    if query.captures[id] == "import_path" and vim.treesitter.is_in_node_range(node, pos[1], pos[2]) then
      return vim.treesitter.get_node_text(node, buf):match("^[\"']([%w_.]+):([%w_]+)[\"']$")
    end
  end
end

---The file `module` loads from, as a module or a package, found in the
---directory holding `from` or one above it.
---@param module string Dotted, e.g. `pkg.sub`
---@param from string
---@return string?
local function module_file(module, from)
  local relative = module:gsub("%.", "/")
  for dir in vim.fs.parents(from) do
    for _, path in ipairs({ ("%s/%s.py"):format(dir, relative), ("%s/%s/__init__.py"):format(dir, relative) }) do
      if vim.uv.fs_stat(path) then
        return path
      end
    end
  end
end

---The 0-based row of `lines` that defines `name` at the top level.
---@param lines string[]
---@param name string
---@return integer?
local function definition_row(lines, name)
  for i, line in ipairs(lines) do
    local defined = line:match("^def ([%w_]+)")
      or line:match("^async def ([%w_]+)")
      or line:match("^class ([%w_]+)")
      or line:match("^([%w_]+)%s*[:=]")
    if defined == name then
      return i - 1
    end
  end
end

---Where the cyclopts lazy command import path under the cursor points: the
---top-level definition of its attribute, or the top of its module when the
---module only re-exports it.
---@return lsp.Location?
function M.under_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local module, attribute = import_path(0, { cursor[1] - 1, cursor[2] })
  if not module or not attribute then
    return nil
  end
  local path = module_file(module, vim.api.nvim_buf_get_name(0))
  if not path then
    return nil
  end
  local position = { line = definition_row(vim.fn.readfile(path), attribute) or 0, character = 0 }
  return { uri = vim.uri_from_fname(path), range = { start = position, ["end"] = position } }
end

return M

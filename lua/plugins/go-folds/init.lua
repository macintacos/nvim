-- Draw Go's short constructs collapsed onto one line, as real folds whose
-- 'foldtext' is the code itself rather than the fold bar.

local folds = require("config.folds")
local inline = require("plugins.go-folds.inline")

local M = {}

local FOLDTEXT = "v:lua.require'plugins.go-folds'.foldtext()"
local LSP_FOLDEXPR = "v:lua.vim.lsp.foldexpr()"

---Diagnostic severities a collapsed line counts, most severe first.
---`letter` stands in for a severity's sign where the config sets none.
---@type { level: vim.diagnostic.Severity, group: string, letter: string }[]
local SEVERITIES = {
  { level = vim.diagnostic.severity.ERROR, group = "DiagnosticError", letter = "E" },
  { level = vim.diagnostic.severity.WARN, group = "DiagnosticWarn", letter = "W" },
}

---The mark closing a collapsed line: the chevron the gutter gives a closed fold.
---@return string
local function cue()
  return " " .. (vim.opt.fillchars:get().foldclose or "+")
end

---Root of `buf`'s Go tree, or nil without a Go parser.
---@param buf integer
---@return TSNode?
local function root(buf)
  local parser = vim.treesitter.get_parser(buf, "go")
  local trees = parser and parser:parse()
  local tree = trees and trees[1]
  return tree and tree:root()
end

---@param buf integer
---@param row integer 0-indexed
---@return string
local function line(buf, row)
  return vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
end

---@class go-folds.Cached
---@field tick integer
---@field tabstop integer
---@field constructs go-folds.inline.Construct[]

---Each buffer's constructs, as of one changedtick.
---@type table<integer, go-folds.Cached?>
local cache = {}

---The constructs of `buf` that draw on one line.
---@param buf integer
---@return go-folds.inline.Construct[]
local function constructs(buf)
  local tick, tabstop = vim.api.nvim_buf_get_changedtick(buf), vim.bo[buf].tabstop
  local cached = cache[buf]
  if cached and cached.tick == tick and cached.tabstop == tabstop then
    return cached.constructs
  end
  local tree = root(buf)
  local found = tree
      and inline.constructs(tree, function(row)
        return line(buf, row)
      end, { width = folds.MAX_WIDTH - vim.api.nvim_strwidth(cue()), tabstop = tabstop })
    or {}
  cache[buf] = { tick = tick, tabstop = tabstop, constructs = found }
  return found
end

---The construct of `buf` whose header is on `row`.
---@param buf integer
---@param row integer 0-indexed
---@return go-folds.inline.Construct?
function M._construct(buf, row)
  for _, construct in ipairs(constructs(buf)) do
    if construct.first == row then
      return construct
    end
  end
end

---The highlight group tree-sitter gives each byte of `row`, keyed by 0-indexed byte.
---@param buf integer
---@param tree TSNode
---@param row integer 0-indexed
---@return table<integer, string?>
local function colors(buf, tree, row)
  local groups = {}
  local query = vim.treesitter.query.get("go", "highlights")
  if not query then
    return groups
  end
  local width = #line(buf, row)
  -- ponytail: a later capture wins, with no regard for `priority` metadata or
  -- injected languages; read both the way the highlighter does if Go's query
  -- comes to depend on them.
  for id, node in query:iter_captures(tree, buf, row, row + 1) do
    local name = assert(query.captures[id], "a capture id names a capture")
    if not name:find("^_") and name ~= "spell" and name ~= "nospell" then
      local start_row, from, end_row, to = node:range()
      for col = start_row < row and 0 or from, (end_row > row and width or to) - 1 do
        groups[col] = ("@%s.go"):format(name)
      end
    end
  end
  return groups
end

---The highlight groups under every chunk of a collapsed line. Chunks stack on
---Folded, so the editor's own background has to be laid back over its band.
---@param construct go-folds.inline.Construct
---@return string[]
local function ground(construct)
  local cursor = vim.fn.line(".") - 1
  if vim.wo.cursorline and cursor >= construct.first and cursor <= construct.last then
    return { "Normal", "CursorLine" }
  end
  return { "Normal" }
end

---@alias go-folds.Chunk [string, string[]]

---Append `piece` to `chunks`, split wherever its color changes.
---@param chunks go-folds.Chunk[]
---@param text string The piece's whole line
---@param piece go-folds.inline.Piece
---@param groups table<integer, string?>
---@param base string[]
local function append_piece(chunks, text, piece, groups, base)
  local from = piece.from
  for col = piece.from + 1, piece.to do
    if col == piece.to or groups[col] ~= groups[from] then
      chunks[#chunks + 1] = { text:sub(from + 1, col), vim.list_extend(vim.list_slice(base), { groups[from] }) }
      from = col
    end
  end
end

---Append a count of each severity of diagnostic on `construct`'s lines.
---@param chunks go-folds.Chunk[]
---@param buf integer
---@param construct go-folds.inline.Construct
---@param base string[]
local function append_diagnostics(chunks, buf, construct, base)
  for _, severity in ipairs(SEVERITIES) do
    local count = #vim.tbl_filter(function(diagnostic)
      return diagnostic.lnum >= construct.first and diagnostic.lnum <= construct.last
    end, vim.diagnostic.get(buf, { severity = severity.level }))
    if count > 0 then
      local icon = vim.tbl_get(vim.diagnostic.config() or {}, "signs", "text", severity.level) or severity.letter
      chunks[#chunks + 1] =
        { (" %s %d"):format(icon, count), vim.list_extend(vim.list_slice(base), { severity.group }) }
    end
  end
end

---`construct` as 'foldtext' chunks: its one line in the code's own colors, the
---cue, then any diagnostics its hidden lines carry.
---@param buf integer
---@param construct go-folds.inline.Construct
---@return go-folds.Chunk[]
function M._chunks(buf, construct)
  local base = ground(construct)
  local tree = assert(root(buf), "a buffer with constructs has a Go tree")
  local chunks = { { construct.indent, base } }
  for index, piece in ipairs(construct.pieces) do
    if index > 1 then
      chunks[#chunks + 1] = { " ", base }
    end
    append_piece(chunks, line(buf, piece.row), piece, colors(buf, tree, piece.row), base)
  end
  chunks[#chunks + 1] = { cue(), vim.list_extend(vim.list_slice(base), { "GoFoldsCue" }) }
  append_diagnostics(chunks, buf, construct, base)
  -- Past the last chunk Neovim fills the row with Folded's band.
  chunks[#chunks + 1] = { (" "):rep(vim.o.columns), base }
  return chunks
end

---Whether `construct`'s one line fits the current window. A closed fold's line
---never wraps, so one that overran would lose its end without a sign.
---@param construct go-folds.inline.Construct
---@return boolean
local function fits(construct)
  return vim.api.nvim_strwidth(construct.text .. cue()) <= folds.text_width()
end

---'foldtext' expression for a Go window: a closed construct as one line of Go,
---any other closed fold as the bar.
---@return string|go-folds.Chunk[]
function M.foldtext()
  local buf = vim.api.nvim_get_current_buf()
  local construct = M._construct(buf, vim.v.foldstart - 1)
  if not construct or construct.last ~= vim.v.foldend - 1 or not fits(construct) then
    return folds.foldtext()
  end
  return M._chunks(buf, construct)
end

---Close every construct in the windows folding `buf` by its language server,
---the first time only: a construct opened since stays open.
---@param buf integer
local function collapse(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.b[buf].go_folds_collapsed then
    return
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.wo[win].foldexpr == LSP_FOLDEXPR then
      vim.b[buf].go_folds_collapsed = true
      vim.api.nvim_win_call(win, function()
        for _, construct in ipairs(vim.tbl_filter(fits, constructs(buf))) do
          local first, last = construct.first + 1, construct.last + 1
          vim.cmd(first .. "foldclose")
          -- With no fold of its own the construct's line closed whatever fold holds it.
          if vim.fn.foldclosed(first) ~= first or vim.fn.foldclosedend(first) ~= last then
            vim.cmd(first .. "foldopen")
          end
        end
      end)
    end
  end
end

---`ranges` of `buf` with one range per construct, reaching its closing brace.
---@param ranges lsp.FoldingRange[]
---@param buf integer
---@return lsp.FoldingRange[]
local function widen(ranges, buf)
  if vim.bo[buf].filetype ~= "go" then
    return ranges
  end
  -- Neovim folds by the ranges as soon as this returns them.
  vim.schedule(function()
    collapse(buf)
  end)
  return inline.widen(ranges, constructs(buf))
end

---Fold `buf`'s constructs by `client`'s folding ranges, and close them once the
---first ranges arrive, when `client` serves folding ranges for a Go buffer.
---@param client vim.lsp.Client
---@param buf integer
function M.attach(client, buf)
  if vim.bo[buf].filetype == "go" and client:supports_method("textDocument/foldingRange") then
    folds.rewrite_ranges(client, widen)
  end
end

---Register the autocmds that give Go windows their 'foldtext' and fold their
---buffers' constructs.
function M.setup()
  local group = vim.api.nvim_create_augroup("GoFolds", { clear = true })

  -- Points a Go window's 'foldtext' at this plugin, so a closed construct draws
  -- as code and every other fold keeps the bar. 'foldtext' is local to the
  -- window, hence both events: FileType fires when a buffer becomes Go,
  -- BufWinEnter when a Go buffer is shown in another window.
  vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    group = group,
    desc = "Draw a Go window's closed constructs as one line of code",
    callback = function(ev)
      if vim.bo[ev.buf].filetype ~= "go" then
        return
      end
      for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
        vim.wo[win][0].foldtext = FOLDTEXT
      end
    end,
  })

  -- Stretches gopls's folding ranges over each construct's closing brace and
  -- closes the constructs once the ranges land. Fires when a language server
  -- attaches to a buffer; only one serving folding ranges for Go is hooked.
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    desc = "Fold a Go buffer's one-line constructs",
    callback = function(ev)
      M.attach(assert(vim.lsp.get_client_by_id(ev.data.client_id), "LspAttach names a live client"), ev.buf)
    end,
  })
end

return M

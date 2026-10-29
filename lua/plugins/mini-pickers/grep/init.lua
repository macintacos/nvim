---Live grep rendered as a breadcrumb list.
---
---`MiniPick.default_show` prints an rg hit as `path│lnum│col│text`, so the path
---repeats on every row of a file and the matched text starts three columns in.
---This changes only the drawing — the items stay the raw rg strings, so
---choosing and previewing still work — hoisting the path into a virtual header
---above each run of hits and right-aligning the line number against the text it
---belongs to.
---
---The picker runs rg itself, as mini.pick's `grep_live` does, so it can rank
---rg's whole output (`rank`) and keep filters, sort, and the last query
---across opens (`state`). Ranking keeps a file's hits together, so one
---header per run of equal paths covers every hit in that file.

local rank = require("plugins.mini-pickers.grep.rank")
local selection = require("plugins.mini-pickers.grep.selection")
local grep_state = require("plugins.mini-pickers.grep.state")
local side_preview = require("plugins.mini-pickers.preview")
local render = require("plugins.mini-pickers.render")
local symbols = require("plugins.mini-pickers.symbols")

local M = {}

---Split one rg item into its path, line number, and matched text.
---
---The picker runs rg with `--field-match-separator '\x00'`, so an item is
---`path\0lnum\0col\0text`. Leading indentation is dropped from the text — the
---rows are already indented under their header, and a deeply nested match
---would otherwise start off the right edge of the window.
---@param item any
---@return string? path nil when the item is not an rg hit.
---@return string? lnum
---@return string text Always set; the item verbatim when it does not parse.
---@return integer? col 1-based byte column where the hit starts.
local function parse(item)
  local str = tostring(item)
  local path, lnum, col, text = str:match("^(.-)%z(%d+)%z(%d+)%z(.*)$")
  if not (path and lnum and col and text) then
    return nil, nil, str
  end
  return path, lnum, (text:gsub("^%s+", "")), tonumber(col, 10)
end

-- Characters Vim's very-magic regex treats as operators but rg's regex reads
-- literally. Everything else the two dialects spell the same way.
local VIM_ONLY_SPECIALS = "[<>=@%%&~]"

---Where the query's match ends, given where rg says it starts.
---
---rg reports only a hit's start column, which leaves the preview marking one
---character. The rg pattern is re-run as a Vim regex to measure the rest.
---Syntax only rg understands (inline flags, lookarounds) fails to compile or to
---match at `col`, and gets nil rather than a guess.
---@param line string The line the hit is on.
---@param col integer 1-based byte column where the hit starts.
---@param pattern string The rg pattern.
---@param ignore_case boolean Whether rg searched case-insensitively.
---@return integer? end_col 0-based exclusive byte column.
local function match_end(line, col, pattern, ignore_case)
  local vim_pattern = (ignore_case and "\\c" or "\\C") .. "\\v" .. pattern:gsub(VIM_ONLY_SPECIALS, "\\%0")
  local ok, regex = pcall(vim.regex, vim_pattern)
  if not ok then
    return nil
  end
  local from, to = regex:match_str(line:sub(col))
  if from ~= 0 or not to then
    return nil
  end
  return col - 1 + to
end

---`source.preview` that marks the whole match, not just its first character.
---@param buf_id integer
---@param item any
local function preview(buf_id, item)
  MiniPick.default_preview(buf_id, item)
  local _, lnum, _, col = parse(item)
  local pattern = table.concat(MiniPick.get_picker_query() or {})
  if not (lnum and col) or pattern == "" then
    return
  end
  local row = assert(tonumber(lnum, 10)) - 1
  local line = vim.api.nvim_buf_get_lines(buf_id, row, row + 1, false)[1]
  -- Mirrors the case flag the picker hands rg.
  local ignore_case = vim.o.ignorecase and not (vim.o.smartcase and pattern:find("%u"))
  local end_col = line and match_end(line, col, pattern, ignore_case)
  if end_col then
    vim.api.nvim_buf_set_extmark(buf_id, render.ns, row, col - 1, {
      end_col = end_col,
      hl_group = "MiniPickPreviewRegion",
      priority = 203,
    })
  end
end

---`source.show` for the live grep.
---@param buf_id integer
---@param items any[]
---@param query string[]
local function show(buf_id, items, query)
  local paths, lnums, lines = {}, {}, {}
  for i, item in ipairs(items) do
    paths[i], lnums[i], lines[i] = parse(item)
  end

  MiniPick.default_show(buf_id, lines, query)

  local state = MiniPick.get_picker_state()
  local width = state and vim.api.nvim_win_get_width(state.windows.main) or 80

  vim.api.nvim_buf_clear_namespace(buf_id, render.ns, 0, -1)
  local prev_path, first_has_header = nil, false
  for i = 1, #lines do
    if paths[i] and paths[i] ~= prev_path then
      local ok, icon, hl = pcall(MiniIcons.get, "file", paths[i])
      icon = ok and icon or " "
      vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, 0, {
        virt_lines = {
          {
            { icon .. " ", ok and hl or "Comment" },
            { symbols.fit(paths[i], width - 2), render.crumb_hl() },
          },
        },
        virt_lines_above = true,
        priority = 199,
      })
      first_has_header = first_has_header or i == 1
    end

    if lnums[i] then
      vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, 0, {
        virt_text = { { lnums[i], "LineNr" } },
        virt_text_pos = "right_align",
        priority = 199,
      })
    end

    -- Indent the hits so the header's first glyph sits left of what it covers.
    vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, 0, {
      virt_text = { { "  " } },
      virt_text_pos = "inline",
      priority = 199,
    })

    prev_path = paths[i]
  end

  if state then
    render.reserve_trail_row(state.windows.main, first_has_header)
  end
end

---Grep scope for one filesystem entry.
---
---A directory greps itself. A file greps its parent directory narrowed back down
---to the file: the leading `/` anchors the glob to the search root, so a
---same-named file in a subdirectory does not come along.
---@param path string
---@param fs_type "file"|"directory"
---@return string cwd Directory the picker searches.
---@return string[] globs Restriction passed to `grep_live`.
local function scope(path, fs_type)
  if fs_type == "directory" then
    return path, {}
  end
  return vim.fs.dirname(path), { "/" .. vim.fs.basename(path) }
end

-- Exposed for tests: the item format and the scope split are the only parts
-- worth asserting headlessly.
M._parse = parse
M._show = show
M._match_end = match_end
M._scope = scope

-- Uppercase so `:mksession` saves it with the project's session.
local STATE_VAR = "GrepLiveState"

-- Herdr takes ⌥a ⌥d ⌥s ⌥w for pane resizing, so they never reach the picker.
local KEYBAR = {
  { "⌥x", "exclude" },
  { "⌥o", "only" },
  { "⌥f", "filters" },
  { "⌥t", "sort" },
  { "⌥u", "ignored" },
  { "⌥r", "reset" },
}

---The preview footer listing the grep's keys.
---@return [string, string][]
local function keybar()
  local chunks = { { " ", "MiniPickBorderText" } }
  for i, entry in ipairs(KEYBAR) do
    vim.list_extend(chunks, {
      { entry[1] .. " ", "MiniPickBorderText" },
      { entry[2] .. (i < #KEYBAR and "  " or " "), "MiniPickKeybarLabel" },
    })
  end
  return chunks
end

---@return "smart-case"|"ignore-case"|"case-sensitive"
local function rg_case()
  return vim.o.ignorecase and (vim.o.smartcase and "smart-case" or "ignore-case") or "case-sensitive"
end

---Recency rank of each recently used file, relative to `cwd`: buffers by last
---use, then `oldfiles`, which misses files opened this session.
---@param cwd string
---@param bufs { name: string, lastused: integer }[] Listed buffers, as `getbufinfo` gives them.
---@param oldfiles string[] `v:oldfiles`.
---@return table<string, integer>
local function recency(cwd, bufs, oldfiles)
  bufs = vim.list_slice(bufs)
  table.sort(bufs, function(a, b)
    return a.lastused > b.lastused
  end)
  local paths = vim.tbl_map(function(b)
    return b.name
  end, bufs)
  vim.list_extend(paths, oldfiles)
  local ranks, n = {}, 0
  for _, path in ipairs(paths) do
    local rel = path ~= "" and vim.fs.relpath(cwd, path)
    if rel and not ranks[rel] then
      n = n + 1
      ranks[rel] = n
    end
  end
  return ranks
end

M._recency = recency

---Resolve a typed path: `~` expanded, an absolute path kept, a relative one
---read from `cwd`.
---@param input string
---@param cwd string Absolute.
---@return string
local function resolve(input, cwd)
  local path = vim.fs.normalize(vim.trim(input))
  return vim.startswith(path, "/") and path or vim.fs.joinpath(cwd, path)
end

---Ask for a path in the picker's UI line, as mini.pick's own glob prompt does.
---@param prompt string
---@param text string
---@return string?
local function ask(prompt, text)
  local from_bottom = assert(MiniPick.get_picker_opts()).options.content_from_bottom
  return MiniInput.get({
    prompt = "(mini.pick) " .. prompt,
    init_keys = { text },
    completion = "file",
    handlers = { view = MiniInput.gen_view.uiline({ style = from_bottom and "statusline" or "winbar" }) },
  })
end

local NAME = "Grep live"

-- Namespace of the selection's key listener.
local SELECT_NS = vim.api.nvim_create_namespace("mini_pickers_grep_selected")
local SELECTED_HL = "MiniPickPrompt:Visual"

---Open the live grep picker.
---@param local_opts? { globs?: string[] } `globs` scope the search, rg-style.
---@param opts table? Options for `MiniPick.start`, merged over the custom show.
function M.pick(local_opts, opts)
  -- The filter list reopens the picker with these, before they are merged below.
  local caller_opts = opts
  opts = opts or {}
  local scope_globs = (local_opts or {}).globs or {}
  local state = grep_state.decode(vim.g[STATE_VAR])
  local root = vim.fn.getcwd()
  local cwd = vim.fs.abspath(opts.source and opts.source.cwd or root)
  local base = opts.source and opts.source.name or NAME
  local origin_name = vim.api.nvim_buf_get_name(0)
  local origin = origin_name ~= "" and vim.fs.relpath(cwd, origin_name) or nil

  local function save()
    vim.g[STATE_VAR] = grep_state.encode(state)
  end

  local function postprocess(lines)
    while lines[#lines] == "" do
      lines[#lines] = nil
    end
    local recent = state.sort == "recent" and recency(cwd, vim.fn.getbufinfo({ buflisted = 1 }), vim.v.oldfiles) or nil
    return rank.order(lines, { sort = state.sort, origin = origin, recent = recent })
  end

  local set_items_opts = { do_match = false, querytick = MiniPick.get_querytick() }
  local sys = { kill = function() end }
  local function match(_, _, query)
    sys:kill()
    if MiniPick.get_querytick() == set_items_opts.querytick then
      return
    end
    state.query = table.concat(query)
    save()
    if state.query == "" then
      sys = { kill = function() end }
      return MiniPick.set_picker_items({}, set_items_opts)
    end
    set_items_opts.querytick = MiniPick.get_querytick()
    local command = grep_state.command(state, {
      pattern = state.query,
      case = rg_case(),
      globs = vim.list_extend(vim.deepcopy(scope_globs), grep_state.globs(state.filters, root, cwd)),
      paths = grep_state.paths(state.filters, root, cwd),
    })
    sys = MiniPick.set_picker_items_from_cli(command, {
      postprocess = postprocess,
      set_items_opts = set_items_opts,
      spawn_opts = { cwd = cwd },
    }) or sys
  end

  -- Save, then re-run the current query under the changed state.
  local function changed()
    save()
    MiniPick.set_picker_opts({ source = { name = grep_state.label(state, base, NAME) } })
    MiniPick.set_picker_query(MiniPick.get_picker_query() or {})
  end

  local function add_filter(kind)
    local item = (MiniPick.get_picker_matches() or {}).current
    local path = item and parse(item)
    local dir = path and vim.fs.dirname(path) or "."
    local input = ask(kind == "exclude" and "Exclude path" or "Only path", dir == "." and "" or dir .. "/")
    if not input or vim.trim(input) == "" then
      return
    end
    local rel = vim.fs.relpath(root, resolve(input, cwd))
    if rel then
      state = grep_state.add_filter(state, kind, rel, vim.fn.isdirectory(vim.fs.joinpath(root, rel)) == 1)
      changed()
    end
  end

  local function edit_filters()
    local filters = state.filters
    if #filters == 0 then
      return
    end
    -- mini.pick runs one picker at a time, so the list replaces the grep, which
    -- reopens on the saved state afterwards.
    vim.schedule(function()
      vim.ui.select(filters, {
        prompt = "Remove filter",
        format_item = grep_state.filter_text,
      }, function(_, i)
        if i then
          table.remove(state.filters, i)
          save()
        end
        M.pick(local_opts, caller_opts)
      end)
    end)
    return true
  end

  local mappings = {
    grep_exclude = {
      char = "<M-x>",
      func = function()
        add_filter("exclude")
      end,
    },
    grep_include = {
      char = "<M-o>",
      func = function()
        add_filter("include")
      end,
    },
    grep_filters = { char = "<M-f>", func = edit_filters },
    grep_sort = {
      char = "<M-t>",
      func = function()
        state.sort = rank.next_sort(state.sort)
        changed()
      end,
    },
    grep_ignored = {
      char = "<M-u>",
      func = function()
        state.ignored = not state.ignored
        changed()
      end,
    },
    grep_reset = {
      char = "<M-r>",
      func = function()
        state = grep_state.reset(state)
        changed()
      end,
    },
    switch_method = {
      char = "<C-e>",
      func = function()
        state.method = state.method == "regex" and "plain" or "regex"
        changed()
      end,
    },
  }

  -- Select the saved query once the picker is up, as mini.pick has no initial
  -- query. Captured now: the picker's first match runs on an empty query.
  -- Fires on the next MiniPickStart; that picker may not be this grep, since
  -- `MiniPick.start` returns early from the command-line window, so it checks.
  local initial = vim.fn.split(state.query, "\\zs")
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("MiniPickers.GrepStart", { clear = true }),
    pattern = "MiniPickStart",
    once = true,
    callback = function()
      local started = MiniPick.get_picker_opts()
      if started and started.source.match == match then
        M._select(initial)
      end
    end,
  })

  opts = vim.tbl_deep_extend(
    "force",
    { source = { show = show, preview = preview }, window = side_preview.window({ footer = keybar() }) },
    opts,
    { source = { items = {}, match = match, name = grep_state.label(state, base, NAME) }, mappings = mappings }
  )
  return MiniPick.start(opts)
end

---Set the active picker's query and draw it selected: the next key replaces,
---clears, or keeps it per `selection`. A query something else seeded at
---start, such as `<leader>sP`'s word, wins.
---
---mini.pick's prompt has no selection, so it is emulated. A `'winhighlight'`
---entry on the list window draws the prompt in its title as the selection band,
---a key listener settles the selection before mini.pick reads the key, and a
---`vim.paste` wrapper replaces the query with a paste, which no key reports.
---@param query string[]
function M._select(query)
  local picker = MiniPick.get_picker_state()
  if not picker or #query == 0 or #(MiniPick.get_picker_query() or {}) > 0 then
    return
  end
  local win = picker.windows.main
  MiniPick.set_picker_query(query)
  -- mini.pick rewrites only the `FloatBorder:` entry, so an appended one stays.
  vim.wo[win].winhighlight = vim.wo[win].winhighlight .. "," .. SELECTED_HL

  local paste, replace_paste = vim.paste, nil
  local function deselect()
    vim.on_key(nil, SELECT_NS)
    if vim.paste == replace_paste then
      vim.paste = paste
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.wo[win].winhighlight = vim.wo[win].winhighlight:gsub("," .. vim.pesc(SELECTED_HL), "")
    end
  end

  replace_paste = function(lines, phase)
    deselect()
    MiniPick.set_picker_query({})
    return paste(lines, phase)
  end
  vim.paste = replace_paste

  vim.on_key(function(key, typed)
    -- Keys a plugin feeds, like the preview's `zt`, are not the user's.
    if typed == "" then
      return
    end
    deselect()
    local action = selection.classify(key)
    if action == "replace" or action == "clear" then
      MiniPick.set_picker_query({})
    end
    if action == "clear" then
      return ""
    end
  end, SELECT_NS)
  -- Drops the listener and the paste wrapper when the picker stops while the
  -- query is still selected; fires on that picker's MiniPickStop.
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("MiniPickers.GrepSelection", { clear = true }),
    pattern = "MiniPickStop",
    once = true,
    callback = deselect,
  })
end

---Open the live grep picker scoped to one filesystem entry.
---
---The scope replaces the picker's plain name in the border label, since it is
---the part that actually varies between these pickers. The label is fitted
---from the left, so a path too long for the window keeps its tail.
---@param path string
---@param fs_type "file"|"directory"
function M.pick_in(path, fs_type)
  local cwd, globs = scope(path, fs_type)
  local label = vim.fn.fnamemodify(path, ":~:.") .. (fs_type == "directory" and "/" or "")
  return M.pick({ globs = globs }, { source = { cwd = cwd, name = "Grep live (" .. label .. ")" } })
end

return M

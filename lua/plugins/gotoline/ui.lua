local files = require("plugins.gotoline.files")
local match = require("plugins.gotoline.match")
local parse_mod = require("plugins.gotoline.parse")
local preview = require("plugins.gotoline.preview")

local M = {}

local NS_RESULTS = vim.api.nvim_create_namespace("gotoline-results")
local NS_PREVIEW = preview.NS
local MAX_RESULTS = 200
local HINT = "type a letter to find a file, or a number to jump in the current buffer"

---@class gotoline.State
---@field prompt_buf integer
---@field prompt_win integer
---@field results_buf integer
---@field results_win integer
---@field origin_buf integer
---@field origin_win integer
---@field locked_file string|nil
---@field results gotoline.Match[]
---@field selected integer

---@type gotoline.State|nil
local state = nil

local handlers = {}

---@param s {results: gotoline.Match[], selected: integer}
function handlers.select_next(s)
  if #s.results == 0 then
    return
  end
  s.selected = (s.selected % #s.results) + 1
end

---@param s {results: gotoline.Match[], selected: integer}
function handlers.select_prev(s)
  if #s.results == 0 then
    return
  end
  s.selected = ((s.selected - 2) % #s.results) + 1
end

---@param s {results: gotoline.Match[], selected: integer, locked_file: string|nil}
---@return string|nil new_prompt
function handlers.lock(s)
  local hit = s.results[s.selected]
  if not hit then
    return nil
  end
  s.locked_file = hit.path
  return hit.path .. ":"
end

---Reconcile the prompt with the current lock anchor (`<file>:`).
---  - prompt still starts with the anchor → no change.
---  - prompt is a strict prefix of the anchor (backspace from the right) → unlock,
---    return the remaining text so the user can keep editing.
---  - anything else (mid-anchor edit while in normal mode) → restore the anchor.
---@param s {locked_file: string|nil}
---@param prompt_text string
---@return string|nil rewritten_prompt
function handlers.unlock_if_colon_deleted(s, prompt_text)
  if not s.locked_file then
    return nil
  end
  local anchor = s.locked_file .. ":"
  if vim.startswith(prompt_text, anchor) then
    return nil
  end
  if vim.startswith(anchor, prompt_text) then
    s.locked_file = nil
    return prompt_text
  end
  return anchor
end

M._handlers = handlers

local function get_prompt()
  return vim.api.nvim_buf_get_lines(state.prompt_buf, 0, 1, false)[1] or ""
end

local function set_prompt(text)
  vim.api.nvim_buf_set_lines(state.prompt_buf, 0, -1, false, { text })
  pcall(vim.api.nvim_win_set_cursor, state.prompt_win, { 1, #text })
end

local function clear_results_view()
  vim.api.nvim_buf_clear_namespace(state.results_buf, NS_RESULTS, 0, -1)
  vim.api.nvim_buf_clear_namespace(state.results_buf, NS_PREVIEW, 0, -1)
end

---Switch the results buffer out of preview mode: detach treesitter,
---reset filetype, drop the line-number gutter and clear the window footer.
local function reset_results_buffer()
  pcall(vim.treesitter.stop, state.results_buf)
  vim.bo[state.results_buf].filetype = ""
  vim.wo[state.results_win].number = false
  pcall(vim.api.nvim_win_set_config, state.results_win, { footer = "" })
end

---Look up a filetype icon for `file_path` via mini.icons; returns nil if unavailable.
---@param file_path string
---@return string|nil icon
---@return string|nil hl_group
local function file_icon(file_path)
  local ok, icons = pcall(require, "mini.icons")
  if not ok then
    return nil, nil
  end
  local icon, hl = icons.get("file", vim.fn.fnamemodify(file_path, ":t"))
  return icon, hl
end

local function show_hint()
  state.results = {}
  state.selected = 1
  clear_results_view()
  reset_results_buffer()
  vim.api.nvim_buf_set_lines(state.results_buf, 0, -1, false, { HINT })
  vim.api.nvim_buf_set_extmark(state.results_buf, NS_RESULTS, 0, 0, {
    end_col = #HINT,
    hl_group = "Comment",
  })
end

local function paint_results()
  clear_results_view()
  reset_results_buffer()

  if #state.results == 0 then
    vim.api.nvim_buf_set_lines(state.results_buf, 0, -1, false, { "" })
    return
  end

  local lines = {}
  for i, r in ipairs(state.results) do
    lines[i] = r.path
  end
  vim.api.nvim_buf_set_lines(state.results_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_extmark(state.results_buf, NS_RESULTS, state.selected - 1, 0, {
    line_hl_group = "GotolineSelected",
    priority = 200,
  })
  -- Prepend a filetype icon to each result (inline virt_text, so match-position
  -- columns in the path remain accurate). matchfuzzypos returns 0-based bytes.
  for row, r in ipairs(state.results) do
    local icon, icon_hl = file_icon(r.path)
    if icon then
      vim.api.nvim_buf_set_extmark(state.results_buf, NS_RESULTS, row - 1, 0, {
        virt_text = { { icon .. " ", icon_hl or "Normal" } },
        virt_text_pos = "inline",
        priority = 210,
      })
    end
    for _, col in ipairs(r.positions or {}) do
      vim.api.nvim_buf_set_extmark(state.results_buf, NS_RESULTS, row - 1, col, {
        end_col = col + 1,
        hl_group = "GotolineMatch",
        priority = 220,
      })
    end
  end
  pcall(vim.api.nvim_win_set_cursor, state.results_win, { state.selected, 0 })
end

local function render_results_list(query)
  local root = files.root(vim.api.nvim_buf_get_name(state.origin_buf))
  files.list(root, function(paths)
    if not state or not vim.api.nvim_buf_is_valid(state.results_buf) then
      return
    end
    local results = match.rank(query, paths)
    if #results > MAX_RESULTS then
      results = vim.list_slice(results, 1, MAX_RESULTS)
    end
    state.results = results
    state.selected = 1
    paint_results()
  end)
end

local function render_preview_for(file_path, line)
  clear_results_view()
  local r = preview.render(state.results_buf, file_path, line)
  if not r.ok then
    return
  end

  vim.wo[state.results_win].number = true

  if r.target_row then
    pcall(vim.api.nvim_win_set_cursor, state.results_win, { r.target_row, 0 })
    vim.api.nvim_win_call(state.results_win, function()
      vim.cmd("normal! zz")
    end)
  end

  -- Anchor the filename label to the window border so it stays bottom-right
  -- of the preview window regardless of how short the buffer is.
  local name = vim.fn.fnamemodify(file_path, ":t")
  local icon, icon_hl = file_icon(file_path)
  local footer = icon and { { " " .. icon .. " ", icon_hl or "Normal" }, { name .. " ", "FloatFooter" } }
    or { { " " .. name .. " ", "FloatFooter" } }
  pcall(vim.api.nvim_win_set_config, state.results_win, {
    footer = footer,
    footer_pos = "right",
  })
end

local function origin_file()
  local name = vim.api.nvim_buf_get_name(state.origin_buf)
  return name ~= "" and name or nil
end

local function redraw()
  if not state then
    return
  end
  local parsed = parse_mod.parse(get_prompt(), state.locked_file)
  if parsed.mode == "empty" then
    show_hint()
  elseif parsed.mode == "filename" then
    render_results_list(parsed.file_query)
  elseif parsed.mode == "line_only" then
    local f = origin_file()
    if f then
      render_preview_for(f, parsed.line)
    else
      show_hint()
    end
  elseif parsed.mode == "locked" then
    -- Locked file paths are relative to the project root.
    local root = files.root(vim.api.nvim_buf_get_name(state.origin_buf))
    render_preview_for(root .. "/" .. parsed.file, parsed.line or 1)
  end
end

---Lock the currently-selected result and refresh. Used by `:` and `<CR>`-on-list.
local function lock_selection()
  local new_prompt = handlers.lock(state)
  if new_prompt then
    set_prompt(new_prompt)
    redraw()
  end
end

local function confirm()
  local parsed = parse_mod.parse(get_prompt(), state.locked_file)

  if parsed.mode == "filename" then
    lock_selection()
    return
  end

  local target_file, target_line
  if parsed.mode == "line_only" then
    target_file = origin_file()
    target_line = parsed.line
  elseif parsed.mode == "locked" and parsed.line then
    local root = files.root(vim.api.nvim_buf_get_name(state.origin_buf))
    target_file = root .. "/" .. parsed.file
    target_line = parsed.line
  end
  if not target_file or not target_line then
    return
  end
  if vim.fn.filereadable(target_file) ~= 1 then
    vim.notify("GoToLine: cannot read " .. target_file, vim.log.levels.WARN)
    return
  end

  local origin_win = state.origin_win
  M.close()
  if vim.api.nvim_win_is_valid(origin_win) then
    vim.api.nvim_set_current_win(origin_win)
  end
  vim.cmd("edit " .. vim.fn.fnameescape(target_file))
  pcall(vim.api.nvim_win_set_cursor, 0, { target_line, 0 })
  vim.cmd("normal! zz")
  -- The prompt window was in insert mode; ensure the user lands in normal mode
  -- in the destination buffer.
  vim.cmd("stopinsert")
end

function M.open()
  if state then
    return
  end
  local ui_info = vim.api.nvim_list_uis()[1]
  local total_w = (ui_info and ui_info.width) or vim.o.columns
  local total_h = (ui_info and ui_info.height) or vim.o.lines
  local width = math.min(120, math.floor(total_w * 0.8))
  local height = math.min(30, math.floor(total_h * 0.7))
  local row = math.floor((total_h - height) / 2)
  local col = math.floor((total_w - width) / 2)

  local origin_buf = vim.api.nvim_get_current_buf()
  local origin_win = vim.api.nvim_get_current_win()
  files.invalidate(files.root(vim.api.nvim_buf_get_name(origin_buf)))

  local prompt_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[prompt_buf].bufhidden = "wipe"
  -- Marker checked by plugin/blink.lua to skip completion on this buffer.
  vim.b[prompt_buf].gotoline_prompt = true
  local prompt_win = vim.api.nvim_open_win(prompt_buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = 1,
    border = "rounded",
    title = " GoToLine ",
    title_pos = "center",
    style = "minimal",
  })

  local results_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[results_buf].bufhidden = "wipe"
  local results_win = vim.api.nvim_open_win(results_buf, false, {
    relative = "editor",
    row = row + 3,
    col = col,
    width = width,
    height = height - 3,
    border = "rounded",
    style = "minimal",
  })
  vim.wo[results_win].cursorline = false
  vim.wo[results_win].number = false
  vim.wo[results_win].relativenumber = false

  state = {
    prompt_buf = prompt_buf,
    prompt_win = prompt_win,
    results_buf = results_buf,
    results_win = results_win,
    origin_buf = origin_buf,
    origin_win = origin_win,
    locked_file = nil,
    results = {},
    selected = 1,
  }

  vim.api.nvim_buf_attach(prompt_buf, false, {
    on_lines = function()
      vim.schedule(function()
        if not state then
          return
        end
        if state.locked_file then
          local rewritten = handlers.unlock_if_colon_deleted(state, get_prompt())
          if rewritten ~= nil then
            set_prompt(rewritten)
          end
        end
        redraw()
      end)
    end,
  })

  local function bmap(mode, lhs, rhs)
    vim.keymap.set(mode, lhs, rhs, { buffer = prompt_buf, nowait = true, silent = true })
  end

  local function nav(handler)
    return function()
      if state then
        handler(state)
        paint_results()
      end
    end
  end

  local nav_next = nav(handlers.select_next)
  local nav_prev = nav(handlers.select_prev)

  bmap("i", "<C-j>", nav_next)
  bmap("i", "<C-n>", nav_next)
  bmap("i", "<Tab>", nav_next)
  bmap("i", "<C-k>", nav_prev)
  bmap("i", "<C-p>", nav_prev)
  bmap("i", "<S-Tab>", nav_prev)
  bmap("i", "<CR>", confirm)
  bmap("i", ":", function()
    if state and not state.locked_file then
      lock_selection()
    end
  end)
  bmap("n", "q", M.close)
  bmap("n", "<Esc>", M.close)

  vim.cmd("startinsert!")
  redraw()
end

function M.close()
  if not state then
    return
  end
  local s = state
  state = nil
  for _, w in ipairs({ s.prompt_win, s.results_win }) do
    if w and vim.api.nvim_win_is_valid(w) then
      vim.api.nvim_win_close(w, true)
    end
  end
end

return M

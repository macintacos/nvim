---Side-by-side preview for mini.pick.
---
---mini.pick draws its preview in place of the list, in the picker's one window.
---This hangs a second float right of the list instead and keeps it showing the
---current item. The picker's own `source.preview` fills it: `default_preview`
---positions the cursor in whichever window shows the buffer it is handed, so a
---location item (grep hit, symbol, reference) lands on its line here too.
---
---Pickers opt in by passing `window = preview.window()` to `MiniPick.start`,
---which also narrows the list to leave room. Below `MIN_COLUMNS` the list takes
---the whole width and the preview stacks above it instead.

local windows = require("helpers.windows")

local M = {}

---Editor width below which there is no room for a preview beside the list.
M.MIN_COLUMNS = 120

local LIST_RATIO = 0.4
local STACKED_LIST_RATIO = 0.25
local STACKED_PREVIEW_RATIO = 0.4

-- Each float's border takes a cell either side.
local BORDERS = 4

---@class mini-pickers.preview.Layout
---@field list { width: integer, height?: integer } Overrides for the list window.
---@field beside? integer Width of a preview right of the list.
---@field above? integer Height of a preview on top of the list.

---Split the editor between the list and the preview: side by side when wide
---enough, else stacked with the preview on top.
---@param columns integer
---@param rows integer Editor height a float can use.
---@return mini-pickers.preview.Layout layout Sizes inside the borders.
function M._layout(columns, rows)
  if columns >= M.MIN_COLUMNS then
    local list = math.floor(LIST_RATIO * columns)
    return { list = { width = list }, beside = columns - list - BORDERS }
  end
  local content = rows - BORDERS
  if content < 2 then
    return { list = { width = columns } }
  end
  local list = math.max(math.floor(STACKED_LIST_RATIO * content), 1)
  local above = math.max(math.floor(STACKED_PREVIEW_RATIO * content), 1)
  return { list = { width = columns, height = list }, above = above }
end

---The geometry of a floating window, as `nvim_win_get_config` reports it for one.
---@class mini-pickers.preview.Placement : vim.api.keyset.win_config
---@field row integer
---@field col integer
---@field width integer
---@field height integer

---Float config for the preview, placed against the list window per `layout`.
---@param list mini-pickers.preview.Placement The list window's current config.
---@param layout { beside?: integer, above?: integer }
---@return vim.api.keyset.win_config
function M._float_config(list, layout)
  local config = {
    relative = "editor",
    anchor = list.anchor,
    border = list.border,
    title = { { " PREVIEW ", "MiniPickBorderText" } },
    zindex = list.zindex,
    style = "minimal",
    focusable = false,
  }
  if layout.beside then
    config.row, config.col = list.row, list.col + list.width + 2
    config.width, config.height = layout.beside, list.height
  else
    config.row, config.col = list.row - list.height - 2, list.col
    config.width, config.height = list.width, layout.above
  end
  return config
end

---Editor height a picker float can use; mirrors mini.pick's own bound.
---@return integer
local function editor_rows()
  local has_tabline = vim.o.showtabline == 2 or (vim.o.showtabline == 1 and #vim.api.nvim_list_tabpages() > 1)
  return vim.o.lines - vim.o.cmdheight - (has_tabline and 1 or 0) - (vim.o.laststatus > 0 and 1 or 0)
end

local function current_layout()
  return M._layout(vim.o.columns, editor_rows())
end

local function window_config()
  return current_layout().list
end

---Picker `window` option that opts into the side preview.
---@return table
function M.window()
  return { config = window_config }
end

---A fresh buffer for one preview; wiped as soon as the next replaces it.
---@return integer
local function scratch()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  return buf
end

---Keep a side preview in step with the active picker until it stops.
---@param preview fun(buf_id: integer, item: any) The picker's `source.preview`.
---@param main integer The picker's list window.
local function attach(preview, main)
  local ns = vim.api.nvim_create_namespace("mini_pick_side_preview")
  local group = vim.api.nvim_create_augroup("MiniPickers.PreviewSession", { clear = true })
  ---@type integer?
  local win
  local shown

  local function render()
    local matches = MiniPick.is_picker_active() and MiniPick.get_picker_matches()
    local item = matches and matches.current
    if not (win and vim.api.nvim_win_is_valid(win)) or item == shown then
      return
    end
    shown = item
    local buf = scratch()
    vim.api.nvim_win_set_buf(win, buf)
    if item ~= nil then
      preview(buf, item)
      vim.api.nvim_win_call(win, windows.reveal_cursor)
    end
    -- mini.pick has already redrawn for this key and is blocked in getcharstr,
    -- which does not repaint on its own.
    vim.cmd.redraw()
  end

  -- Opens, moves, or closes the float to fit the current editor size.
  local function place()
    local layout = current_layout()
    if not ((layout.beside or layout.above) and vim.api.nvim_win_is_valid(main)) then
      if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      win = nil
      return
    end
    local main_config = vim.api.nvim_win_get_config(main) --[[@as mini-pickers.preview.Placement]]
    local config = M._float_config(main_config, layout)
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_config(win, config)
    else
      win = vim.api.nvim_open_win(scratch(), false, vim.tbl_extend("force", config, { noautocmd = true }))
      shown = nil
    end
    render()
  end

  local function detach()
    vim.on_key(nil, ns)
    vim.api.nvim_del_augroup_by_id(group)
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  -- mini.pick emits no event when the current item moves, but every move is a
  -- key it reads. Scheduled so the picker has handled the key before we look.
  vim.on_key(function()
    vim.schedule(render)
  end, ns)

  -- Refresh the preview when matching lands: items arriving from an async
  -- source (rg, an LSP reply) and query changes both reset the current item
  -- without a move key.
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "MiniPickMatch", callback = render })

  -- Re-fit the float on resize. mini.pick refits the list from its own
  -- `VimResized` handler; scheduled so the list's new size is what gets read.
  vim.api.nvim_create_autocmd("VimResized", { group = group, callback = vim.schedule_wrap(place) })

  -- Tear the preview down with the picker it belongs to.
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "MiniPickStop", once = true, callback = detach })

  place()
end

---Attach a side preview to every picker started with `window = M.window()`.
function M.setup()
  -- Opt-in check on every picker start: `get_picker_opts` copies the options,
  -- but functions survive the copy, so our `window.config` is still ours.
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("MiniPickers.Preview", { clear = true }),
    pattern = "MiniPickStart",
    callback = function()
      local opts, state = MiniPick.get_picker_opts(), MiniPick.get_picker_state()
      if opts and state and opts.window.config == window_config then
        attach(opts.source.preview, state.windows.main)
      end
    end,
  })
end

return M

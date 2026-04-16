-- Neovim 0.12+ vim._core.ui2 overlay (experimental, no external plugin)
-- Filters noisy messages, adds titled rounded borders on msg/pager/dialog
-- windows, and reroutes oversized messages to the pager.

local ui2 = require("vim._core.ui2")
local msgs = require("vim._core.ui2.messages")

-- ── Config ──────────────────────────────────────────────────────────

local IGNORED_KINDS = {
  bufwrite = true,
  [""] = true,
  empty = true,
}

local SKIP_PATTERNS = {
  "%d+L, %d+B",
  "; after #%d+",
  "; before #%d+",
  "%d fewer lines",
  "%d more lines",
  "%d lines yanked",
}

local KIND_TITLES = {
  emsg = { " Error ", "ErrorMsg" },
  echoerr = { " Error ", "ErrorMsg" },
  lua_error = { " Error ", "ErrorMsg" },
  rpc_error = { " Error ", "ErrorMsg" },
  wmsg = { " Warning ", "WarningMsg" },
  echo = { " Info ", "Normal" },
  echomsg = { " Info ", "Normal" },
  lua_print = { " Print ", "Normal" },
  search_cmd = { " Search ", "Normal" },
  search_count = { " Search ", "Normal" },
  undo = { " Undo ", "Normal" },
  shell_out = { " Shell ", "Normal" },
  shell_err = { " Shell ", "ErrorMsg" },
  shell_cmd = { " Shell ", "Normal" },
  quickfix = { " Quickfix ", "Normal" },
  progress = { " Progress ", "Normal" },
  typed_cmd = { " Command ", "Normal" },
  list_cmd = { " List ", "Normal" },
  verbose = { " Verbose ", "Comment" },
}

-- ── State ────────────────────────────────────────────────────────────

local last_title = nil
local last_hl = "Normal"

-- ── Helpers ─────────────────────────────────────────────────────────

---Flatten a `msg_show` content list (chunks of `{hl_id, text, ...}`) into a plain string.
---@param content table|any
---@return string
local function content_to_text(content)
  if type(content) ~= "table" then
    return tostring(content or "")
  end
  local parts = {}
  for _, chunk in ipairs(content) do
    if type(chunk) == "table" and chunk[2] then
      parts[#parts + 1] = chunk[2]
    end
  end
  return table.concat(parts)
end

---Return true if a message should be filtered out (ignored kind or matches a skip pattern).
---@param kind string
---@param content table
---@return boolean
local function should_skip(kind, content)
  if IGNORED_KINDS[kind] then
    return true
  end
  local text = content_to_text(content)
  for _, pat in ipairs(SKIP_PATTERNS) do
    if text:find(pat) then
      return true
    end
  end
  return false
end

---Resolve a floating-window title + highlight for a message. Falls back to a
---truncated preview of the content when the kind is unknown.
---@param kind string
---@param content table
---@return string title
---@return string hl
local function resolve_title(kind, content)
  local entry = KIND_TITLES[kind]
  if entry then
    return entry[1], entry[2]
  end
  local text = vim.trim(content_to_text(content)):gsub("\n.*", "")
  if #text > 40 then
    text = text:sub(1, 37) .. "…"
  end
  return text ~= "" and (" " .. text .. " ") or "  Message ", "Normal"
end

---Re-style the ui2 window identified by `key` with a rounded border + current title.
---Extras are merged into the win config (e.g. `relative`, `anchor`, `height`).
---No-op if the window is missing, invalid, or hidden.
---@param key "msg"|"pager"|"dialog"
---@param extra table?
local function override_win(key, extra)
  local win = ui2.wins and ui2.wins[key]
  if not (win and vim.api.nvim_win_is_valid(win)) then
    return
  end
  if vim.api.nvim_win_get_config(win).hide then
    return
  end
  local cfg = {
    border = "rounded",
    style = "minimal",
    title = last_title and { { last_title, last_hl } } or nil,
    title_pos = last_title and "center" or nil,
  }
  for k, v in pairs(extra or {}) do
    cfg[k] = v
  end
  pcall(vim.api.nvim_win_set_config, win, cfg)
end

-- ── ui2 enable ──────────────────────────────────────────────────────

ui2.enable({
  enable = true,
  msg = {
    targets = {
      echo = "msg",
      echomsg = "msg",
      shell_ret = "msg",
      undo = "msg",
      wmsg = "msg",
      completion = "msg",
      confirm = "dialog",
      confirm_sub = "dialog",
      echoerr = "msg",
      emsg = "msg",
      list_cmd = "pager",
      lua_error = "msg",
      lua_print = "msg",
      progress = "msg",
      quickfix = "msg",
      rpc_error = "msg",
      search_cmd = "msg",
      search_count = "msg",
      shell_cmd = "msg",
      shell_err = "msg",
      shell_out = "msg",
      typed_cmd = "msg",
      verbose = "pager",
      wildlist = "msg",
    },
    cmd = { height = 0.5 },
    dialog = { height = 0.5 },
    msg = { height = 0.5, timeout = 2000 },
    pager = { height = 0.8 },
  },
})

-- ── Wrap set_pos: the single source of truth for window placement ───

local orig_set_pos = msgs.set_pos

msgs.set_pos = function(tgt)
  orig_set_pos(tgt)
  if tgt == nil or tgt == "msg" then
    override_win("msg", {
      relative = "editor",
      anchor = "NE",
      row = 1,
      col = vim.o.columns - 1,
    })
  elseif tgt == "pager" or tgt == "dialog" then
    local win = ui2.wins and ui2.wins[tgt]
    if win and vim.api.nvim_win_is_valid(win) then
      override_win(tgt, { height = vim.api.nvim_win_get_height(win) })
    end
  end
end

-- ── Wrap msg_show: filter + track title for the window override ─────

msgs.msg_show = function(kind, content, replace_last, _history, append, id, trigger)
  if should_skip(kind, content) then
    return
  end
  last_title, last_hl = resolve_title(kind, content)

  local tgt = ui2.cfg.msg.targets[kind] or ui2.cfg.msg.targets[trigger] or ui2.cfg.msg.target

  msgs.show_msg(tgt, kind, content, replace_last, append, id)
  msgs.set_pos(tgt)
end

-- ── Wrap show_msg: reroute oversized msg-target content to the pager ─

local orig_show_msg = msgs.show_msg
msgs.show_msg = function(tgt, kind, content, replace_last, append, id)
  if tgt == "msg" then
    local text = content_to_text(content)
    local lines = vim.split(text, "\n")
    local width = 0
    for _, line in ipairs(lines) do
      width = math.max(width, vim.api.nvim_strwidth(line))
    end
    if width > math.floor(vim.o.columns * 0.75) or #lines > 20 then
      vim.schedule(function()
        msgs.show_msg("pager", kind, content, replace_last, append, id)
        msgs.set_pos("pager")
      end)
      return
    end
  end
  orig_show_msg(tgt, kind, content, replace_last, append, id)
end

-- ── LSP progress ─────────────────────────────────────────────────────

local id = { LspProgressMessages = vim.api.nvim_create_augroup("LspProgressMessages", { clear = true }) }

-- Forward LSP progress reports into vim.api.nvim_echo with kind = "progress"
-- so ui2 routes them through the same styled msg window as every other
-- message, instead of relying on a separate notifier. Fires on every LSP
-- progress token update (begin/report/end) from any attached client.
vim.api.nvim_create_autocmd("LspProgress", {
  group = id.LspProgressMessages,
  callback = function(ev)
    local value = ev.data.params.value
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end
    local is_end = value.kind == "end"
    local msg = value.message and (client.name .. ": " .. value.message) or (client.name .. (is_end and ": done" or ""))
    vim.api.nvim_echo({ { msg } }, false, {
      id = "lsp." .. ev.data.client_id,
      kind = "progress",
      source = "vim.lsp",
      title = value.title,
      status = is_end and "success" or "running",
      percent = value.percentage,
    })
  end,
})

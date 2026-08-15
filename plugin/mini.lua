-- mini.nvim modules
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.align", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.bracketed", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.cursorword", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.extra", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.files", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.hipatterns", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.icons", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.pick", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.statusline", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.trailspace", version = "stable" },
  -- mini.input is in beta and has no stable tag yet — track main
  { src = "https://github.com/nvim-mini/mini.input" },
})

-- ============================================================================
-- mini.align
-- ============================================================================

require("mini.align").setup()

-- ============================================================================
-- mini.bracketed
-- ============================================================================

-- [/] motions for buffer, comment, conflict, diagnostic, file, indent, jump,
-- location, oldfile, quickfix, treesitter, undo, window, yank
require("mini.bracketed").setup()

-- ============================================================================
-- mini.input
-- ============================================================================

-- Provides the vim.ui.input() implementation (snacks.input is disabled)
require("mini.input").setup()

-- ============================================================================
-- mini.icons
-- ============================================================================

-- Creates the global MiniIcons table. Both mini.pick and mini.extra check for
-- it at render time and silently fall back to icon-less output when absent, so
-- this is what puts file icons on :Pick files/grep/buffers and kind icons on
-- the LSP symbol pickers.
require("mini.icons").setup()

-- ============================================================================
-- mini.pick / mini.extra
-- ============================================================================

-- Fuzzy picker. setup() also takes over vim.ui.select(), which is why
-- snacks sets picker.ui_select = false (see plugin/snacks.lua).
require("mini.pick").setup()

-- Registers the extra pickers (lsp, keymaps, manpages, git_commits, ...)
-- into MiniPick.registry, making them reachable as :Pick <name>.
require("mini.extra").setup()

-- LSP symbol pickers arrive doubly prefixed: Neovim formats every symbol as
-- "[Kind] name" (vim.lsp.util.symbols_to_items) and mini.extra prepends
-- "<path>│<lnum>│<col>│ " for the workspace scopes. The kind is already carried
-- by the icon and the path is what pushes the name off-screen, so both go.
local symbol_ns = vim.api.nvim_create_namespace("mini_pick_lsp_symbols")

-- Kinds worth listing. Servers emit a symbol per table key, so without this a
-- Lua file's outline is mostly `[1]`, `[2]`, and `desc`. Data filetypes are
-- exempt because there Object/Array/String *are* the structure — the same
-- carve-out the old snacks picker needed for toml.
local SYMBOL_KINDS = {
  Class = true,
  Constant = true,
  Constructor = true,
  Enum = true,
  EnumMember = true,
  Event = true,
  Field = true,
  Function = true,
  Interface = true,
  Method = true,
  Module = true,
  Namespace = true,
  Package = true,
  Property = true,
  Struct = true,
  TypeParameter = true,
  Variable = true,
}
local SYMBOL_KINDS_ALL_FT = { toml = true, json = true, jsonc = true, yaml = true, markdown = true }

-- Relative path when the file lives under cwd, otherwise just enough tail to
-- tell two files apart. Plain `pathshorten` is useless on the deep absolute
-- paths workspace symbols return — it yields "/o/h/C/n/0/s/n/r/l/v/_/u/x.lua".
---@param path string
---@return string
local function short_path(path)
  local rel = vim.fn.fnamemodify(path, ":.")
  if rel ~= path and #rel <= 40 then
    return rel
  end
  return "…/" .. vim.fn.fnamemodify(path, ":h:t") .. "/" .. vim.fn.fnamemodify(path, ":t")
end

-- Subdued italic labels for the right-aligned kind annotation: one highlight
-- group per kind, coloured by mixing that kind's icon colour with Comment so
-- each hue stays recognisable while sitting back from the symbol name. Mixing
-- toward Comment rather than toward the background is deliberate — catppuccin
-- runs with transparent_background, so Normal has no bg to blend with.
local KIND_MIX = 0.5

---@type table<string, true>
local kind_hl_made = {}

---Mix two 0xRRGGBB colours, keeping `alpha` of the first.
---@param a integer
---@param b integer
---@param alpha number
---@return integer
local function mix(a, b, alpha)
  local out = {}
  for i, shift in ipairs({ 65536, 256, 1 }) do
    local ca, cb = math.floor(a / shift) % 256, math.floor(b / shift) % 256
    out[i] = math.floor(ca * alpha + cb * (1 - alpha) + 0.5)
  end
  return out[1] * 65536 + out[2] * 256 + out[3]
end

---Highlight group for one kind's label, created on first use.
---@param kind string
---@param icon_hl string Highlight group mini.icons uses for this kind's icon.
---@return string
local function kind_label_hl(kind, icon_hl)
  local name = "MiniPickKind" .. kind:gsub("%W", "")
  if kind_hl_made[name] then
    return name
  end
  local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
  local icon = vim.api.nvim_get_hl(0, { name = icon_hl, link = false })
  local fg = comment.fg
  if icon.fg and comment.fg then
    fg = mix(icon.fg, comment.fg, KIND_MIX)
  end
  vim.api.nvim_set_hl(0, name, { fg = fg, italic = true })
  kind_hl_made[name] = true
  return name
end

-- Label colours are derived from the active theme's icon and Comment groups,
-- so drop the cache on a colorscheme change and let the next render rebuild
-- them against the new palette.
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    kind_hl_made = {}
  end,
})

---Split a mini.extra LSP symbol item into its display parts.
---@param item table
---@return string icon, string hl, string name, string kind
local function symbol_parts(item)
  local ok, icon, hl = pcall(MiniIcons.get, "lsp", item.kind)
  icon = ok and icon or " "
  -- Drop mini.extra's position prefix, or the icon it prepended when there is
  -- no position prefix, then split off Neovim's own "[Kind] " label.
  local raw = item.text:match("^.*│ (.*)$")
  if raw == nil then
    raw = item.text:gsub("^" .. vim.pesc(icon) .. "%s*", "")
  end
  local kind, name = raw:match("^%[([^%]]*)%]%s*(.*)$")
  return icon, (ok and hl or "Normal"), (name or raw), (kind or item.kind or "")
end

---Build a `source.show` for the LSP symbol pickers.
---
---Buffer text is only "<icon> <name>" — the kind, and the location for
---workspace scopes, are right-aligned virtual text. Being virtual keeps them
---out of the buffer entirely, so they read as labels and can never be matched
---by a query (typing "string" won't surface every String-kind symbol).
---@param with_location boolean Prefix the annotation with "<path>:<lnum>".
---@return fun(buf_id: integer, items: table[], query: string[])
local function make_symbol_show(with_location)
  return function(buf_id, items, query)
    local rows, display = {}, {}
    for i, item in ipairs(items) do
      local icon, hl, name, kind = symbol_parts(item)
      rows[i] = {
        icon = icon,
        hl = hl,
        kind = kind,
        loc = (with_location and item.path) and ("%s:%d"):format(short_path(item.path), item.lnum or 1) or "",
      }
      display[i] = vim.tbl_extend("force", item, { text = icon .. " " .. name })
    end

    MiniPick.default_show(buf_id, display, query)

    -- Colour the kind icon and hang the annotation off the right edge. Runs
    -- after default_show so it layers on top of the query match highlights.
    vim.api.nvim_buf_clear_namespace(buf_id, symbol_ns, 0, -1)
    for i, row in ipairs(rows) do
      vim.api.nvim_buf_set_extmark(buf_id, symbol_ns, i - 1, 0, {
        end_col = #row.icon,
        hl_group = row.hl,
        priority = 199,
      })
      local annotation = {}
      if row.loc ~= "" then
        annotation[#annotation + 1] = { row.loc .. "  ", "Comment" }
      end
      if row.kind ~= "" then
        annotation[#annotation + 1] = { row.kind, kind_label_hl(row.kind, row.hl) }
      end
      if #annotation > 0 then
        vim.api.nvim_buf_set_extmark(buf_id, symbol_ns, i - 1, 0, {
          virt_text = annotation,
          virt_text_pos = "right_align",
          priority = 199,
        })
      end
    end
  end
end

---Build a `source.match` that matches on symbol names alone.
---
---mini.pick derives its match strings from each item's raw `text`, which still
---carries the path and the "[Kind]" label, so both would otherwise be
---queryable. Matching against the cleaned names keeps the query honest.
---@param do_filter boolean Also drop kinds outside SYMBOL_KINDS.
---@return fun(stritems: string[], inds: integer[], query: string[]): integer[]
local function make_symbol_match(do_filter)
  return function(stritems, inds, query)
    local items = MiniPick.get_picker_items() or {}
    local names = {}
    for i, stritem in ipairs(stritems) do
      names[i] = items[i] and select(3, symbol_parts(items[i])) or stritem
    end

    local kept = {}
    for _, i in ipairs(inds) do
      local kind = items[i] and items[i].kind
      if not do_filter or kind == nil or SYMBOL_KINDS[kind] then
        kept[#kept + 1] = i
      end
    end

    -- default_match short-circuits an empty query to *every* stritem, ignoring
    -- the inds we just filtered — which is the picker's opening state, so the
    -- filter has to be returned directly here.
    if #query == 0 then
      return kept
    end
    return MiniPick.default_match(names, kept, query, { sync = true })
  end
end

MiniPick.registry.lsp = function(local_opts)
  local_opts = local_opts or {}
  local scope = tostring(local_opts.scope or "")
  -- references/definition/etc. are location lists, not symbols — leave them be.
  if not scope:find("symbol") then
    return MiniExtra.pickers.lsp(local_opts)
  end

  local source = { show = make_symbol_show(scope:find("workspace") ~= nil) }
  -- The live scope drives its query through `source.match`, so overriding it
  -- would break the search. Its results come from the server already scoped
  -- to the query, which is far less noisy than a whole-file outline anyway.
  if scope ~= "workspace_symbol_live" then
    source.match = make_symbol_match(not SYMBOL_KINDS_ALL_FT[vim.bo.filetype])
  end
  return MiniExtra.pickers.lsp(local_opts, { source = source })
end

-- Commits that touched the line under the cursor — the one picker neither
-- mini.pick nor mini.extra provides. `-L` restricts the log to a line range
-- and forces patch output, so `-s` suppresses it back down to one line per
-- commit; choosing one opens its full diff in a scratch tab.
MiniPick.registry.git_blame_line = function()
  local path = vim.fn.expand("%:p")
  if path == "" then
    vim.notify("git_blame_line: buffer has no file", vim.log.levels.WARN)
    return
  end
  local lnum = vim.fn.line(".")

  -- Same preview/choose shape mini.extra's git_commits uses, so both git
  -- pickers behave identically: diff in the preview pane, and choosing one
  -- replaces the target window rather than opening somewhere new.
  local function show_commit(buf_id, item)
    local hash = type(item) == "string" and item:match("^%x+")
    if not hash then
      return
    end
    vim.bo[buf_id].syntax = "git"
    vim.system(
      { "git", "--no-pager", "show", hash },
      { text = true },
      vim.schedule_wrap(function(res)
        if vim.api.nvim_buf_is_valid(buf_id) then
          vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, vim.split(res.stdout or "", "\n"))
        end
      end)
    )
  end

  return MiniPick.builtin.cli({
    command = { "git", "log", "-s", "--format=%h %as %an: %s", ("-L%d,%d:%s"):format(lnum, lnum, path) },
  }, {
    source = {
      name = ("Git blame line %d"):format(lnum),
      preview = show_commit,
      choose = function(item)
        local win = (MiniPick.get_picker_state().windows or {}).target
        if win == nil or not vim.api.nvim_win_is_valid(win) then
          return
        end
        local buf_id = vim.api.nvim_create_buf(true, true)
        show_commit(buf_id, item)
        vim.bo[buf_id].filetype = "git"
        vim.api.nvim_win_set_buf(win, buf_id)
      end,
    },
  })
end

-- ============================================================================
-- mini.statusline
-- ============================================================================

-- Override default section backgrounds to match the dark theme
local function set_statusline_highlights()
  vim.api.nvim_set_hl(0, "MiniStatuslineDevinfo", { bg = "#1a1a2e" })
  vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo", { bg = "#1a1a2e" })
  vim.api.nvim_set_hl(0, "MiniStatuslinePackUpdates", { fg = "#a6e3a1", bg = "#1a1a2e" })
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_statusline_highlights })
set_statusline_highlights()

local pack_updates = require("config.pack-updates")
local map = require("helpers.mappings").map

-- Custom statusline section: shows a braille spinner while checking
-- for plugin updates, then icon + count when updates are available.
---@param args { trunc_width: integer }
---@return string
local function section_pack_updates(args)
  if MiniStatusline.is_truncated(args.trunc_width) then
    return ""
  end
  local frame = pack_updates.spinner_frame()
  if frame then
    return frame
  end
  local n = pack_updates.update_count()
  if n > 0 then
    return " " .. n
  end
  return ""
end

require("mini.statusline").setup({
  content = {
    active = function()
      local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
      local git = MiniStatusline.section_git({ trunc_width = 40 })
      local diff = MiniStatusline.section_diff({ trunc_width = 75 })
      local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
      local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
      local filename = MiniStatusline.section_filename({ trunc_width = 140 })
      local location = MiniStatusline.section_location({ trunc_width = 75 })
      local search = MiniStatusline.section_searchcount({ trunc_width = 75 })
      local updates = section_pack_updates({ trunc_width = 75 })

      return MiniStatusline.combine_groups({
        { hl = mode_hl, strings = { mode } },
        { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
        "%<",
        { hl = "MiniStatuslineFilename", strings = { filename } },
        "%=",
        { hl = "MiniStatuslinePackUpdates", strings = { updates } },
        { hl = mode_hl, strings = { search, location } },
      })
    end,
  },
})

-- ============================================================================
-- mini.files
-- ============================================================================

-- Half the screen width, used for the preview pane
local function preview_width()
  return math.floor(vim.o.columns * 0.5)
end

-- Measures the widest entry in a directory listing buffer so we can
-- auto-fit the preview column to its content instead of a fixed width.
-- Directory lines follow the format /<path_id>/<icon>/<name> where
-- the path_id and separators are concealed — we only measure icon+name.
-- Returns nil when the buffer isn't a directory listing.
---@param buf_id integer
---@return integer?
local function directory_content_width(buf_id)
  local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
  local max_width, found = 0, false
  for _, line in ipairs(lines) do
    local icon, name = line:match("^/%d+/(.-)/(.*)")
    if icon then
      found = true
      local w = vim.fn.strdisplaywidth(icon) + vim.fn.strdisplaywidth(name)
      if w > max_width then
        max_width = w
      end
    end
  end
  return found and max_width or nil
end

---@type string?
local cut_line = nil

local augroup = vim.api.nvim_create_augroup("mini_files_config", { clear = true })

-- Keep the preview pane width proportional when the terminal is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup,
  callback = function()
    local ok, files = pcall(require, "mini.files")
    if not ok then
      return
    end
    local width = preview_width()
    files.config.windows.width_preview = width
    pcall(files.refresh, { windows = { width_preview = width } })
  end,
})

-- Cap window height at 70% of screen and auto-fit directory preview
-- columns to their content width instead of using the full preview width
vim.api.nvim_create_autocmd("User", {
  group = augroup,
  pattern = "MiniFilesWindowUpdate",
  ---@param args { data: { win_id: integer, buf_id: integer } }
  callback = function(args)
    local win_id = args.data.win_id
    local buf_id = args.data.buf_id
    local config = vim.api.nvim_win_get_config(win_id)
    local changed = false

    local max_height = math.floor(vim.o.lines * 0.7)
    if config.height > max_height then
      config.height = max_height
      changed = true
    end

    local files = require("mini.files")
    if config.width == files.config.windows.width_preview then
      local content_width = directory_content_width(buf_id)
      if content_width then
        config.width = content_width + 1
        changed = true
      end
    end

    if changed then
      vim.api.nvim_win_set_config(win_id, config)
    end
  end,
})

-- Disable scrolloff inside mini.files windows so entries at the top
-- and bottom of the list aren't pushed away from the edge
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "minifiles",
  callback = function()
    vim.opt_local.scrolloff = 0
  end,
})

-- Buffer-local keymaps set each time a new explorer buffer is created
vim.api.nvim_create_autocmd("User", {
  group = augroup,
  pattern = "MiniFilesBufferCreate",
  ---@param args { data: { buf_id: integer } }
  callback = function(args)
    local buf = args.data.buf_id
    local files = require("mini.files")

    -- <CR>: open file (closing the explorer) or expand directory. If the
    -- buffer has pending edits, apply them first so go_in's close_on_file
    -- doesn't trip the "Close without synchronization?" prompt.
    -- synchronize() always calls vim.fn.confirm; stub it to return 1 (Yes)
    -- so fs actions apply silently.
    map("Open file or expand directory", "n", "<CR>", function()
      if vim.bo[buf].modified then
        local orig_confirm = vim.fn.confirm
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.fn.confirm = function()
          return 1
        end
        local ok, err = pcall(files.synchronize)
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.fn.confirm = orig_confirm
        if not ok then
          vim.notify(tostring(err), vim.log.levels.ERROR)
          return
        end
      end
      local entry = files.get_fs_entry()
      if entry then
        files.go_in({ close_on_file = true })
      end
    end, { buffer = buf })

    -- Insert-mode <CR>: drop back to normal mode instead of inserting a
    -- newline. After typing a name with `o`/`i`, Enter feels like commit;
    -- landing in normal mode lets the existing n-mode <CR> sync and open.
    map("Leave insert mode", "i", "<CR>", "<Esc>", { buffer = buf })

    -- Route :w through BufWriteCmd. mini.files creates scratch buffers
    -- (buftype=nofile) which would otherwise reject :w with E382.
    vim.bo[buf].buftype = "acwrite"

    -- Intercept :w to trigger synchronize instead of a regular file write —
    -- prompts the user to confirm pending file system changes
    vim.api.nvim_create_autocmd("BufWriteCmd", {
      buffer = buf,
      callback = function()
        files.synchronize()
      end,
    })

    -- :q (and therefore :wq, :x) closes the whole explorer, matching
    -- the q / <Esc> keymap behavior. Scheduled so the original :q
    -- finishes first, then files.close() cleans up the rest.
    vim.api.nvim_create_autocmd("QuitPre", {
      buffer = buf,
      callback = function()
        vim.schedule(function()
          pcall(files.close)
        end)
      end,
    })

    -- <C-s>: synchronize pending filesystem changes with a confirm prompt.
    -- Overrides the global <C-s> mapping for this buffer because the global
    -- one uses <cmd>w<cr>, which runs :w in a restricted context where
    -- vim.fn.confirm returns its default (Yes) without prompting — silently
    -- auto-applying changes. Feeding <Esc> afterwards exits insert/visual
    -- mode so the keymap behaves consistently across modes.
    map("Synchronize mini.files", { "n", "i", "x", "s" }, "<C-s>", function()
      files.synchronize()
      local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
      vim.api.nvim_feedkeys(esc, "n", false)
    end, { buffer = buf })

    -- H: jump the explorer back to the current working directory.
    -- Useful when nested deep in a tree and you want to start over from
    -- the project root without closing and reopening the explorer.
    map("Go to cwd root", "n", "H", function()
      files.open(vim.uv.cwd(), false)
    end, { buffer = buf })

    -- q / <Esc>: close the explorer, synchronizing first so any pending
    -- edits are not silently dropped — the confirm prompt still runs.
    local function sync_and_close()
      files.synchronize()
      files.close()
    end

    map("Sync and close", "n", "q", sync_and_close, { buffer = buf })
    map("Sync and close", "n", "<Esc>", sync_and_close, { buffer = buf })

    -- mm: cut the entry under the cursor. Stashes the entire buffer line
    -- (including the concealed /<path_id>/ prefix) in a module-local
    -- variable and removes it from the buffer. Preserving the path_id is
    -- what lets a subsequent paste be recognized by mini.files's diff as
    -- a move rather than a delete + create.
    map("Cut entry (paste with p)", "n", "mm", function()
      local lnum = vim.api.nvim_win_get_cursor(0)[1]
      local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
      if not line or line == "" then
        return
      end
      cut_line = line
      vim.api.nvim_buf_set_lines(buf, lnum - 1, lnum, false, {})
    end, { buffer = buf })

    -- p: paste the previously cut entry below the cursor in any mini.files
    -- buffer. The move is not committed until the user synchronizes
    -- (:w / <C-s> / q), so this is safe to undo by closing without sync.
    map("Paste cut entry", "n", "p", function()
      if not cut_line then
        vim.notify("mini.files: nothing to paste", vim.log.levels.WARN)
        return
      end
      local lnum = vim.api.nvim_win_get_cursor(0)[1]
      vim.api.nvim_buf_set_lines(buf, lnum, lnum, false, { cut_line })
      cut_line = nil
    end, { buffer = buf })

    -- <M-p>: toggle the preview pane on/off. Flipping the config flag
    -- alone doesn't redraw, so we re-set the current branch to force
    -- mini.files to rebuild the layout with the new preview setting.
    map("Toggle preview pane", "n", "<M-p>", function()
      files.config.windows.preview = not files.config.windows.preview
      local state = files.get_explorer_state()
      if state then
        local branch = vim.list_slice(state.branch, 1, state.depth_focus)
        files.set_branch(branch, { depth_focus = state.depth_focus })
      end
    end, { buffer = buf })

    -- yp / yP: yank the path of the entry under the cursor to the system
    -- clipboard. yp gives a path relative to cwd, yP gives the absolute
    -- path. In visual mode, copies one path per selected line, newline-
    -- separated. Visual mode reads the live selection via line("v") /
    -- line(".") rather than '< / '> (those reflect the *previous*
    -- selection until exit), then feeds <Esc> so yank also exits visual
    -- mode like Vim's default y.
    local function copy_paths(transform)
      return function()
        local mode = vim.fn.mode()
        local lnums = {}
        if mode == "v" or mode == "V" or mode == "\22" then
          local s = math.min(vim.fn.line("v"), vim.fn.line("."))
          local e = math.max(vim.fn.line("v"), vim.fn.line("."))
          for i = s, e do
            table.insert(lnums, i)
          end
          local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
          vim.api.nvim_feedkeys(esc, "n", false)
        else
          lnums = { vim.api.nvim_win_get_cursor(0)[1] }
        end

        local paths = {}
        for _, lnum in ipairs(lnums) do
          local entry = files.get_fs_entry(buf, lnum)
          if entry then
            table.insert(paths, transform(entry.path))
          end
        end
        if #paths == 0 then
          vim.notify("mini.files: no entry under cursor", vim.log.levels.WARN)
          return
        end
        vim.fn.setreg("+", table.concat(paths, "\n"))
        vim.notify(("Copied %d path%s to clipboard"):format(#paths, #paths == 1 and "" or "s"))
      end
    end

    map(
      "Copy relative path",
      { "n", "x" },
      "yp",
      copy_paths(function(p)
        return vim.fn.fnamemodify(p, ":.")
      end),
      { buffer = buf }
    )

    map(
      "Copy absolute path",
      { "n", "x" },
      "yP",
      copy_paths(function(p)
        return p
      end),
      { buffer = buf }
    )
  end,
})

require("mini.files").setup({
  windows = {
    preview = true,
    width_preview = preview_width(),
  },
  options = {
    use_as_default_explorer = true,
  },
})

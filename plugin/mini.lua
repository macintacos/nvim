-- mini.nvim modules
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.align", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.bracketed", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.cmdline", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.cursorword", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.extra", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.files", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.hipatterns", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.icons", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.indentscope", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.notify", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.pick", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.sessions", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.starter", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.statusline", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.trailspace", version = "stable" },
  -- mini.input is in beta and has no stable tag yet — track main
  { src = "https://github.com/nvim-mini/mini.input" },
})

-- ============================================================================
-- Bare setup() modules
-- ============================================================================

-- Modules whose whole configuration is `require(...).setup()`. Add a name here
-- and it is wired up; anything needing options or extra wiring gets its own
-- section below.
local bare_setup = {
  "mini.align",
  -- [/] motions for buffer, comment, conflict, diagnostic, file, indent, jump,
  -- location, oldfile, quickfix, treesitter, undo, window, yank
  "mini.bracketed",
  -- Creates the global MiniIcons table. Both mini.pick and mini.extra check for
  -- it at render time and silently fall back to icon-less output when absent, so
  -- this is what puts file icons on :Pick files/grep/buffers and kind icons on
  -- the LSP symbol pickers.
  "mini.icons",
  -- Provides the vim.ui.input() implementation (snacks.input is disabled)
  "mini.input",
  -- Floating notifications and LSP progress reports; replaces the snacks
  -- notifier, which plugin/snacks.lua disables.
  "mini.notify",
}

for _, name in ipairs(bare_setup) do
  require(name).setup()
end

-- setup() only builds the notification machinery — this is what routes
-- vim.notify through it.
vim.notify = require("mini.notify").make_notify()

-- ============================================================================
-- mini.cmdline
-- ============================================================================

-- Autocorrects misspelled commands and options, and peeks at the lines a
-- `:range` refers to. Its autocomplete is off because blink.cmp already drives
-- cmdline completion (see plugin/blink.lua) and both would open a popup.
require("mini.cmdline").setup({
  autocomplete = { enable = false },
})

-- ============================================================================
-- mini.indentscope
-- ============================================================================

-- Scope indicator only: the `ii`/`ai` textobjects and `[i`/`]i` motions it maps
-- by default are already provided by snacks.scope. Animation is off to match
-- vim.g.snacks_animate = false.
local indentscope = require("mini.indentscope")
indentscope.setup({
  draw = { animation = indentscope.gen_animation.none() },
  mappings = {
    object_scope = "",
    object_scope_with_border = "",
    goto_top = "",
    goto_bottom = "",
  },
})

-- ============================================================================
-- mini.pick / mini.extra
-- ============================================================================

-- Fuzzy picker. setup() also takes over vim.ui.select(), which is why
-- snacks sets picker.ui_select = false (see plugin/snacks.lua).
require("mini.pick").setup({
  mappings = {
    -- <Tab>/<S-Tab> walk the match list. The two actions they displace take
    -- over the <C-n>/<C-p> that move_down/move_up just vacated.
    move_down = "<Tab>",
    move_up = "<S-Tab>",
    toggle_preview = "<C-p>",
    toggle_info = "<C-n>",
  },
})

-- Registers the extra pickers (lsp, keymaps, manpages, git_commits, ...)
-- into MiniPick.registry, making them reachable as :Pick <name>. Must run
-- after mini.pick's setup(), which creates the MiniPick table it registers into.
require("mini.extra").setup()

-- Customised registry entries: `:Pick files` with its own preview key, LSP
-- symbol pickers (a document-symbol outline plus thinned workspace scopes),
-- and a blame picker for the line under the cursor.
require("plugins.mini-pickers").setup()

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

-- ============================================================================
-- mini.sessions / mini.starter
-- ============================================================================

-- Directories that never get a session of their own, carried over from the
-- auto-session config this replaced. They aren't projects, so a session for
-- them would accumulate without ever being worth restoring.
local session_suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" }

-- Session name for the cwd: the absolute path with `/` replaced by `%`. Gives
-- every project its own file under `config.directory` while keeping the project
-- itself clean — mini.sessions' other mode drops a Session.vim in each root.
---@return string
local function session_name()
  return (vim.fn.getcwd():gsub("/", "%%"))
end

-- vim.fs.normalize rather than fnamemodify(":p:h") — the latter resolves a path
-- differently depending on whether the directory exists, silently collapsing
-- `~/Projects` to `$HOME` when it doesn't.
---@param dir string Absolute path, as returned by getcwd()
---@return boolean
local function session_suppressed(dir)
  for _, suppressed in ipairs(session_suppressed_dirs) do
    if dir == vim.fs.normalize(suppressed) then
      return true
    end
  end
  return false
end

-- True when this Neovim holds something worth persisting: at least one listed
-- buffer backed by a real file. The starter buffer is `nobuflisted`, so quitting
-- straight from the start screen reports false — without this, that would
-- overwrite the project's good session with an empty one.
---@return boolean
local function session_has_content()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.fn.buflisted(buf) == 1 and vim.api.nvim_buf_get_name(buf) ~= "" then
      return true
    end
  end
  return false
end

require("mini.sessions").setup({
  -- mini.starter has to win at VimEnter: autoread would restore the session
  -- first and the start screen would never be shown.
  autoread = false,
  -- autowrite only fires when v:this_session is set, which is never true for a
  -- project whose session hasn't been read yet. The autocmd below owns writing
  -- instead, so a project gets a session without ever being saved by hand.
  autowrite = false,
  hooks = { pre = { write = require("helpers.windows").close_all_floating_wins } },
})

-- Writes the cwd's session on exit, which is what makes sessions appear without
-- being asked for. Guarded so an empty or throwaway Neovim can't clobber a real
-- session. Fires: VimLeavePre, late enough to capture the final layout but
-- while windows still exist for :mksession.
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("mini_sessions_autosave", { clear = true }),
  callback = function()
    if session_suppressed(vim.fn.getcwd()) or not session_has_content() then
      return
    end
    require("mini.sessions").write(session_name())
  end,
})

local starter = require("mini.starter")

-- The cwd's own session, pinned above every other section. Returns nothing when
-- the project has no session yet. This is a function rather than a table because
-- items are evaluated when the screen is drawn, not when setup() runs — by then
-- the session written by a previous Neovim has been detected.
---@return table[]
local function session_resume_item()
  local name = session_name()
  if not MiniSessions.detected[name] then
    return {}
  end
  return {
    {
      name = "Resume " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":~"),
      action = function()
        MiniSessions.read(name)
      end,
      section = "Resume",
    },
  }
end

-- Every other detected session, most recently written first. The cwd's own is
-- filtered out because session_resume_item() already pins it at the top.
---@return table[]
local function other_session_items()
  local current = session_name()
  local names = {}
  for name, _ in pairs(MiniSessions.detected) do
    if name ~= current then
      table.insert(names, name)
    end
  end
  table.sort(names, function(a, b)
    return MiniSessions.detected[a].modify_time > MiniSessions.detected[b].modify_time
  end)

  local items = {}
  for _, name in ipairs(names) do
    table.insert(items, {
      name = vim.fn.fnamemodify((name:gsub("%%", "/")), ":~"),
      action = function()
        MiniSessions.read(name)
      end,
      section = "Sessions",
    })
  end
  return items
end

-- What is worth reaching for before any file is open: the README, the two
-- pickers, and the project switcher — this screen is exactly where you land
-- after realising Neovim opened in the wrong directory.
---@return table[]
local function project_items()
  local items = {
    { name = "Find file", action = MiniPick.registry.files, section = "Project" },
    { name = "Grep", action = MiniPick.registry.grep_live, section = "Project" },
    {
      name = "Switch project",
      action = function()
        require("plugins.projects").open()
      end,
      section = "Project",
    },
  }

  -- README leads when the project has one — the thing most often wanted from a
  -- cold start, and what the auto-session setup used to open on its own.
  local readme = vim.fs.joinpath(vim.fn.getcwd(), "README.md")
  if vim.fn.filereadable(readme) == 1 then
    table.insert(items, 1, {
      name = "Open README",
      action = function()
        vim.cmd.edit(vim.fn.fnameescape(readme))
      end,
      section = "Project",
    })
  end

  return items
end

-- Rendered only when something is actually out of date. The count comes from
-- the disk cache config.pack-updates fills during init; on the first launch
-- after that cache expires the check is still running when this renders, so the
-- item turns up next launch instead. The statusline shows it live either way.
---@return table[]
local function pack_update_item()
  local n = require("config.pack-updates").update_count()
  if n == 0 then
    return {}
  end
  return {
    {
      name = ("Update plugins (%d)"):format(n),
      action = function()
        vim.pack.update()
      end,
      section = "Plugins",
    },
  }
end

---Run git in the cwd, returning trimmed stdout or nil on any failure.
---@param args string[]
---@return string?
local function git(args)
  local ok, res = pcall(function()
    return vim.system(vim.list_extend({ "git" }, args), { text = true }):wait(300)
  end)
  if not ok or res.code ~= 0 then
    return nil
  end
  return vim.trim(res.stdout)
end

-- Distance from the branch this one merges into. The worktree layout already
-- puts the current branch in the directory name, so the useful thing to show is
-- how far it has drifted from the default. Synchronous because `rev-list
-- --count` is ~5ms on a warm repo; the 300ms cap stops a pathological one from
-- stalling startup, and any failure just drops the line.
---@return string?
local function branch_divergence()
  local default = git({ "rev-parse", "--abbrev-ref", "origin/HEAD" })
  if not default then
    return nil
  end
  local counts = git({ "rev-list", "--left-right", "--count", default .. "...HEAD" })
  if not counts then
    return nil
  end
  local behind, ahead = counts:match("(%d+)%s+(%d+)")
  if not behind then
    return nil
  end
  behind, ahead = tonumber(behind), tonumber(ahead)

  if ahead == 0 and behind == 0 then
    return "in sync with " .. default
  end
  local parts = {}
  if ahead > 0 then
    table.insert(parts, "↑" .. ahead)
  end
  if behind > 0 then
    table.insert(parts, "↓" .. behind)
  end
  return table.concat(parts, " ") .. " vs " .. default
end

---@return string
local function starter_header()
  local hour = tonumber(vim.fn.strftime("%H"))
  local part = (hour < 12 and "morning") or (hour < 18 and "afternoon") or "evening"
  local lines = {
    ("Good %s, %s"):format(part, vim.uv.os_get_passwd().username),
    vim.fn.fnamemodify(vim.fn.getcwd(), ":~"),
  }
  local divergence = branch_divergence()
  if divergence then
    lines[#lines] = lines[#lines] .. "  " .. divergence
  end
  return table.concat(lines, "\n")
end

-- mini.starter's default footer spells every key out in <>-notation over six
-- lines. Neither mini.icons nor nvim-web-devicons carries keyboard glyphs —
-- both are filetype/LSP-kind icon sets — so these are the plain Unicode key
-- symbols instead, the same ones macOS prints on its own menus.
--
-- Laid out as a grid: within each column the symbols are right-aligned and the
-- labels left-aligned, so the two rows line up vertically. Widths come from
-- strdisplaywidth rather than `#` because every symbol here is multibyte, and
-- mini.starter's aligning hook derives a single left pad from the widest line
-- and applies it to all of them — so a grid built here survives centering.
-- ⌃n/⌃p and ⌥j/⌥k also move, left out to keep the rows short.
---@return string
local function build_starter_footer()
  local rows = {
    { { "↑↓", "move" }, { "⏎", "open" }, { "⌫", "delete" } },
    { { "⎋", "reset" }, { "⌃c", "close" } },
  }

  local width = vim.fn.strdisplaywidth
  local sym_w, label_w = {}, {}
  for _, row in ipairs(rows) do
    for col, pair in ipairs(row) do
      sym_w[col] = math.max(sym_w[col] or 0, width(pair[1]))
      label_w[col] = math.max(label_w[col] or 0, width(pair[2]))
    end
  end

  local lines = { "󰌌  type to filter" }
  for _, row in ipairs(rows) do
    local cells = {}
    for col, pair in ipairs(row) do
      local sym = string.rep(" ", sym_w[col] - width(pair[1])) .. pair[1]
      local label = pair[2] .. string.rep(" ", label_w[col] - width(pair[2]))
      table.insert(cells, sym .. "  " .. label)
    end
    -- Trailing pad would count toward this line's width and shift the whole
    -- centered block, so it comes off before the line is kept.
    table.insert(lines, (table.concat(cells, "   "):gsub("%s+$", "")))
  end

  return table.concat(lines, "\n")
end

local starter_footer = build_starter_footer()

-- Sections render in order of first appearance, so "Resume" leads the screen.
starter.setup({
  items = {
    session_resume_item,
    project_items,
    starter.sections.recent_files(5, true, false),
    other_session_items,
    pack_update_item,
    starter.sections.builtin_actions(),
  },
  header = starter_header,
  footer = starter_footer,
})

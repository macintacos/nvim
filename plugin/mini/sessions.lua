---Reads and writes `:mksession` files, one per project directory.
---@see https://github.com/nvim-mini/mini.sessions/blob/main/doc/mini-sessions.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.sessions", version = "stable" } })

local session_name = require("helpers.sessions").name

-- Directories that never get a session of their own, carried over from the
-- auto-session config this replaced. They aren't projects, so a session for
-- them would accumulate without ever being worth restoring.
local session_suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" }

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

-- Directories whose buffers never reach a session file. macOS hangs $TMPDIR off
-- /private/var/folders, and /tmp resolves to /private/tmp — where coding agents
-- drop the prompt file they hand to $EDITOR. Scratch buffers, agent workspaces,
-- and anything piped through a temp file live under one of the two; none of it
-- exists to be reopened tomorrow.
local session_excluded_dirs = { "/private/var/folders", "/private/tmp" }

-- resolve() first because Neovim reports those paths as /var/folders/..., the
-- unresolved symlink, so a prefix match on the real location would never hit.
---@param name string Absolute path: a buffer name or a working directory
---@return boolean
local function session_excluded(name)
  local resolved = vim.fn.resolve(name)
  for _, dir in ipairs(session_excluded_dirs) do
    if vim.startswith(resolved, dir .. "/") then
      return true
    end
  end
  return false
end

-- True when this Neovim holds something worth persisting: at least one listed
-- buffer backed by a real file that survives the exclusion above. The starter
-- buffer is `nobuflisted`, so quitting straight from the start screen reports
-- false — without this, that would overwrite the project's good session with an
-- empty one, as would quitting with nothing but excluded buffers open.
---@return boolean
local function session_has_content()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.fn.buflisted(buf) == 1 and name ~= "" and not session_excluded(name) then
      return true
    end
  end
  return false
end

-- :mksession records whichever buffers exist when it runs, so removing them
-- beforehand is the only filter available. Safe only because write() is called
-- from VimLeavePre, where the buffers are about to go anyway.
local function wipe_excluded_bufs()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if session_excluded(vim.api.nvim_buf_get_name(buf)) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

require("mini.sessions").setup({
  -- mini.starter has to win at VimEnter: autoread would restore the session
  -- first and the start screen would never be shown.
  autoread = false,
  -- autowrite only fires when v:this_session is set, which is never true for a
  -- project whose session hasn't been read yet. The autocmd below owns writing
  -- instead, so a project gets a session without ever being saved by hand.
  autowrite = false,
  hooks = {
    pre = {
      write = function()
        require("helpers.windows").close_all_floating_wins()
        wipe_excluded_bufs()
      end,
    },
  },
})

-- Writes the cwd's session, which is what makes sessions appear without being
-- asked for. Guarded so an empty or throwaway Neovim can't clobber a real one.
---@param opts table|nil Options for MiniSessions.write
local function session_write(opts)
  -- session_excluded() on the cwd, not just on buffers: a Neovim launched in an
  -- agent scratchpad is as throwaway as the files in it, and would otherwise
  -- leave a session behind for a directory that is gone tomorrow.
  local cwd = vim.fn.getcwd()
  if session_suppressed(cwd) or session_excluded(cwd) or not session_has_content() then
    return
  end
  require("mini.sessions").write(session_name(), opts)
end

local session_augroup = vim.api.nvim_create_augroup("mini_sessions_autosave", { clear = true })

-- Fires: VimLeavePre, late enough to capture the final layout but while windows
-- still exist for :mksession.
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = session_augroup,
  callback = function()
    session_write()
  end,
})

local session_timer = assert(vim.uv.new_timer())

-- Keeps the session current between quits, so a crash or a terminal closed out
-- from under Neovim doesn't cost the layout. Fires: the events that change what
-- :mksession would record — which file sits in which window, how windows and
-- tabs are arranged — plus FocusLost, to catch the layout you walked away from.
vim.api.nvim_create_autocmd({
  "BufEnter",
  "BufDelete",
  "WinNew",
  "WinClosed",
  "WinResized",
  "TabNew",
  "TabClosed",
  "FocusLost",
}, {
  group = session_augroup,
  callback = function()
    -- Debounced: these arrive in bursts — opening a picker is a WinNew, a
    -- BufEnter and a WinClosed inside a second — and only the layout that
    -- settles is worth writing.
    session_timer:start(
      2000,
      0,
      vim.schedule_wrap(function()
        -- The configured pre-write hook closes floats and wipes buffers, which
        -- is only safe on the way out, so this write runs without it. pcall
        -- because a background :mksession must never interrupt what is being
        -- typed over it.
        pcall(session_write, { hooks = { pre = function() end }, verbose = false })
      end)
    )
  end,
})

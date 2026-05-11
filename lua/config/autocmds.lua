local map = require("helpers.mappings").map

local function augroup(name)
  return vim.api.nvim_create_augroup("__personal_" .. name, { clear = true })
end

-- Disable automatic comment continuation on new lines.
-- By default, Neovim inserts comment leaders when pressing Enter (r),
-- opening a new line with o/O (o), or auto-wrapping text (c). This removes
-- all three so new lines are always plain text.
-- Fires: on every FileType detection (overrides ftplugin defaults).
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o", "c" })
  end,
})

-- Auto-reload buffers that were modified outside Neovim.
-- External tools (git, formatters, build scripts) may change files on disk.
-- Without this, the buffer would silently go stale until a manual :edit.
-- Fires: when Neovim regains focus or a terminal job finishes.
-- Skips nofile buffers (scratch, floating windows) that have no backing file.
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Briefly flash yanked text to give visual feedback on what was copied.
-- Disabled — this is now handled by the tiny-glimmer plugin (plugin/tiny-glimmer.lua).
-- vim.api.nvim_create_autocmd("TextYankPost", {
--   group = augroup("highlight_yank"),
--   callback = function()
--     (vim.hl or vim.highlight).on_yank()
--   end,
-- })

-- Equalize split dimensions after a terminal/window resize.
-- Without this, resizing the terminal leaves splits lopsided. The command
-- iterates every tab with "tabdo wincmd =" to rebalance all of them, then
-- returns to the tab you were on so your focus isn't disrupted.
-- Fires: whenever the outer terminal or GUI window changes size.
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- Restore the cursor to the last edited position when reopening a file.
-- Neovim stores the previous cursor location in the '" mark. This reads that
-- mark and jumps to it, so you pick up where you left off. A per-buffer flag
-- prevents running twice if the same buffer is re-read. gitcommit buffers are
-- excluded because you always want to start at the top of a new commit message.
-- Fires: after a buffer's content is read from disk.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf]._last_loc then
      return
    end
    vim.b[buf]._last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Map "q" to close transient/informational buffers (help, quickfix, etc.).
-- These buffer types are read-only or ephemeral — you rarely need the full
-- :q/:bd workflow to dismiss them. Marking them as unlisted keeps them out of
-- the buffer list, and the "q" keymap closes the window and wipes the buffer.
-- vim.schedule defers the keymap so it doesn't collide with the ftplugin load.
-- Fires: when any of the listed filetypes are detected.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "PlenaryTestPopup",
    "checkhealth",
    "dbout",
    "gitsigns-blame",
    "grug-far",
    "help",
    "lspinfo",
    "neotest-output",
    "neotest-output-panel",
    "neotest-summary",
    "notify",
    "qf",
    "spectre_panel",
    "startuptime",
    "tsplayground",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      map("Quit buffer", "n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
      })
    end)
  end,
})

-- Hide man page buffers from the buffer list.
-- When you open a man page with :Man or K, it creates a regular listed buffer
-- that clutters :ls and buffer-switching pickers. Marking it unlisted keeps it
-- accessible but out of the way.
-- Fires: when a buffer's filetype is set to "man".
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("man_unlisted"),
  pattern = { "man" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})

-- Enable line wrapping and spell checking for prose-oriented filetypes.
-- Code files benefit from nowrap + no spell, but text, markdown, commit
-- messages, and similar filetypes are easier to read and write with soft
-- wrapping and spell suggestions enabled.
-- Fires: when a buffer's filetype matches any of the listed prose types.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Register a labeled <localleader> group with which-key for markdown
-- buffers so the buffer-local <localleader>X mappings configured in
-- plugin/mkdnflow.lua and any future markdown-specific <localleader>
-- mappings surface under a single named group.
-- Fires: when a buffer's filetype is set to markdown.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("markdown_localleader"),
  pattern = { "markdown" },
  callback = function(event)
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<localleader>", group = "markdown", buffer = event.buf, icon = { icon = "󰍔", color = "blue" } },
      })
    end
  end,
})

-- Force conceallevel to 0 for JSON files.
-- Some colorschemes or plugins set conceallevel > 0, which hides quotes and
-- colons in JSON — making the file look broken or hard to edit. This ensures
-- JSON is always displayed verbatim.
-- Fires: when a buffer's filetype is set to json, jsonc, or json5.
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = augroup("json_conceal"),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

-- Automatically create missing intermediate directories when saving a file.
-- This lets you :e a/b/c/new_file.lua and :w without manually running mkdir
-- first. The URL guard (matching "proto://") prevents this from firing on
-- remote/protocol paths like scp:// or oil://.
-- Fires: just before a buffer is written to disk.
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Auto-apply chezmoi templates when editing source files in the chezmoi directory.
-- chezmoi manages dotfiles via a source-of-truth directory (~/.local/share/chezmoi).
-- This hooks into chezmoi.nvim's file watcher so that saving a source file
-- automatically runs "chezmoi apply" for that target, keeping dotfiles in sync
-- without leaving the editor. Requires https://github.com/xvzc/chezmoi.nvim.
-- Fires: when opening or creating a file under the chezmoi source directory.
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { os.getenv("HOME") .. "/.local/share/chezmoi/*" },
  callback = function(ev)
    local bufnr = ev.buf
    local edit_watch = function()
      require("chezmoi.commands.__edit").watch(bufnr)
    end
    vim.schedule(edit_watch)
  end,
})

-- Sets cursorcolumn only in the windows that have focus.
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  callback = function()
    vim.wo.cursorcolumn = true
  end,
})
vim.api.nvim_create_autocmd({ "WinLeave" }, {
  callback = function()
    vim.wo.cursorcolumn = false
  end,
})

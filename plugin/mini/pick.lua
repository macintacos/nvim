---Fuzzy picker driving `:Pick`, and the `vim.ui.select()` implementation.
---@see https://github.com/nvim-mini/mini.pick/blob/main/doc/mini-pick.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.pick", version = "stable" } })

---Re-type `key` into the picker, so a second key runs the action bound to the
---first. mini.pick binds one key per action, so an alias has to be a custom
---action; the picker reads chars through `getcharstr()`, which feedkeys feeds.
---@param key string Key whose action to run, e.g. "<C-n>".
---@return fun()
local function alias(key)
  local keys = vim.keycode(key)
  return function()
    vim.api.nvim_feedkeys(keys, "t", false)
  end
end

---Move the selection half the list window's height, the way <C-d>/<C-u> move
---the cursor in a buffer. Re-typing `move_down` that many times would wrap off
---the last match and carry on from the top, so the jump is computed and set in
---one go -- which also spares the preview a render per row crossed.
---@param sign integer -1 to move up, 1 to move down.
---@return fun()
local function half_page(sign)
  return function()
    local matches = MiniPick.get_picker_matches() or {}
    local inds = matches.all_inds
    if inds == nil or #inds == 0 then
      return
    end
    local pos = 1
    for i, ind in ipairs(inds) do
      if ind == matches.current_ind then
        pos = i
        break
      end
    end
    local height = vim.api.nvim_win_get_height(MiniPick.get_picker_state().windows.main)
    local target = pos + sign * math.max(math.floor(height / 2), 1)
    MiniPick.set_picker_match_inds({ inds[math.min(math.max(target, 1), #inds)] }, "current")
  end
end

-- setup() also takes over vim.ui.select(), which is why snacks sets
-- picker.ui_select = false (see plugin/snacks.lua).
require("mini.pick").setup({
  -- The default float is a fixed 61.8% of the terminal width, which leaves too
  -- little room for paths and matches in a narrow terminal. Below 120 columns
  -- the picker takes the whole width instead (mini.pick clamps for the border).
  window = {
    config = function()
      local columns = vim.o.columns
      return { width = columns < 120 and columns or math.floor(0.618 * columns) }
    end,
  },
  mappings = {
    -- move_down/move_up keep their default <C-n>/<C-p>; the aliases below add
    -- <C-j>/<C-k>/<Tab>/<S-Tab>, which displaces the two toggles onto <M-*>.
    -- <C-d>/<C-u> take the half-page moves. delete_left is dropped rather than
    -- rehomed: <BS> and <C-w> already trim a query, and leaving the built-in on
    -- <C-u> makes mini.pick warn about the duplicate on every picker.
    toggle_preview = "<M-p>",
    toggle_info = "<M-i>",
    delete_left = "",
    move_down_ctrl_j = { char = "<C-j>", func = alias("<C-n>") },
    move_down_tab = { char = "<Tab>", func = alias("<C-n>") },
    move_up_ctrl_k = { char = "<C-k>", func = alias("<C-p>") },
    move_up_shift_tab = { char = "<S-Tab>", func = alias("<C-p>") },
    move_down_half = { char = "<C-d>", func = half_page(1) },
    move_up_half = { char = "<C-u>", func = half_page(-1) },
  },
})

-- mini.pick and mini.input only accept a one-shot paste (`vim.paste` phase -1).
-- macOS splits a terminal paste over ~1KB across pty writes, so Neovim reads it in
-- chunks and streams it (phases 1/2/3), which both modules refuse with a warning.
-- Re-dispatch each chunk as its own one-shot paste -- they append to the prompt in
-- order, so cmd+v works at any clipboard size.
--
-- Deferred because each of those two modules installs its own `vim.paste` wrapper
-- in setup(), and this one only sees a streamed paste if it sits above both.
-- Scheduling puts it on top no matter which order the two files were sourced in.
vim.schedule(function()
  local paste_orig = vim.paste
  vim.paste = function(lines, phase)
    local prompt_active = MiniPick.is_picker_active() or MiniInput.get_state() ~= nil
    if phase == -1 or not prompt_active then
      return paste_orig(lines, phase)
    end
    paste_orig(lines, -1)
    return true
  end
end)

-- Customised registry entries: `:Pick files` with its own preview key, LSP
-- symbol pickers (a document-symbol outline plus thinned workspace scopes),
-- and a blame picker for the line under the cursor. Must run after the setup()
-- above, which is what creates the MiniPick table it writes into.
require("plugins.mini-pickers").setup()

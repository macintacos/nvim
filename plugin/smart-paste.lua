-- github.com/nemanjamalesija/smart-paste.nvim
-- Context-aware paste indentation: auto-indents pasted text to the surrounding level.
vim.pack.add({ "https://github.com/nemanjamalesija/smart-paste.nvim" }, { load = false })

-- Deferred load (like nvim-surround/ts-comments) so remapping the paste keys
-- doesn't run on the startup critical path. Mirrors the plugin's own VeryLazy
-- recommendation.
vim.schedule(function()
  vim.cmd.packadd("smart-paste.nvim")

  -- gp/gP are intentionally omitted from the default key set: peeper-picker owns
  -- gpp/gph and <Nop>s bare gp, so mapping gp/gP here would shadow those and add
  -- a timeoutlen delay before gpp/gph resolve.
  require("smart-paste").setup({ keys = { "p", "P", "]p", "[p" } })

  -- Flash the pasted region blue so it's clear what landed where. smart-paste
  -- owns the paste keys, so we wrap the maps it just created: run its handler,
  -- then schedule a highlight of the '[..'] change marks, which every
  -- smart-paste code path leaves bracketing the inserted text.
  local hl = vim.hl or vim.highlight
  local ns = vim.api.nvim_create_namespace("smart_paste_flash")

  local function flash_paste()
    local buf = vim.api.nvim_get_current_buf()
    local s = vim.api.nvim_buf_get_mark(buf, "[")
    local e = vim.api.nvim_buf_get_mark(buf, "]")
    if s[1] == 0 or e[1] == 0 then
      return
    end
    hl.range(buf, ns, "FlashPaste", { s[1] - 1, s[2] }, { e[1] - 1, e[2] }, { inclusive = true })
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      end
    end, 150)
  end

  -- Wrap smart-paste's own keymap: call its handler, flash, and (for expr maps)
  -- return the keys it produced so behavior is otherwise identical.
  local function wrap(mode, lhs)
    local m = vim.fn.maparg(lhs, mode, false, true)
    if vim.tbl_isempty(m) or not m.callback then
      return
    end
    local orig, is_expr = m.callback, m.expr == 1
    vim.keymap.set(mode, lhs, function()
      local rhs = orig()
      vim.schedule(flash_paste)
      if is_expr then
        return rhs
      end
    end, { expr = is_expr, silent = m.silent == 1, desc = "Smart paste + flash: " .. lhs })
  end

  for _, lhs in ipairs({ "p", "P", "]p", "[p" }) do
    wrap("n", lhs)
  end
  for _, lhs in ipairs({ "p", "P" }) do
    wrap("x", lhs)
  end
end)

-- github.com/ghostty-org/ghostty (bundled vim/ support files — not a vim.pack plugin)
-- Syntax highlighting, filetype detection, and option omnicompletion for Ghostty config files.

-- $GHOSTTY_RESOURCES_DIR points at whichever terminal launched nvim (cmux on this
-- machine, which ships no vim/ support), so fall back to the Ghostty.app bundle.
-- First existing directory wins; if none exist this file is a no-op.
local vimfiles
for _, dir in ipairs({
  (vim.env.GHOSTTY_RESOURCES_DIR or "") .. "/../vim/vimfiles",
  "/Applications/Ghostty.app/Contents/Resources/vim/vimfiles",
}) do
  if vim.fn.isdirectory(dir) == 1 then
    vimfiles = dir
    break
  end
end

if vimfiles then
  -- Put Ghostty's syntax/ftplugin/compiler dirs on the runtimepath; Neovim loads
  -- them automatically once a buffer's filetype becomes "ghostty".
  vim.opt.runtimepath:append(vimfiles)

  -- ftdetect only runs at startup, before this dir joins the runtimepath, so
  -- register Ghostty's detection patterns ourselves (mirrors plugin/pkl-neovim.lua).
  -- These mirror ftdetect/ghostty.vim verbatim.
  vim.filetype.add({
    pattern = {
      [".*/ghostty/config"] = "ghostty",
      [".*%.ghostty/config"] = "ghostty",
      [".*/ghostty/themes/.*"] = "ghostty",
      [".*%.ghostty"] = "ghostty",
    },
  })
end

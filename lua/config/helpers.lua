local M = {}

---Convenience function that wraps the given string with `<Cmd>` and `<CR>`
---@param command string The command to wrap.
M.Cmd = function(command)
  return "<Cmd>" .. command .. "<CR>"
end

return M


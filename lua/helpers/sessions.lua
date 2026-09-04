local M = {}

---Session name for `dir`: the absolute path with `/` replaced by `%`. Gives
---every project its own file under `MiniSessions.config.directory` while keeping
---the project itself clean — mini.sessions' other mode drops a Session.vim in
---each root. Shared so the writer and every reader agree on the scheme.
---@param dir? string Absolute path; defaults to the current working directory.
---@return string
function M.name(dir)
  return ((dir or vim.fn.getcwd()):gsub("/", "%%"))
end

return M

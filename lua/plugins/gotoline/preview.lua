local M = {}

M.NS = vim.api.nvim_create_namespace("gotoline")
local NS = M.NS

---@class gotoline.PreviewResult
---@field ok boolean
---@field target_row integer|nil  -- 1-based row in the buffer

---Render a file preview into `buf` with the target line highlighted.
---@param buf integer
---@param file_path string
---@param line integer 1-based requested line
---@return gotoline.PreviewResult
function M.render(buf, file_path, line)
  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)

  if vim.fn.filereadable(file_path) ~= 1 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
    return { ok = false }
  end

  local lines = vim.fn.readfile(file_path)
  if #lines == 0 then
    lines = { "" }
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local ft = vim.filetype.match({ filename = file_path, buf = buf }) or ""
  if ft ~= "" then
    vim.bo[buf].filetype = ft
  end

  local target = math.max(1, math.min(line, #lines))
  vim.api.nvim_buf_set_extmark(buf, NS, target - 1, 0, {
    line_hl_group = "GotolineTargetLine",
    priority = 200,
  })

  return { ok = true, target_row = target }
end

return M

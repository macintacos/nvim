---@class gotoline.ParsedPrompt
---@field mode "empty"|"filename"|"locked"|"line_only"
---@field file_query string|nil
---@field file string|nil
---@field line integer|nil

local M = {}

---@param s string
---@return string
local function rtrim(s)
  return (s:gsub("%s+$", ""))
end

---Parse `s` as a strict positive base-10 integer (1-based line number).
---@param s string
---@return integer|nil
local function to_line(s)
  local n = s:match("^%d+$") and tonumber(s) or nil
  if n and n >= 1 then
    return n
  end
end

---Parse a prompt into a structured result.
---@param prompt_text string Raw prompt buffer contents.
---@param locked_file string|nil The file path locked by the UI, if any.
---@return gotoline.ParsedPrompt
function M.parse(prompt_text, locked_file)
  local text = rtrim(prompt_text or "")

  if locked_file then
    local rest = text:sub(#locked_file + 1)
    if rest:sub(1, 1) == ":" then
      local digits = rest:sub(2)
      return {
        mode = "locked",
        file = locked_file,
        line = to_line(digits),
      }
    end
  end

  if text == "" then
    return { mode = "empty" }
  end

  local line = to_line(text)
  if line then
    return { mode = "line_only", line = line }
  end

  return { mode = "filename", file_query = text }
end

return M

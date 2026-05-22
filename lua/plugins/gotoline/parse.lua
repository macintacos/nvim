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

---Parse `s` as a base-10 integer (any value — clamping to a valid 1-based line
---happens at jump time, not here, so that `-5` previews/jumps to line 1 and a
---huge number jumps to the file's last line).
---@param s string
---@return integer|nil
local function to_line(s)
  if s:match("^%-?%d+$") then
    return tonumber(s)
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

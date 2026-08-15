local store = require("plugins.ftchooser.store")

local M = {}

---@class ftchooser.Entry
---@field [1] string Human-friendly label shown in the picker
---@field [2] string The filetype value set on the buffer

-- Human-friendly label -> filetype. Add a line to extend the picker.
---@type ftchooser.Entry[]
M.filetypes = {
  { "JSON", "json" },
  { "JSON with Comments (jsonc)", "jsonc" },
  { "JSON5", "json5" },
  { "YAML", "yaml" },
  { "TOML", "toml" },
  { "Lua", "lua" },
  { "Markdown", "markdown" },
  { "Shell (sh / bash)", "sh" },
  { "Python", "python" },
  { "Rust", "rust" },
  { "Go", "go" },
  { "JavaScript", "javascript" },
  { "TypeScript", "typescript" },
  { "HTML", "html" },
  { "CSS", "css" },
  { "SQL", "sql" },
  { "Dockerfile", "dockerfile" },
  { "Git commit", "gitcommit" },
  { "Vim script", "vim" },
  { "Plain Text", "text" },
}

---Normalize a buffer's name to an absolute path used as the store key.
---Empty for unnamed buffers (no stable key -> not remembered).
---@param buf integer
---@return string
local function key_for(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return ""
  end
  return vim.fs.normalize(vim.fn.fnamemodify(name, ":p"))
end

---Set `buf`'s filetype to `ft` and remember it for this file across restarts.
---@param buf integer
---@param ft string
function M.set_filetype(buf, ft)
  vim.bo[buf].filetype = ft
  local key = key_for(buf)
  if key ~= "" then
    store.set(store.path(), key, ft)
  end
end

---Open a picker to choose the current buffer's filetype from friendly names.
function M.open()
  local buf = vim.api.nvim_get_current_buf()
  local current = vim.bo[buf].filetype

  local labels = {}
  local by_label = {}
  for _, entry in ipairs(M.filetypes) do
    labels[#labels + 1] = entry[1]
    by_label[entry[1]] = entry[2]
  end

  vim.ui.select(labels, {
    prompt = "Filetype (current: " .. (current ~= "" and current or "none") .. ")",
    -- Mark the label matching the buffer's current filetype.
    format_item = function(label)
      return (by_label[label] == current and "● " or "  ") .. label
    end,
  }, function(label)
    if label then
      M.set_filetype(buf, by_label[label])
    end
  end)
end

---Register the reapply hook. Runs after builtin ftdetect so a remembered
---filetype wins over automatic detection for that file.
function M.setup()
  vim.api.nvim_create_autocmd("BufReadPost", {
    group = vim.api.nvim_create_augroup("ftchooser", { clear = true }),
    callback = function(ev)
      local key = key_for(ev.buf)
      if key == "" then
        return
      end
      local ft = store.get(store.path(), key)
      if ft and ft ~= vim.bo[ev.buf].filetype then
        vim.bo[ev.buf].filetype = ft
      end
    end,
  })
end

return M

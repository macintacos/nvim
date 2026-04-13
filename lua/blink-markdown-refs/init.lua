---@module 'blink.cmp'
---@class blink.cmp.Source
local source = {}

local search = require("blink-markdown-refs.search")
local util = require("blink-markdown-refs.util")

local hl_ns = vim.api.nvim_create_namespace("blink-markdown-refs")
vim.api.nvim_set_hl(0, "BlinkCmpDocMatchLine", { default = true, bg = "#1a1c30" })
vim.api.nvim_set_hl(0, "BlinkCmpDocMatchChars", { default = true, bold = true, fg = "#ff9e64", bg = "#252840" })

local EMPTY_RESPONSE = { items = {}, is_incomplete_forward = false, is_incomplete_backward = false }

function source.new()
  return setmetatable({}, { __index = source })
end

function source:enabled()
  return vim.bo.filetype == "markdown"
end

function source:get_trigger_characters()
  return { "@" }
end

function source:get_completions(ctx, callback)
  local line_before = ctx.line:sub(1, ctx.cursor[2])
  local at_pos = line_before:match(".*()@")

  if not at_pos then
    callback(EMPTY_RESPONSE)
    return
  end

  local query = line_before:sub(at_pos + 1)

  if query:match("%s") then
    callback(EMPTY_RESPONSE)
    return
  end

  local root = util.get_root(ctx.bufnr)
  local buf_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ctx.bufnr), ":h")

  return search.search(query, root, buf_dir, callback)
end

function source:resolve(item, callback)
  item = vim.deepcopy(item)

  if not item.data or not item.data.path then
    callback(item)
    return
  end

  local path = item.data.path
  local target_line = item.data.line or 1
  local start_line = math.max(1, target_line - 5)
  local end_line = target_line + 15

  local lines = vim.fn.readfile(path, "", end_line)
  if #lines >= start_line then
    local slice = vim.list_slice(lines, start_line, end_line)
    local ext = vim.fn.fnamemodify(path, ":e")
    local is_match_type = item.data.type == "content" or item.data.type == "heading"
    local match_idx = is_match_type and (target_line - start_line + 1) or nil
    local query = item.data.query or ""

    item.documentation = {
      kind = "markdown",
      value = table.concat(slice, "\n"),
      draw = function(opts)
        local bufnr = opts.window:get_buf()

        -- Set buffer content directly — no code fences means no top padding
        vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, slice)
        vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
        vim.api.nvim_set_option_value("modified", false, { buf = bufnr })

        -- Apply treesitter syntax highlighting for the file's language
        local lang = vim.treesitter.language.get_lang(ext) or ext
        local ok, docs = pcall(require, "blink.cmp.lib.window.docs")
        if ok then
          pcall(docs.highlight_with_treesitter, bufnr, lang, 0, #slice)
        end

        -- For content matches, highlight the matched line and characters
        if match_idx and match_idx >= 1 and match_idx <= #slice then
          local buf_line = match_idx - 1
          vim.api.nvim_buf_clear_namespace(bufnr, hl_ns, 0, -1)
          vim.api.nvim_buf_set_extmark(bufnr, hl_ns, buf_line, 0, {
            line_hl_group = "BlinkCmpDocMatchLine",
            priority = 200,
          })

          local col_start = util.smart_find(query, slice[match_idx])
          if col_start then
            vim.api.nvim_buf_set_extmark(bufnr, hl_ns, buf_line, col_start - 1, {
              end_col = col_start - 1 + #query,
              hl_group = "BlinkCmpDocMatchChars",
              priority = 201,
            })
          end
        end
      end,
    }
  end
  callback(item)
end

function source:execute(ctx, item, callback, default_implementation)
  local strip = vim.b[ctx.bufnr].blink_md_refs_strip_at
  if strip then
    vim.b[ctx.bufnr].blink_md_refs_strip_at = nil

    -- Find the @ position and replace from there (removing the @)
    local line_before = ctx.line:sub(1, ctx.cursor[2])
    local at_pos = line_before:match(".*()@")
    if at_pos and item.data and item.data.raw_path then
      local row = ctx.cursor[1]
      vim.api.nvim_buf_set_text(ctx.bufnr, row - 1, at_pos - 1, row - 1, ctx.cursor[2], { item.data.raw_path })
      callback()
      return
    end
  end

  default_implementation()
  callback()
end

return source

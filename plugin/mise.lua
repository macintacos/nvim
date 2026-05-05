-- github.com/jmbuhr/otter.nvim
-- Mise integration: tree-sitter injection predicates plus otter.nvim activation
-- on mise toml files. See https://mise.jdx.dev/mise-cookbook/neovim.html

-- Gates after/queries/toml/injections.scm: only inject `run = "..."` bodies in
-- files whose name matches *mise*.toml (e.g. mise.toml, .mise.toml, mise.local.toml).
require("vim.treesitter.query").add_predicate("is-mise?", function(_, _, bufnr, _)
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(tonumber(bufnr) or 0), ":t")
  return string.match(filename, ".*mise.*%.toml$") ~= nil
end, { force = true, all = false })

-- Gates after/queries/bash/injections.scm: only inject TOML/KDL into #MISE / #USAGE
-- comments in bash files that live in a mise tasks directory.
require("vim.treesitter.query").add_predicate("is-mise-task?", function(_, _, bufnr, _)
  local path = vim.api.nvim_buf_get_name(tonumber(bufnr) or 0)
  return path:match("[/\\]%.?mise%-tasks?[/\\]") ~= nil or path:match("[/\\]%.?mise[/\\]tasks?[/\\]") ~= nil
end, { force = true, all = false })

vim.pack.add({ "https://github.com/jmbuhr/otter.nvim" })
require("otter").setup()

-- Activate otter on TOML buffers, but only when the filename looks like a mise file —
-- otherwise plain pyproject.toml / Cargo.toml etc. would also spin up otter.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "toml",
  group = vim.api.nvim_create_augroup("__personal_mise_otter", { clear = true }),
  callback = function(args)
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":t")
    if filename:match(".*mise.*%.toml$") then
      require("otter").activate()
    end
  end,
})

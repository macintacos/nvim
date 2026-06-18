-- Local plugin (no upstream repo)
-- :PackPR — pick an open PR across managed repos and point its vim.pack spec at
-- the PR's branch (or reset to default) so it can be smoke-tested live.
require("plugins.pack-pr").setup({
  repos = {
    "macintacos/agentcomplete.nvim",
    -- Onboard a repo with a one-line "owner/repo" entry, or a table to override
    -- a derived field, e.g. { repo = "owner/x.nvim", spec_file = "plugin/custom.lua" }.
  },
})

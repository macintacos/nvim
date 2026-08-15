-- Local plugin (no upstream repo)
-- Gives uv single-file scripts (PEP 723) working Python tooling: filetype
-- detection for the extensionless ones, and a ty client pointed at the
-- per-script environment uv builds for them.
require("plugins.uv-scripts").setup({})

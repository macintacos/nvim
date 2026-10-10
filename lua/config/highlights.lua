-- Custom highlight groups, from the shared palette's roles.

-- Flash colors for yank/paste feedback. Copy flashes green (FlashYank, used by
-- the TextYankPost autocmd in lua/config/autocmds.lua) and paste flashes purple
-- (FlashPaste, used by the paste wrapper in plugin/smart-paste.lua), so it's
-- clear both where the region is and which operation just happened.
---@param p palette.Roles
local function set_flash_hl(p)
  vim.api.nvim_set_hl(0, "FlashYank", { bg = p.green.base, fg = p.bg1 })
  vim.api.nvim_set_hl(0, "FlashPaste", { bg = p.purple.base, fg = p.bg1 })
end

-- Query matches in mini.pick: solid blocks in the list and the preview.
--
-- The list marks matches at extmark priority 200 and the current row at 201,
-- so the row's colours win over the match's on that row. `reverse` is a flag,
-- and flags survive the override: a match draws as a cyan block on other rows
-- and as a block of the current row's foreground on the current one. Cyan, like
-- the match characters of every other picker.
---@param p palette.Roles
local function set_picker_match_hl(p)
  vim.api.nvim_set_hl(0, "MiniPickMatchRanges", { fg = p.cyan.base, bg = p.bg1, reverse = true, bold = true })
  vim.api.nvim_set_hl(0, "MiniPickPreviewRegion", { fg = p.bg1, bg = p.cyan.base, bold = true })
end

-- Without a palette file the feedback groups borrow the scheme's, so yanks, pastes
-- and hovered links still show; the palette's colours replace them.
local function set_feedback_fallback_hl()
  for group, scheme_group in pairs({
    FlashYank = "IncSearch",
    FlashPaste = "Visual",
    LinkHover = "Visual",
    LinkHoverIcon = "Visual",
  }) do
    vim.api.nvim_set_hl(0, group, { link = scheme_group, default = true })
  end
end

-- Ctrl-hover over a link or path (helpers.links). sel0, the selection colour:
-- syntax colours stay legible on it, where bg4 drops accents below 4.5. The underline matches herdr's own ctrl-hover one,
-- which blinks as Neovim redraws; this keeps it steady underneath.
---@param p palette.Roles
local function set_link_hover_hl(p)
  vim.api.nvim_set_hl(0, "LinkHover", { bg = p.sel0, underline = true })
  vim.api.nvim_set_hl(0, "LinkHoverIcon", { fg = p.cyan.base, bg = p.sel0 })
end

-- changeset.nvim's unified diff: an added or deleted line's background, and the
-- stronger one behind the characters it changed. Overrides changeset's defaults,
-- which it derives from the theme.
---@param p palette.Roles
local function set_changeset_diff_hl(p)
  vim.api.nvim_set_hl(0, "ChangesetDiffAdd", { bg = p.diff.add })
  vim.api.nvim_set_hl(0, "ChangesetDiffAddText", { bg = p.diff.add_text })
  vim.api.nvim_set_hl(0, "ChangesetDiffDelete", { bg = p.diff.delete })
  vim.api.nvim_set_hl(0, "ChangesetDiffDeleteText", { bg = p.diff.delete_text })
end

-- Neovim's own groups, where Dracula Pro leaves Neovim's default colours in place
-- or the palette's role table names a different role than Pro does.
---@param p palette.Roles
---@return table<string, vim.api.keyset.highlight>
local function ui_groups(p)
  return {
    DiagnosticOk = { fg = p.green.base },
    DiagnosticUnderlineOk = { sp = p.green.base, underline = true },
    DiagnosticDeprecated = { sp = p.red.base, strikethrough = true },
    OkMsg = { fg = p.green.base },
    ModeMsg = { fg = p.green.base },
    CurSearch = { link = "IncSearch" },
    QuickFixLine = { bg = p.sel0 },
    WinBar = { fg = p.fg2, bg = p.bg0, bold = true },
    WinBarNC = { fg = p.fg3, bg = p.bg0 },
    FloatShadow = { bg = p.bg4, blend = 80 },
    FloatShadowThrough = { bg = p.bg4, blend = 100 },
    NvimInternalError = { fg = p.red.base, bg = p.red.base },
    LineNr = { fg = p.fg3 },
    -- Pro links it, and modes.nvim's `:hi CursorLineNr guibg=` drops a link.
    CursorLineNr = { fg = p.yellow.base },
    SignColumn = { fg = p.fg3 },
    FoldColumn = { fg = p.fg3 },
    NonText = { fg = p.bg4 },
    WinSeparator = { fg = p.bg4 },
    FloatBorder = { fg = p.bg4, bg = p.bg0 },
    ColorColumn = { bg = p.bg2 },
    Folded = { fg = p.comment, bg = p.bg2 },
    TabLine = { fg = p.comment, bg = p.bg2 },
    TabLineFill = { bg = p.bg2 },
    PmenuThumb = { bg = p.bg4 },
    StatusLine = { bg = p.bg0, bold = true },
    StatusLineTerm = { bg = p.bg0, bold = true },
    Search = { bg = p.sel1 },
    -- Pro gives matches the dark menu's background, which Alucard's raised menu isn't.
    PmenuMatch = { fg = p.cyan.base, bg = p.bg0 },
    DiffAdd = { bg = p.diff.add },
    DiffChange = { bg = p.diff.change },
    DiffDelete = { bg = p.diff.delete },
    DiffText = { bg = p.diff.text },
    Added = { fg = p.green.base },
    Changed = { fg = p.orange.base },
    Removed = { fg = p.red.base },
  }
end

-- Markdown in Dracula's own colours, which Pro's markdown syntax groups follow and
-- its treesitter groups don't.
---@param p palette.Roles
---@return table<string, vim.api.keyset.highlight>
local function markdown_groups(p)
  return {
    ["@markup.heading"] = { fg = p.purple.base, bold = true },
    ["@markup.strong"] = { fg = p.orange.base, bold = true },
    ["@markup.italic"] = { fg = p.yellow.base, italic = true },
    ["@markup.raw"] = { fg = p.green.base },
    ["@markup.link.label"] = { fg = p.pink.base },
    ["@markup.link.url"] = { fg = p.cyan.base, underline = true },
    ["@markup.list"] = { fg = p.cyan.base },
    ["@markup.quote"] = { fg = p.yellow.base, italic = true },
    RenderMarkdownBullet = { link = "@markup.list" },
    RenderMarkdownDash = { fg = p.comment },
  }
end

-- Syntax where Pro's scheme strays from the palette's role table, which every other
-- tool follows. Pro routes regexes through the escape groups, which stay pink.
---@param p palette.Roles
---@return table<string, vim.api.keyset.highlight>
local function syntax_groups(p)
  return {
    Character = { fg = p.yellow.base },
    ["@string.regexp"] = { fg = p.red.base },
    ["@string.regex"] = { link = "@string.regexp" },
    ["@exception"] = { fg = p.pink.base },
    ["@attribute.builtin"] = { link = "@attribute" },
    ["@lsp.type.namespace"] = { fg = p.pink.base },
    ["@lsp.type.typeParameter"] = { fg = p.cyan.base, italic = true },
    ["@attribute.diff"] = { fg = p.cyan.base, italic = true },
    -- The ---/+++ lines, from after/queries/diff/highlights.scm.
    ["@diff.file"] = { fg = p.fg0, bold = true },
    ["@string.special.url"] = { link = "@markup.link.url" },
    -- Pro's own link misspells it.
    ["@function.macro"] = { fg = p.green.base },
    ["@lsp.type.macro"] = { link = "@function.macro" },
    -- Keys in data files, apart from code's fields. JSON5 captures them as keywords,
    -- and TOML's quoted ones come from after/queries/toml/highlights.scm.
    ["@property.json"] = { fg = p.cyan.base },
    ["@keyword.json5"] = { fg = p.cyan.base },
    ["@property.yaml"] = { fg = p.cyan.base },
    ["@property.toml"] = { fg = p.cyan.base },
    ["@property.git_config"] = { fg = p.cyan.base },
    ["@property.kdl"] = { fg = p.cyan.base },
  }
end

-- Plugins Pro doesn't cover, or covers through groups this file recolours.
---@param p palette.Roles
---@return table<string, vim.api.keyset.highlight>
local function plugin_groups(p)
  return {
    -- Pro links the signs to the diff groups, which carry line backgrounds here.
    GitSignsAdd = { fg = p.green.base },
    GitSignsAddNr = { fg = p.green.base },
    GitSignsAddLn = { bg = p.diff.add },
    GitSignsChange = { fg = p.orange.base },
    GitSignsChangeNr = { fg = p.orange.base },
    GitSignsChangeLn = { bg = p.diff.change },
    GitSignsDeleteLn = { bg = p.diff.delete },
    -- blink.cmp leaves matches unmarked unless it mimics nvim-cmp, and its borders
    -- in the menu's text colour.
    BlinkCmpLabelMatch = { fg = p.cyan.base },
    BlinkCmpMenuBorder = { link = "FloatBorder" },
    BlinkCmpDocBorder = { link = "FloatBorder" },
    BlinkCmpSignatureHelpBorder = { link = "FloatBorder" },
    MiniPickMatchCurrent = { bg = p.sel0 },
    MiniPickPromptPrefix = { fg = p.green.base },
    MiniPickHeader = { fg = p.comment },
    MiniIndentscopeSymbol = { fg = p.purple.base },
    -- Pro pills visual mode in yellow; here it's pink, like modes.nvim's visual cursor.
    MiniStatuslineModeVisual = { fg = p.bg1, bg = p.pink.base },
    GotolineSelected = { bg = p.sel0 },
    GotolineMatch = { fg = p.cyan.base },
    SnacksPickerMatch = { fg = p.cyan.base },
    SnacksPickerPrompt = { fg = p.green.base },
    SnacksPickerSelected = { fg = p.pink.base },
    SnacksPickerTotals = { fg = p.purple.base },
    SnacksPickerDir = { fg = p.comment },
    SnacksPickerPathHidden = { fg = p.comment },
    SnacksPickerPathIgnored = { fg = p.comment },
    SnacksPickerGitStatusStaged = { fg = p.green.base },
    SnacksPickerGitStatusRenamed = { fg = p.purple.base },
    SnacksPickerGitStatusUnmerged = { fg = p.pink.base },
    SnacksPickerGitStatusIgnored = { fg = p.comment },
    SnacksPickerGitStatusUntracked = { fg = p.comment },
    SnacksImageMath = { link = "@markup.math" },
    WhichKeyIcon = { fg = p.cyan.base },
    WhichKeyIconAzure = { fg = p.cyan.base },
    WhichKeyIconYellow = { fg = p.yellow.base },
    FlashLabel = { fg = p.bg1, bg = p.pink.base, bold = true },
    BlinkPairsOrange = { fg = p.orange.base },
    BlinkPairsPurple = { fg = p.purple.base },
    BlinkPairsBlue = { fg = p.cyan.base },
    BlinkPairsUnmatched = { fg = p.red.base },
    MasonHeader = { fg = p.bg1, bg = p.green.base, bold = true },
    MasonHeaderSecondary = { fg = p.bg1, bg = p.cyan.base, bold = true },
    MasonHighlight = { fg = p.cyan.base },
    MasonHighlightBlock = { fg = p.bg1, bg = p.cyan.base },
    MasonHighlightBlockBold = { fg = p.bg1, bg = p.cyan.base, bold = true },
    MasonHighlightSecondary = { fg = p.orange.base },
    MasonHighlightBlockSecondary = { fg = p.bg1, bg = p.orange.base },
    MasonHighlightBlockBoldSecondary = { fg = p.bg1, bg = p.orange.base, bold = true },
    MasonMuted = { fg = p.comment },
    MasonMutedBlock = { fg = p.bg1, bg = p.comment },
    MasonMutedBlockBold = { fg = p.bg1, bg = p.comment, bold = true },
  }
end

---@param groups table<string, vim.api.keyset.highlight>
local function set_groups(groups)
  for name, attrs in pairs(groups) do
    vim.api.nvim_set_hl(0, name, attrs)
  end
end

-- Re-apply on ColorScheme because setting a colorscheme clears custom groups.
-- Fires when the scheme loads at startup (plugin/dracula-pro.lua) and on every
-- 'background' flip, which reloads it. Without a palette file the scheme's own
-- groups stand.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "dracula-pro",
  callback = function()
    set_feedback_fallback_hl()
    local p = require("helpers.palette").active()
    if not p then
      return
    end
    set_groups(ui_groups(p))
    set_groups(markdown_groups(p))
    set_groups(syntax_groups(p))
    set_groups(plugin_groups(p))
    set_flash_hl(p)
    set_picker_match_hl(p)
    set_link_hover_hl(p)
    set_changeset_diff_hl(p)
  end,
})

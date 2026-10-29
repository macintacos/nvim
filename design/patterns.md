# Patterns

These are the ways the config already shows things. Before you add a UI element, reuse the pattern that matches it rather than inventing a new one.

## Chrome

The statusline is global and sits on `bg0` (`plugin/mini/statusline.lua`). Only its mode sections and the green plugin-update count carry color.

The tabline shows tab pages, not buffers, as rounded pills sized to their names (`plugin/tabby.lua`). The current tab is tinted cyan and shows its number in purple. vim.pack's update review tab is green, and the tab of a scratch file (`lua/plugins/scratch/`) is yellow.

Each window's filename floats bottom-right in an incline label (`plugin/incline.lua`): the file's icon on its own color, then the name in bold. The statuscolumn draws the fold, sign, and number columns and ends in a `▏` separator (`plugin/mini/statuscolumn.lua`).

## Floats

Every float takes a rounded border (`'winborder'` in `lua/config/options.lua`). Borders are `bg4`. The float itself is `bg0` in dark mode and `bg1` in light mode, so it never sits brighter than the editor.

A picker's keys show as a keybar on the right of the side preview's bottom border, such as `⌥x exclude  ⌥o only` for the live grep. Keys take the border text's color and labels the dimmer `MiniPickKeybarLabel`. State that differs from the defaults goes in the list's footer rather than in a row of its own, so the keybar and the state cost no rows.

## Mode colors

Each mode has one color. The statusline's mode section shows it, and `plugin/modes.lua` paints it on the cursor, the cursor line's tint, and the line number. The cursor's smear trail (`plugin/smear-cursor.lua`) follows the cursor's color.

| Mode | Color | Shows on |
| --- | --- | --- |
| Normal | purple | statusline |
| Insert | green | statusline, cursor line |
| Visual, select | pink | statusline, cursor |
| Replace | orange | statusline, cursor line |
| Command | cyan | statusline |
| Copy (`y`) | yellow | cursor line |
| Delete (`d`), change (`c`) | red | cursor line |
| Format (`=`, `!`, `>`, `<`, and `g` operators such as `gq`) | orange | cursor line |

Copy, delete, change, and format aren't Neovim modes. They are operators waiting for a motion, which modes.nvim colors as if they were modes.

The cursor line takes the mode's color at 14% over `bg1`. Visual and select leave the line to the selection band. In normal mode the cursor line is the plain `bg3` band with a yellow line number.

## What each hue means

Outside the mode colors above, use a hue only for the meanings below, and add a row here before you give one a new meaning. Syntax colors in code follow Dracula Pro's own assignments.

| Hue | Meaning in the UI |
| --- | --- |
| cyan | Matched characters in every picker and in completion, keys in data files, links and URLs |
| green | Prompt prefixes, success, added lines, the plugin-update count |
| pink | Jump labels |
| purple | The current tab's number, the current branch's icon in the branch picker, the indent scope line, the paste flash |
| red | Errors, removed lines, and unmatched brackets |
| orange | Changed lines |
| yellow | The cursor line number in normal mode, and scratch files |

## Signals besides color

Style carries meaning that color alone doesn't:

- Italic marks a modified buffer or a tab with unsaved changes.
- Bold marks the current item, such as the current tab or the filename in its label.
- A Nerd Font glyph sits beside a label rather than replacing it.
- Git signs differ by shape: `┃` marks an added line, `╏` a changed one, and `_` a deleted one (`plugin/gitsigns.lua`).

## Feedback and motion

A yank flashes the yanked region green, and a paste flashes the pasted region purple, so you see both where the text is and which operation ran (`lua/config/highlights.lua`).

The only motion is the cursor's smear trail, tuned short so it settles fast. `vim.g.snacks_animate = false` in `plugin/snacks.lua` turns off every snacks animation, scrolling included.

Background work shows a braille spinner while it runs, then states its result. The plugin-update check shows the spinner in the statusline, then the count of plugins with updates (`lua/plugins/pack-updates/`).

## Folds

A closed fold draws as a braille bar that carries the fold's summary and its size, joined by ` · `, such as `1 line · 7.7%` (`lua/config/folds.lua`). The bar matches mkdnflow's folds, so a folded function and a folded Markdown heading look alike. Its text is the comment color blended 35% toward purple, so a fold doesn't read as a comment.

## Messages

A local plugin's message starts with the plugin's name and a colon, then says what went wrong or what to do next, as in `worktrunk: save or discard your unsaved changes first`. Give an error the fix when one exists.

Notifications stack in the bottom-right corner, three rows higher than mini.notify's default so they clear the incline label (`plugin/mini/notify.lua`).

## Refused

No view carries an eyebrow, a small label set above a heading. Let the heading stand alone.

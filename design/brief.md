# Brief

This is a personal Neovim 0.12 config with one user, its owner. Its job is to make editing code fast while the UI stays quiet, so the code holds the attention.

## Mode

The editor is in the taste skill's Operate mode, the mode for a tool someone works in all day. Scanning, consistency, and Neovim's own conventions come before visual expression. The config's character shows only in its accents and icons.

## Where it runs

It runs in Ghostty inside herdr, set in Berkeley Mono at 16pt, with Nerd Font glyphs available.

The color scheme follows the terminal's appearance, even in a running editor: Dracula Pro's Van Helsing when the terminal is dark, Alucard when it is light. Design every change for both.

## What it covers

The direction covers the editor's chrome (statusline, tabline, statuscolumn, winbar, and filename labels), its floats (pickers, notifications, input, completion, and which-key), its highlight bands and syntax colors, and the messages the local plugins send through `vim.notify`. A highlight band is a tinted background behind text, such as the cursor line, the selection, or a diff line.

It doesn't cover script output, because the mise tasks print only their tools' own output. The editor makes no sound.

## Floors

These hold for every change, in both themes:

- Text holds 4.5:1 contrast against the editor background and floats.
- Text on a highlight band holds 3:1 against that band. Fix a failing text color, never the band.
- Color is never the only signal: pair it with a glyph, weight, or style.

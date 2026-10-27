# Decisions

Each entry records one design decision: what was decided, why, and what it ruled out. Add new entries at the top.

## 2026-10-27: Light-mode strings use `#007d77`

Strings in light mode take a teal tuned to 4.59:1 on `bg1`. They already used a teal override, `#108881`, in place of Alucard's orchid yellow, but it measured 3.97:1, under the 4.5:1 text floor. This decision only darkens it.

The teal keeps the strings' existing hue, darkened in OKLCH to the contrast the other Alucard accents hold, about 4.58:1. The gold `#715c0a` was the alternative. It held higher contrast and would have returned strings to Dracula Pro's yellow role, but it changed how every light-mode file looks.

## 2026-10-27: Light-mode overrides stay in highlights.lua

The three light-mode overrides stay in `lua/config/highlights.lua`, recorded in `exceptions.md`. Moving them into the dotfiles' `palette.toml` would have let other tools use them, but it would also stop the shared palette from being a copy of Alucard.

## 2026-10-27: design/ records the config as it stood

The direction started from what the config already did, so `design/` records those choices rather than redesigning them. The only change at setup was the light-mode string color.

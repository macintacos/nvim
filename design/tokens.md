# Tokens

Every color comes from the shared palette. Don't copy a palette value into a highlight group or into `design/`. The only hard-coded colors are the overrides `exceptions.md` lists, and the hex values in `exceptions.md` and `decisions.md` are those overrides, not palette values.

## Source of truth

The dotfiles define the palette in `managed/.chezmoidata/palette.toml` and deploy it to `~/.config/palette/palette.json`. `lua/helpers/palette.lua` reads that file and returns the variant that matches `'background'`. Change a palette value in the dotfiles, never in this repo.

## How the scheme uses it

Dracula Pro draws most groups, fed the palette's colors through `helpers.palette.dracula_pro`. `lua/config/highlights.lua` then recolors two kinds of group: those Pro leaves at Neovim's defaults, and those where Pro's role differs from the palette's. It reapplies them on every `ColorScheme` event, so they survive each switch between dark and light.

## Roles

Pick a color by its role. The field annotations on `palette.Roles` in `lua/helpers/palette.lua` define each one:

| Role | Use it for |
| --- | --- |
| `bg0` | Dark mode: floats, popups, and the status and title bars. Light mode: white, so floats use `bg1` instead. |
| `bg1` | The editor background. |
| `bg2` | The color column, closed folds, and inactive tabs. |
| `bg3` | The cursor line. |
| `bg4` | Borders, dividers, and non-text characters. |
| `fg1` | Body text. |
| `fg2` | The winbar and the current tab's name. |
| `fg3` | Line numbers and other gutter text. |
| `comment` | Comments and secondary text, such as picker headers and inactive tab names. |
| `sel0` | The selection band, and any band that must keep syntax colors legible on it. |
| `sel1` | The search-match band. |
| `diff.*` | Diff line bands (`add`, `delete`, `change`) and the stronger bands behind changed characters (`text`, `add_text`, `delete_text`). |
| `red` … `pink` | Accents, each with `base`, `bright`, and `dim`. Use `base` unless a group needs the variant. `patterns.md` says what each hue means. |

## Derived tints

When the palette has no key for a tint, mix one with `helpers.palette.blend(a, b, f)`, which mixes fraction `f` of color `b` into color `a`. The mode-colored cursor lines and the current tab's background are tints of this kind.

## Without a palette file

Without a palette file, the scheme loads Pro's own Van Helsing or Alucard and the recolors in `highlights.lua` don't apply. The yank, paste, and link-hover groups fall back to scheme groups so that feedback still shows.

# Exceptions

These are the places the config departs on purpose from two color rules. The first is that every color comes from the palette (`tokens.md`). The second is the taste skill's rule that a tint the palette lacks is mixed in OKLCH, a color space where equal numeric steps look equally different. Each entry gives its reason, so a change doesn't undo it by accident.

## Light-mode overrides

Three light-mode colors are hard-coded in `lua/config/highlights.lua` instead of coming from the palette:

| Color | Used for | Why |
| --- | --- | --- |
| `#007d77` | Strings | Alucard's yellow role, which Dracula Pro gives strings, is an orchid that sits too close in hue to its pink keywords and purple constants. This teal sits between green and cyan, darkened to 4.59:1 on `bg1`. |
| `#715c0a` | The yellow role outside syntax, such as scratch tabs | The orchid doesn't read as yellow. This gold does and holds 5.96:1 on `bg1`. |
| `#ebe8e2` | The cursor line | Alucard's `bg3` is too strong a band against `bg1`, so this is `bg3` lifted toward `bg1`. |

They stay in this repo so the shared palette remains a copy of Alucard for every other tool that reads it.

## Derived tints don't use OKLCH

`helpers.palette.blend` mixes the red, green, and blue values as the hex code stores them, not in OKLCH. Switching would change every derived tint: the mode-colored cursor lines and the current tab's background. The question is open. A `/taste mockup`, which renders the two options side by side, would settle it.

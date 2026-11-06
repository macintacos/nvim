# Design

This directory holds the design direction for the editor's UI. Every change to the config's colors, chrome, floats, or messages follows it.

## Routing

Walk the `router` fence from `@changing-the`: take every exit whose label matches your change, and load each file those exits lead to.

```router
@changing-the: Changing the UI
  > what-does
what-does: What does the change touch?
  who the UI is for, the mode it works in, what it covers, the contrast floors > brief
  a color: where it comes from, which role to use > tokens
  a highlight group, the statusline or tabline, a float, a mode color, feedback, a notify message > patterns
  a hard-coded color, or a derived tint > exceptions
  reopening a settled question, or settling a new one > decisions
brief!: Load design/brief.md
tokens!: Load design/tokens.md
patterns!: Load design/patterns.md
exceptions!: Load design/exceptions.md
decisions!: Load design/decisions.md
```

## Keeping design/ current

When a change adds a pattern or departs from one, update the matching file in the same change. A pattern goes in `patterns.md`, and a deliberate departure from the palette rules goes in `exceptions.md` with its reason.

When you settle a direction question, add a dated entry to `decisions.md`. When you add a file to `design/`, give it an exit and a stop in `## Routing`.

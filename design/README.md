# Design

This directory holds the design direction for the editor's UI. Every change to the config's colors, chrome, floats, or messages follows it.

## Routing

Read this digraph as a checklist: load every file whose edge matches your change.

```graphviz
digraph design_router {
    node [shape=box];

    "Changing the UI" [shape=doublecircle];
    "What does the change touch?" [shape=diamond];

    "Changing the UI" -> "What does the change touch?";
    "What does the change touch?" -> "Load design/brief.md" [label="who the UI is for, the mode it works in, what it covers, the contrast floors"];
    "What does the change touch?" -> "Load design/tokens.md" [label="a color: where it comes from, which role to use"];
    "What does the change touch?" -> "Load design/patterns.md" [label="a highlight group, the statusline or tabline, a float, a mode color, feedback, a notify message"];
    "What does the change touch?" -> "Load design/exceptions.md" [label="a hard-coded color, or a derived tint"];
    "What does the change touch?" -> "Load design/decisions.md" [label="reopening a settled question, or settling a new one"];
}
```

## Keeping design/ current

When a change adds a pattern or departs from one, update the matching file in the same change. A pattern goes in `patterns.md`, and a deliberate departure from the palette rules goes in `exceptions.md` with its reason.

When you settle a direction question, add a dated entry to `decisions.md`. When you add a file to `design/`, give it an edge in `## Routing`.

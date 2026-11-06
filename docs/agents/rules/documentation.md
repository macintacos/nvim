# Documentation rules

Walk the `router` fence from `@changing-documentation`: take every exit whose label matches your change, and edit each doc those exits lead to.

```router
@changing-documentation: Changing documentation
  > which-doc
which-doc: Which doc does the change affect?
  the config's shape, the local plugins table > readme
  the index of local plugins > readme-2
  one local plugin's behavior, keymaps, and commands > readme-3
  orientation, rules for every change, routing to rule files > agents
  plugin/ conventions: headers, specs, load tiers, builds > plugins
  local plugin layout, wiring, and documentation > local-plugins
  spec layout, running, isolation, fixtures > testing
  mise, hk, the type check, selene > tooling
  adding, removing, or renaming a doc > documentation
  the UI's design direction: who it's for, color roles, patterns, exceptions, decisions > edit-design
readme!: Edit README.md
readme-2!: Edit lua/plugins/README.md
readme-3!: Edit lua/plugins/*/README.md
agents!: Edit AGENTS.md
plugins!: Edit docs/agents/rules/plugins.md
local-plugins!: Edit docs/agents/rules/local-plugins.md
testing!: Edit docs/agents/rules/testing.md
tooling!: Edit docs/agents/rules/tooling.md
documentation!: Edit docs/agents/rules/documentation.md
edit-design!: Edit design/*.md
```

## The doc landscape

- **`README.md`** introduces the config to a person curious about the setup: the preview recording, how plugins load, what mini.nvim and snacks.nvim each own, and the local plugins table. Keep it minimal, let the recording stand without a walkthrough, and leave Dracula Pro unnamed. Write in the first person, as the repo's owner, and hard-wrap prose at about 90 columns like the rest of the file. It changes when a local plugin is added, renamed, or removed (with `lua/plugins/README.md`), and when a job moves between mini and snacks (with `AGENTS.md`).
- **`lua/plugins/README.md`** indexes the local plugins for a person browsing `lua/plugins/`: one alphabetical bullet per plugin, linking its directory and giving its purpose in a sentence. Keep its plugins the same as the rows of `README.md`'s table, which changes with it.
- **`lua/plugins/*/README.md`** documents one local plugin for a person using it: what it does, its keymaps and commands, and the design choices behind it. Edit the section the change affects and keep the file's existing headings. It changes with that plugin's behavior, keymaps, or commands.
- **`AGENTS.md`** is the file every agent loads first: what the repo is, where answers live, the rules every change needs, and the routing router. Keep it to rules that apply to every change, plus the rules of any area that has no rule file yet. It changes when a rule file is added, renamed, or removed, which updates its `## Routing` router.
- **`docs/agents/rules/*.md`** each hold one area's rules, which agents load through `AGENTS.md`'s routing when a change touches that area. State each rule as an instruction, and point to a file in the repo that follows it. A rule file changes when its area's conventions change.
- **`design/`** holds the design direction for the editor's UI. Agents load it through `AGENTS.md`'s routing before a UI change, and the user-level `/taste` skill reads it from the repo root as the repo's standing brief, so it stays there rather than moving into `docs/`. `design/README.md` routes to its files and says which one each kind of change updates. It changes when a change adds a UI pattern, departs from one, or settles a design question.
- **`docs/agents/rules/documentation.md`**, this file, maps every doc to what it covers. Each doc gets one stop in the router and one bullet here.

## Adding a doc

A new doc goes beside what it describes:

- A new local plugin's `README.md` goes in its directory, `lua/plugins/<name>/`.
- A new design file goes in `design/`, with an exit and a stop in `design/README.md`'s `## Routing`. This file's `design/*.md` stop already covers it.
- A rule for an area starts in `AGENTS.md`. Once the area has rules that changes elsewhere do not need, they move to `docs/agents/rules/<area>.md`, with an exit and a stop in `AGENTS.md`'s `## Routing`.

Adding, removing, or renaming a doc updates this file's router and landscape in the same change.

# mise-tasks

`<leader>pt` opens a centered picker over the tasks [mise](https://mise.jdx.dev) defines
for the current directory. Choosing a task runs it in a floating Rex pane, in Neovim's
working directory.

## Usage

Type to filter the tasks by name. Each row shows a task's name and, dimmed beside it, its
description. Tasks marked `hide` are left out.

A second float under the list shows `mise tasks info` for the highlighted task: its
description, source file, dependencies, and the script it runs. Its bottom border lists
the keys.

| Key | Does |
| --- | --- |
| `<CR>` | Runs `mise run <task>`. |
| `<S-CR>` | Closes the picker and asks for arguments in a prompt centered where the picker was, then runs `mise run <task> <arguments>`. |

`sh` reads the arguments, so they quote as they would at a shell prompt: `--name "a b"`
reaches the task as two arguments, `--name` and `a b`.

## The Rex pane

The task runs in a new floating pane that covers the middle 80% of the Rex window and
takes focus. The pane's label is the command it runs, such as `mise run test`.

When the task exits, the pane keeps its output on screen and says how it ended: `Done`,
or `Exited <status>` for a failure. Press Enter to close the pane, and focus goes back to
Neovim. Ctrl-C stops the task and leaves the pane open on `Exited 130`; Ctrl-C at the
prompt closes it.

## Limitations

- The picker works only inside Rex. Elsewhere, `<leader>pt` warns and does nothing.
- If the current directory has no tasks, `<leader>pt` says so instead of opening an empty
  picker.
- Each run opens a new pane. The picker doesn't reuse or track panes from earlier runs.

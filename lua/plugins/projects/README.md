# projects

A `<leader>pp` project picker backed by [zoxide](https://github.com/ajeetdsouza/zoxide).
Selecting a directory relaunches Neovim there — as if you had quit, `cd`'d into it,
and run `nvim` — so you land on that project's start screen and your shell ends up
there too.

## Usage

- `<leader>pp` — open the picker (Snacks). Filter by typing, `<CR>` to switch,
  `q`/`<Esc>` to dismiss. `●` marks the current working directory.

Entries come from `zoxide query --list` (most-frecent first).

## How the "switch" works

Neovim cannot change its parent shell's directory. So switching is a **relaunch**:

1. Picking a directory stashes it in `vim.g.projects_switch_target` and runs
   `:confirm qall`.
2. A `VimLeavePre` autocmd writes that path to the file named by `$NVIM_CWD_FILE`.
3. The fish `nvim` wrapper (see below) reads that file, `cd`s there, and reopens
   `nvim`. [mini.sessions](https://github.com/nvim-mini/mini.sessions) saves the old
   project on the way out (see the `VimLeavePre` autocmd in `plugin/mini.lua`), and
   the new one opens on [mini.starter](https://github.com/nvim-mini/mini.starter)
   with **Resume** as the first entry.

A plain `:qa` (nothing picked) writes nothing, so you exit wherever you were.

## Required shell wrapper

The relaunch only happens when Neovim is launched through a wrapper that sets
`$NVIM_CWD_FILE` and loops on it. Example fish function
(`~/.config/fish/user/functions/nvim.fish`):

```fish
function nvim --wraps nvim --description "nvim + zoxide project switching"
    set -lx NVIM_CWD_FILE (mktemp)
    while true
        command nvim $argv
        set -l target (cat $NVIM_CWD_FILE)
        test -z "$target"; and break   # normal quit -> stay put
        printf '' >$NVIM_CWD_FILE       # consume the request
        cd $target                      # zoxide's PWD hook bumps frecency
        set argv                        # relaunch fresh (drop file args)
    end
    rm -f $NVIM_CWD_FILE
end
```

Without the wrapper, `<leader>pp` still works but simply quits (no cd, no relaunch).

## Limitations

- Switching is a full Neovim restart, and only relaunches when started via the
  wrapper.
- No frecency editing here — zoxide owns the list; `cd`-ing (which the wrapper
  does) is what bumps it.

# Records assets/preview.gif: `vhs assets/preview.tape`, run from the repo root.
#
# Neovim runs this machine's config against a throwaway clone of the repo, so the
# recording never touches your sessions, shada or working tree. In the clone the
# last eight commits sit on a branch of their own, which gives changeset a diff.

Output assets/preview.gif

Set Shell "bash"
Set FontFamily "Berkeley Mono, Symbols Nerd Font Mono"
# Keeps the screen under 140 columns, where mini.statusline shows paths relative to the cwd.
Set FontSize 19
Set LineHeight 1.2
Set Width 1600
Set Height 1000
Set Padding 20
Set WindowBar Colorful
Set BorderRadius 10
Set CursorBlink false
Set TypingSpeed 80ms
Set Theme { "name": "Van Helsing", "black": "#22212c", "red": "#ff9580", "green": "#8aff80", "yellow": "#ffff80", "blue": "#9580ff", "magenta": "#ff80bf", "cyan": "#80ffea", "white": "#f8f8f2", "brightBlack": "#708ca9", "brightRed": "#ffaa99", "brightGreen": "#a2ff99", "brightYellow": "#ffff99", "brightBlue": "#aa99ff", "brightMagenta": "#ff99cc", "brightCyan": "#99ffee", "brightWhite": "#ffffff", "background": "#0b0d0f", "foreground": "#f8f8f2", "selection": "#34404b", "cursor": "#f8f8f2" }

Hide
Type 'unset ${!HERDR_*} TERM_PROGRAM TERM_PROGRAM_VERSION TERMINFO GHOSTTY_RESOURCES_DIR; export COLORTERM=truecolor' Enter
# The clone's mise.toml would otherwise stop the shell on mise's trust prompt.
Type 'export MISE_IGNORED_CONFIG_PATHS=/private/tmp/nvim-preview' Enter
# pwd -P: a symlinked cwd (/tmp is /private/tmp) makes LSP-opened buffers show absolute paths.
Type 'R=$PWD D=/tmp/nvim-preview; rm -rf $D && git clone -q "$R" $D/nvim && cd $D/nvim && cd "$(pwd -P)" && ln -s "$R/.tests" .tests' Enter
Type 'git switch -qc agents-md && git branch -qf trunk HEAD~8 && git update-ref refs/remotes/origin/trunk HEAD~8' Enter
Type 'clear && nvim -i NONE init.lua' Enter
Wait+Screen@30s /vim\.loader\.enable/
# emmylua_ls indexes the workspace before its progress notification clears.
Sleep 15s
Show

Sleep 2s

# <leader>ff: find a file
Space
Sleep 1.2s
Type "f"
Sleep 800ms
Type "f"
Sleep 400ms
Type "which-key"
Sleep 800ms
Enter
Sleep 1.5s

# gd on the `Cmd` helper, into lua/helpers/mappings.lua
Type@150ms "7j$"
Sleep 500ms
Type "gd"
Sleep 2s

# <leader>fu: reveal the file in mini.files, then walk over to the gotoline plugin
Space
Sleep 600ms
Type "f"
Sleep 700ms
Type "u"
Sleep 1.5s
Type "h"
Sleep 600ms
Type "j"
Sleep 600ms
Type "l"
Sleep 600ms
Type@250ms "jjj"
Sleep 500ms
Type "l"
Sleep 600ms
Type "j"
Sleep 700ms
Type "L"
Sleep 1.5s

# <leader>ji: LSP symbols in the file
Space
Sleep 600ms
Type "j"
Sleep 800ms
Type "i"
Sleep 1s
Type "open"
Sleep 800ms
Enter
Sleep 1.5s

# <leader>sp: grep the project
Space
Sleep 500ms
Type "s"
Sleep 700ms
Type "p"
Sleep 500ms
Type "changeset-tog"
Sleep 1s
Enter
Sleep 1.5s

# <leader>gp: the changeset sidebar; ]h previews each changed row
Space
Sleep 500ms
Type "g"
Sleep 900ms
Type "p"
Sleep 2s
Type "]h"
Sleep 1.1s
Type "]h"
Sleep 1.1s
Type "]h"
Sleep 1.1s
Enter
Sleep 2.5s

# <leader>bb: back to an open buffer
Space
Sleep 500ms
Type "b"
Sleep 600ms
Type "b"
Sleep 800ms
Type "which"
Sleep 600ms
Enter
Sleep 1.5s

# <leader><leader>: search every keybinding
Space
Sleep 600ms
Space
Sleep 800ms
Type "changeset"
Sleep 2.5s
Escape
Sleep 1.5s

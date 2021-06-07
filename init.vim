" Lua code is in the 'lua/' folder, ref the init.lua file in there for more details
" DEFAULT TO USING LUA FOR CONFIG UNLESS IT'S A PITA

luafile $NVIM_HOME/lua/config.lua

""" Vim-specific Configurations """

" $NVIM_HOME should be an env variable pointing to where your neovim config is located.
" $PLUG_NVIM_HOME should be an env variable pointing to where your neovim plugin configs are located.
" Examples:
"       export NVIM_HOME="$DOTFILES_HOME/nvim"
"       export PLUG_NVIM_HOME="$NVIM_HOME/viml/plug"

source $PLUG_NVIM_HOME/coc.vim
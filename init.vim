" If you need to look into what's consuming so much startup time, consider using:
" https://github.com/dstein64/vim-startuptime/tree/7a97baae32bedbf6f62d5a573777e4d1652787d1

" $NVIM_HOME should be an env variable pointing to where your neovim config is located.
" $PLUG_NVIM_HOME should be an env variable pointing to where your neovim plugin configs are located.
" Examples:
"       export NVIM_HOME="$DOTFILES_HOME/nvim"
"       export PLUG_NVIM_HOME="$NVIM_HOME/viml/plug"

""" Lua Configurations """
" DEFAULT TO USING LUA FOR CONFIG UNLESS IT'S A PITA

luafile $NVIM_HOME/lua/config.lua

""" Vim-specific Configurations """

source $PLUG_NVIM_HOME/coc.vim
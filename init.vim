" If you need to look into what's consuming so much startup time, consider using:
" https://github.com/dstein64/vim-startuptime/

" $NVIM_HOME should be an env variable pointing to where your neovim config is located.
" $PLUG_NVIM_HOME should be an env variable pointing to where your neovim plugin configs are located.
" Examples:
"       export NVIM_HOME="$DOTFILES_HOME/nvim"
"       export PLUG_NVIM_HOME="$NVIM_HOME/viml/plug"

""" Lua Configurations """
" DEFAULT TO USING LUA FOR CONFIG UNLESS IT'S A PITA
" NOTE: Plugins are still installed in lua/plugins.lua

luafile $NVIM_HOME/lua/config.lua

for file in split(globpath($NVIM_HOME + "/viml", "*.vim", "\n"))
    execute("source ".file)
endfor

for file in split(globpath($PLUG_NVIM_HOME, "*.vim", "\n"))
    execute("source ".file)
endfor


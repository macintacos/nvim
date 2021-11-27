call wilder#setup({'modes': [':', '/', '?']})
call wilder#set_option('use_python_remote_plugin', 0)

" Fuzzy-completion in the wildmenu (!!!)
call wilder#set_option('pipeline', [
    \   wilder#branch(
    \     wilder#cmdline_pipeline({
    \       'fuzzy': 1,
    \       'fuzzy_filter': wilder#lua_fzy_filter(),
    \     }),
    \     wilder#vim_search_pipeline(),
    \   ),
    \ ])

" wilder#popupmenu_border_theme() is optional.
" 'min_height' : sets the minimum height of the popupmenu
"              : can also be a number
" 'max_height' : set to the same as 'min_height' to set the popupmenu to a fixed height
" 'reverse'    : if 1, shows the candidates from bottom to top
call wilder#set_option('renderer',wilder#popupmenu_renderer(wilder#popupmenu_border_theme({
    \ 'highlighter': wilder#basic_highlighter(),
    \ 'highlights': {
    \   'accent': wilder#make_hl('WilderAccent', 'Pmenu', [{}, {}, {'foreground': '#f4468f'}]),
    \ },
    \ 'min_width': '100%',
    \ 'min_height': '15%',
    \ 'max_height': '15%',
    \ 'reverse': 0,
    \ 'left': [
    \   ' ', wilder#popupmenu_devicons(),
    \ ],
    \ 'right': [
    \   ' ', wilder#popupmenu_scrollbar(),
    \ ]
    \ })))

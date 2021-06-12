" Plug 'kana/vim-textobj-user'
" Description: add our own objects for selection purposes

" preservim/vim-textobj-quote
augroup textobj_quote
    autocmd!
    autocmd FileType markdown call textobj#quote#init()
    autocmd FileType textile call textobj#quote#init()
    autocmd FileType text call textobj#quote#init({'educate': 0})
augroup END

" preservim/vim-textobj-sentence
augroup textobj_sentence
    autocmd!
    autocmd FileType markdown call textobj#sentence#init()
    autocmd FileType textile call textobj#sentence#init()
augroup END

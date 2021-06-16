" Plug 'neoclide/coc.nvim'
" Description: an nvim autocompletion engine

" global extensions.... just in case
" can be found in ~/.config/coc/extensions/package.json
let g:coc_global_extensions = [
  \  "coc-css",
  \  "coc-dictionary",
  \  "coc-emmet",
  \  "coc-emoji",
  \  "coc-eslint",
  \  "coc-explorer",
  \  "coc-go",
  \  "coc-html",
  \  "coc-json",
  \  "coc-lists",
  \  "coc-lua",
  \  "coc-markdownlint",
  \  "coc-marketplace",
  \  "coc-prettier",
  \  "coc-pyright",
  \  "coc-rust-analyzer",
  \  "coc-sh",
  \  "coc-snippets",
  \  "coc-tailwindcss",
  \  "coc-tsserver",
  \  "coc-vimlsp",
  \  "coc-word",
  \  "coc-yaml"
  \ ]

" Use <c-space> to trigger completion.
inoremap <silent><expr> <C-space> coc#refresh()



" Use `[c` and `]c` to navigate diagnostics
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(co:c-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use gh to show documentation in preview window.
nnoremap <silent> gh :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" For formatting selected code (coc-format-selected)
augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder.
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Map function and class text objects
" NOTE: Requires 'textDocument.documentSymbol' support from the language server.
xmap if <Plug>(coc-funcobj-i)
omap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap af <Plug>(coc-funcobj-a)
xmap ic <Plug>(coc-classobj-i)
omap ic <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call CocAction('runCommand', 'editor.action.organizeImport')

" coc-go
autocmd BufWritePre *.go :silent call CocAction('runCommand', 'editor.action.organizeImport')

" symbols
let g:coc_status_error_sign = " " " nf-fa-times_circle
let g:coc_status_warning_sign = " " " nf-fa-exclamation_triangle

" autocomplete menu styling
func! s:dracula_colors_menu() abort
  hi Pmenu guibg=#272941 guifg=#6272a4
  hi PmenuSel guibg=#212337 guifg=#6272a4
endfunc

au ColorScheme * call s:dracula_colors_menu()

" have vim start coc-explorer if vim started with folder
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'CocCommand explorer' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif


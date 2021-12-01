" Open inline diff for changes in current file in a vertical splti
command! DiffInlineFile sp | exe 'term git diff -- '
    \ . shellescape(expand("%")) . ' | delta' | startinsert

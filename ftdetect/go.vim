" beryl_go/ftdetect/go.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

" ft=go by extension
autocmd! BufNewFile,BufRead	*.go setf go

" augroup beryl_go_events_before_save
"     au!
"     autocmd! FileType go autocmd BufWritePre <buffer> :%s/\s\+$//ge
" augroup END

augroup beryl_go_after_save
    au!
    autocmd! FileType go autocmd BufWritePost <buffer> call beryl#go#after_save()
augroup END


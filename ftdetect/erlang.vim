" beryl_erlang/ftdetect/erlang.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

" ft=erlang by extension
autocmd! BufNewFile,BufRead	*.erl,*.hrl,*.escript,*.config.script,sys.config setf erlang

augroup beryl_erlang_before_save
    au!
    autocmd! FileType erlang autocmd BufWritePre <buffer> :%s/\s\+$//ge
augroup END

augroup beryl_erlang_after_save
    au!
    autocmd! FileType erlang autocmd BufWritePost <buffer> call beryl#erlang#after_save()
augroup END

autocmd! BufReadPre *.beam setlocal binary
autocmd! BufReadPost *.beam call beryl#erlang#decompile()


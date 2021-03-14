" beryl_vim/ftdetect/vim.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

call system('ftdetect/vim.vim >> /tmp/log')

" ft=vim by extension
autocmd! BufNewFile,BufRead	*.vim setf vim

augroup beryl_vim_events_before_save
    au! 
    autocmd! FileType vim autocmd BufWritePre <buffer> :%s/\s\+$//ge
augroup END

augroup beryl_vim_after_save
    au!
    autocmd! FileType vim autocmd BufWritePost <buffer> call beryl#vim#after_save()
augroup END



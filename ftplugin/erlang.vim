" beryl/ftplugin/erlang.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists('b:did_ftplugin')
	finish
endif
let b:did_ftplugin = 1

let b:beryl_list_tags = 'beryl#erlang#list_tags'

setlocal softtabstop=4
setlocal shiftwidth=4
setlocal expandtab

setlocal commentstring=\%%s

execute 'setlocal tags=' . g:beryl_erlang_project_tagfile . ',' . g:beryl_erlang_otp_tagfile

set errorformat=%f:%l:%c:%m,%f:%l:%t:%m,%f:%l:%m,%f:%l:\ %trror:%m,%f:%l:\ %tarning:%m

setlocal omnifunc=beryl#erlang#omnifunc
setlocal completeopt=menuone,longest,preview

nnoremap <silent> <buffer> <C-]> :call beryl#erlang#goto_tag()<CR>
inoremap <silent> <buffer> <C-]> <ESC>:call beryl#erlang#goto_tag()<CR>

execute 'nnoremap <silent> <buffer> ' . g:beryl_find_usages_key . ' :call beryl#erlang#find_usages()<CR>'
execute 'inoremap <silent> <buffer> ' . g:beryl_find_usages_key . ' <ESC>:call beryl#erlang#find_usages()<CR>'

" execute 'nnoremap <silent> <buffer> ' . g:beryl_list_tags_key . ' :call beryl#select#open("tags")<CR>'
" execute 'inoremap <silent> <buffer> ' . g:beryl_list_tags_key . ' <ESC>:call beryl#select#open("tags")<CR>'

nnoremap <silent> <buffer> ]] :call search('^[a-z][_a-zA-Z0-9]* *(')<CR>
nnoremap <silent> <buffer> [[ :call search('^[a-z][_a-zA-Z0-9]* *(', 'b')<CR>


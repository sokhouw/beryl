" beryl_go/ftplugin/go.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists('b:did_ftplugin')
	finish
endif
let b:did_ftplugin = 1

let b:beryl_list_tags = 'beryl#go#list_tags'

" ----------------------------------------------------------------------------------
" indentation & whitespace
" ----------------------------------------------------------------------------------
"
setlocal softtabstop=4
setlocal shiftwidth=4
setlocal expandtab

setlocal comments=s1:/*,mb:*,ex:*/,://
setlocal commentstring=//\ %s

execute 'setlocal tags=' . g:beryl_go_root_tagfile . ',' . g:beryl_go_project_tagfile

" setlocal omnifunc=beryl#go#omnifunc
" setlocal completeopt=menuone,longest,preview
" set errorformat=%f:%l:%c:%m,%f:%l:%t:%m,%f:%l:%m,%f:%l:\ %trror:%m,%f:%l:\ %tarning:%m

nnoremap <silent> <buffer> <C-]> :call beryl#go#goto_tag()<CR>
inoremap <silent> <buffer> <C-]> <ESC>:call beryl#go#goto_tag()<CR>

" based on https://github.com/fatih/vim-go/blob/master/compiler/go.vim
set errorformat =%-G#\ %.%#                                 " Ignore lines beginning with '#' ('# command-line-arguments' line sometimes appears?)
set errorformat+=%-G%.%#panic:\ %m                          " Ignore lines containing 'panic: message'
set errorformat+=%Ecan\'t\ load\ package:\ %m               " Start of multiline error string is 'can\'t load package'
set errorformat+=%A%\\%%(%[%^:]%\\+:\ %\\)%\\?%f:%l:%c:\ %m " Start of multiline unspecified string is 'filename:linenumber:columnnumber:'
set errorformat+=%A%\\%%(%[%^:]%\\+:\ %\\)%\\?%f:%l:\ %m    " Start of multiline unspecified string is 'filename:linenumber:'
set errorformat+=%C%*\\s%m                                  " Continuation of multiline error message is indented
set errorformat+=%-G%.%#                                    " All lines not matching any of the above patterns are ignored

command! BerylRootTags call beryl#go#create_root_tagfile()


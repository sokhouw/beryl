" beryl/ftplugin/vim.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists('b:did_ftplugin')
	finish
endif
let b:did_ftplugin = 1

let b:beryl_list_tags = 'beryl#vim#list_tags'

setlocal iskeyword+=:
setlocal iskeyword+=#
setlocal commentstring=\"%s

setlocal tags=.tags


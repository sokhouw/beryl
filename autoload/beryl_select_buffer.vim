" beryl-select/autoload/beryl_select.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl_select_buffer")
	finish
endif
let g:autoload_beryl_select_buffer = 1

" -------------------------------------------------------------------------------------
" API
" -------------------------------------------------------------------------------------

function! beryl_select_buffer#open(item)
	silent execute 'b ' . a:item.bufnr
endfunction

function! beryl_select_buffer#list()
	redir => l:result
	silent execute "files"
	redir END
	let l:items = []
	let l:index = 0
	for s in split(l:result, "\n")
		let l:item = {
			\ 'name':	(split(strpart(s, 9), "\""))[0],
			\ 'modified':	strpart(s, 7, 1) == '+',
			\ 'bufnr':	str2nr(strpart(s, 0, 3))}
		let l:items = l:items + [l:item]
	endfor
	return l:items
endfunction

function! beryl_select_buffer#render(item)
	return (a:item.modified ? '+' : ' ') . ' ' . a:item.name
endfunction

function! beryl_select_buffer#get_name(rendered)
	return strpart(a:rendered, 2)
endfunction


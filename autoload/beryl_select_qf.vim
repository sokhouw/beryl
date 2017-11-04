" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:beryl_select_qf")
	finish
endif
let g:beryl_select_qf = 1

" -------------------------------------------------------------------------------------
" API
" -------------------------------------------------------------------------------------

function! beryl_select_qf#open(item)
    call beryl#selectqflist(a:item.name)
endfunction

function! beryl_select_qf#list()
	let l:items = []
	for [k, v] in items(beryl#getqflists())
		call add(l:items, {
                \ 'modified' : 0,
                \ 'name': l:k,
                \ 'descr': l:v})
	endfor
	return l:items
endfunction

function! beryl_select_qf#render(item)
    return '  ' . a:item.name
endfunction

function! beryl_select_qf#get_name(rendered)
	return strpart(a:rendered, 2)
endfunction


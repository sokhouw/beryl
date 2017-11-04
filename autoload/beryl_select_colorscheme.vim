" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:beryl_select_colorscheme")
	finish
endif
let g:beryl_select_colorscheme = 1

" -------------------------------------------------------------------------------------
" API
" -------------------------------------------------------------------------------------

function! beryl_select_colorscheme#open(item)
	silent execute 'colorscheme ' . a:item.name
endfunction

function! beryl_select_colorscheme#list()
	let l:items = []
	for l:path in split(globpath(&rtp, "colors/*.vim"), '\n')
		let l:name = fnamemodify(l:path, ':t:r')
		call add(l:items, {'name': l:name})
	endfor
	return l:items
endfunction

function! beryl_select_colorscheme#render(item)
	return '  ' . a:item.name
endfunction

function! beryl_select_colorscheme#get_name(rendered)
	return strpart(a:rendered, 2)
endfunction


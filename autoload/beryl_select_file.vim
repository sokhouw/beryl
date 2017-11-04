" beryl-select/autoload/beryl_select.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl_select_file")
	finish
endif
let g:autoload_beryl_select_file = 1

" -------------------------------------------------------------------------------------
" API
" -------------------------------------------------------------------------------------

function! beryl_select_file#list()
	let l:filters = deepcopy(g:beryl_select_ignore)
	if (!g:beryl_select_hidden_files)
		let l:filters = l:filters + ['^\\.', '/\\.']
	endif
	let l:cmd = 'export LC_COLLATE="C"; find -L -type f | cut -c 3-' . join(map(l:filters, '" | grep -ve \"" . v:val . "\""')) . ' | sort'
	let l:items = map(split(system(l:cmd), '\n'), "{'name': v:val, 'modified': 0}")
	return l:items
endfunction

function! beryl_select_file#open(item) 
	silent execute 'badd ' . a:item.name
	silent execute 'b ' . a:item.name
endfunction

function! beryl_select_file#render(item)
	return '  ' . a:item.name
endfunction

function! beryl_select_file#get_name(rendered)
	return strpart(a:rendered, 2)
endfunction


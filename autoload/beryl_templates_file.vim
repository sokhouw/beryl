" beryl-templates/autoload/beryl_templates.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl_templates_file")
	finish
endif
let g:autoload_beryl_templates_file = 1

function! beryl_templates_file#list()
	let l:items = [{'name': '[NEW FILE]',
			\ 'modified': 0,
			\ 'filetype': '',
			\ 'path': ''}]
	let l:root = g:beryl_templates_root . '/files/'
	let l:len = strlen(l:root)
	for l:path in split(globpath(l:root, '**'), '\n') 
		if !isdirectory(l:path)
			let l:name = strpart(l:path, l:len)
			let l:filetype = split(l:name, '/')[0]
			call add(l:items, {
				\ 'name': l:name,
				\ 'modified': 0, 
				\ 'filetype': l:filetype, 
				\ 'path': l:path})
		endif
	endfor
	return l:items
endfunction

function! beryl_templates_file#new(item)
	enew
	if a:item.path != ''
		execute 'r ' . a:item.path
		execute '1d'
		execute 'set ft=' . a:item.filetype
		call beryl_templates#resolve()
		setlocal nomodified
		call beryl_templates#start()
	endif
endfunction

function! beryl_templates_file#render(item)
    return '  ' . a:item.name
endfunction

function! beryl_templates_file#get_name(rendered)
    return strpart(a:rendered, 2)
endfunction


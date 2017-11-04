" beryl-templates/autoload/beryl_templates.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl_templates_snippet")
	finish
endif
let g:autoload_beryl_templates_snippet = 1

function! beryl_templates_snippet#list()
	let l:items = []
	let l:root = g:beryl_templates_root . '/snippets/'
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

function! beryl_templates_snippet#normal(item)
	call beryl_templates_snippet#insert(a:item, 0)
endfunction

function! beryl_templates_snippet#visual(item)
	call beryl_templates_snippet#insert(a:item, 1)
endfunction

function! beryl_templates_snippet#insert(item, visual)
	if a:visual
		normal! gvx
	endif
	if getline('.') == ''
		let l:indent = repeat(' ', ErlangIndent())
		call setline('.', l:indent . ' ')
		normal! $
	else
		let l:indent = repeat(' ', col('.') - 1)
	endif
	let l:line = line('.')
	let l:before_snippet = strpart(getline('.'), 0, col('.') - 1)
	let l:after_snippet = strpart(getline('.'), col('.') - 1)
	let l:snippet = s:read_snippet(a:item.path, a:visual)
	call setline(line('.'), l:before_snippet . l:snippet.content[0])
	for l:snippet_line in l:snippet.content[1:]
		call append(l:line, l:indent . l:snippet_line)
		let l:line += 1
	endfor
	call setline(l:line, getline(l:line) . l:after_snippet)
	call beryl_templates#resolve()
	call beryl_templates#start()
endfunction

function! s:read_snippet(path, visual)
	let l:content = join(readfile(a:path), "\n")
	if a:visual
		let l:content = substitute(l:content, '<<\i\+:visual>>', getreg(), '')
	endif
	let l:content = substitute(l:content, '<<\(\i\+\):visual>>', '<<\1>>', 'g') 
	return {'content': split(l:content, "\n")}
endfunction

" based on https://stackoverflow.com/a/1534347
function! s:take_visual()
	let l:save = @a
	try
		normal! gv"ay
		return @a
	finally
		let @a = l:save
	endtry
endfunction

function! beryl_templates_snippet#render(item)
    return '  ' . item.name
endfunction

function! beryl_templates_snippet#get_name(rendered)
    return strpart(a:rendered, 2)
endfunction


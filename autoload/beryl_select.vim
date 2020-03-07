" beryl-select/autoload/beryl_select.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl_select")
	finish
endif
let g:autoload_beryl_select = 1

let s:modes = {}

" -------------------------------------------------------------------------------------
" API - generic
" -------------------------------------------------------------------------------------

function! beryl_select#configure(mode, on_list, on_select, key)
	let s:modes[a:mode] = {
		\ 'on_list': a:on_list,
		\ 'on_select': a:on_select,
        \ 'key': a:key
	\ }
endfunction

function! beryl_select#open()
	l:text = ''
	l:modes = {}
	for [key, val] in items(s:modes)
		let l:text = l:text . (l:text != '' ? '\' : '') . l:val.shortcut
		let l:modes[len(l:modes) + 1] = l:key
	endfor
	l:choice = confirm('', l:text)
	if exists('l:modes[' . l:choice . '])
		call beryl_select#open(l:modes[l:choice])
	endif
endfunction

function! beryl_select#open(mode)
	let l:bufnr = bufnr('%')
	let l:pos = getpos('.')
	call beryl#qf_temp_close()
	let w:dest = 1
	silent below new
	silent setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nonu cursorline filetype=files
	let l:window = -1
	windo if exists('w:dest') | let l:window = winnr() | endif
	let l:mode = a:mode
	while l:mode != ''
		let l:items = {s:modes[l:mode].on_list}()

		let l:context = {
				\ 'mode': l:mode,
				\ 'pos': l:pos,
				\ 'on_select': s:modes[l:mode].on_select,
				\ 'file_bufnr': l:bufnr, 
				\ 'this_bufnr': bufnr('%'),
				\ 'total_count': len(l:items),
				\ 'filter': [], 'filter_str': '', 
				\ 'filtered_count': len(l:items),
                \ 'key': substitute(s:modes[l:mode].key, ' ', '', ''),
				\ 'items': l:items}
		setlocal modifiable noreadonly
		silent execute '%d'
		for l:item in l:items
			call s:append(l:item)
		endfor
		silent execute '1d'
		silent setlocal readonly nomodifiable

		silent execute "resize " . min([line("$"), g:beryl_select_max_size])

		let l:mode = s:loop(l:context)
	endwhile

	windo if exists('w:dest') | unlet w:dest | endif
	call beryl#qf_reopen()
endfunction

" -------------------------------------------------------------------------------------
" API - selecting buffer
" -------------------------------------------------------------------------------------

function! beryl_select#list_buffers()
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

function! beryl_select#open_buffer(item)
	silent execute 'b ' . a:item.bufnr
endfunction

" -------------------------------------------------------------------------------------
" API - selecting file
" -------------------------------------------------------------------------------------

function! beryl_select#list_files()
	let l:filters = deepcopy(g:beryl_select_ignore)
	if (!g:beryl_select_hidden_files)
		let l:filters = l:filters + ['^\\.', '/\\.']
	endif
	let l:cmd = 'export LC_COLLATE="C"; find -L -type f | cut -c 3-' . join(map(l:filters, '" | grep -ve \"" . v:val . "\""')) . ' | sort'
	let l:items = map(split(system(l:cmd), '\n'), "{'name': v:val, 'modified': 0}")
	return l:items
endfunction

function! beryl_select#open_file(item) 
	silent execute 'badd ' . a:item.name
	silent execute 'b ' . a:item.name
endfunction

" -------------------------------------------------------------------------------------
" API - selecting template
" -------------------------------------------------------------------------------------

function! beryl_select#list_templates()
    let l:var = 'g:beryl_' . beryl#handler().name . '_templates'
    if exists(l:var)
        echom 'OK'
        return eval(l:var)
    else
        return []
    endif
endfunction

function! beryl_select#new_file_from_template(item)
    let l:lang = beryl#handler().name
    let l:snippet = values(values(snipMate#GetSnippets([l:lang], a:item.snippet))[0])[0]
    let l:path = input('Filename: ')
    execute 'e ' . l:path
    execute 'set ft=' . l:lang
    call snipMate#expandSnip(l:snippet[0], l:snippet[1], 1)
	call cursor(1, 1)
    redraw!
endfunction

" -------------------------------------------------------------------------------------
" API - selecting colorscheme
" -------------------------------------------------------------------------------------

function! beryl_select#list_colorschemes()
	let l:items = []
	for l:path in split(globpath(&rtp, "colors/*.vim"), '\n')
		let l:name = fnamemodify(l:path, ':t:r')
		call add(l:items, {
				\ 'name': l:name,
				\ 'modified': exists('g:colors_name') && l:name == g:colors_name})
	endfor
	return l:items
endfunction

function! beryl_select#select_colorscheme(item)
	silent execute 'colorscheme ' . a:item.name
endfunction

" -------------------------------------------------------------------------------------
" Internals - event loop
" -------------------------------------------------------------------------------------

function! s:loop(context)
	while 1
		call s:prompt(a:context)
		let l:code = getchar()
		let l:char = nr2char(l:code)
		if l:code == 13 && a:context.filtered_count > 0
			let l:item = s:find(a:context)
			call s:close(a:context)
			call {a:context.on_select}(l:item)
			redraw!
			return ''
		elseif l:char is# "\<ESC>" || (type(l:code) == type(0) && eval('nr2char(' . l:code . ') is# "\' . a:context.key . '"'))
			call s:close(a:context)
			redraw!
			return ''
		elseif l:code is# "\<DEL>"
			let l:item = s:find(a:context)
			if has_key(l:item, 'bufnr') && l:item.bufnr >= 0
				if len(a:context.items) > 1
					setlocal modifiable noreadonly
					silent execute "d"
					let a:context.items = filter(a:context.items, 'v:val.bufnr != '. l:item.bufnr)
					let l:next = s:find(a:context)
					windo if exists('w:dest') && bufname('%') == l:item.name | execute 'b ' . l:next.bufnr | endif
					silent execute "bw " . l:item.bufnr
					silent setlocal nomodifiable readonly
					silent execute "resize " . min([line("$"), g:beryl_select_max_size])
				else
					call s:close(a:context)
					redraw!
					return ''
				endif
			endif
		elseif l:code >= 32 && l:code < 127
			let a:context.filter += [l:char]
			call s:filter(a:context)
		elseif l:code is# "\<BS>"
			let a:context.filter = a:context.filter[0:-2]
			call s:filter(a:context)
		elseif s:is_movement(l:code)
			silent execute 'norm ' . l:code
		endif
	endwhile
endfunction

" -------------------------------------------------------------------------------------
" Internal
" -------------------------------------------------------------------------------------

function! s:prompt(context)
	redraw!
	echohl MoreMsg | echon '>>> ' . join(a:context.filter, '') | echohl None
endfunction

function! s:close(context)
	execute 'bwipe ' . a:context.this_bufnr
    silent execute 'b ' . a:context.file_bufnr
"	bufdo if bufnr('%') == a:context.file_bufnr | call setpos('.', a:context.pos) | endif
endfunction

function! s:find(context)
	let l:name = strpart(getline('.'), 2)
	for l:item in a:context.items
		if l:name == l:item.name
			return l:item
		endif
	endfor
endfunction

function! s:filter(context)
	let l:filter = s:join_filter(a:context.filter)
	let l:pos = getpos(".")
	let a:context.filtered_count = 0
	setlocal modifiable noreadonly
	silent execute "%d"
	for item in a:context.items
		if (l:item.name =~ l:filter)
			call s:append(l:item)
			let a:context.filtered_count += 1
		endif
	endfor
	silent execute "1d"
	if (a:context.filtered_count == 0)
		silent execute "%d"
		silent call append(line("$"), " == NO ENTRIES ==")
		silent execute "1d"
		silent execute "match Error /== NO ENTRIES ==/"
	else
		silent call setpos(".", l:pos)
	endif
	silent setlocal nomodifiable readonly	
	silent execute "resize " . min([line("$"), g:beryl_select_max_size])
	silent execute 'match Search /' . l:filter . '/'
endfunction

function! s:append(item)
	call append(line('$'), (a:item.modified ? '+' : ' ') . ' ' . a:item.name)
endfunction

function! s:is_movement(c)
	return a:c is# "\<Up>" || a:c is# "\<Down>" || a:c is# "\<PageUp>" || a:c is# "\<PageDown>" || a:c is# "\<Left>" || a:c is# "\<Right>"
endfunction

function! s:join_filter(filter)
	let l:filter = []
	for f in a:filter
		let l:filter = l:filter + [escape(f, './')]
	endfor
	return join(l:filter, '[a-zA-Z0-9]*')
endfunction


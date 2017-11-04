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

function! beryl_select#configure(mode, descr, on_list, on_select, on_render, get_name)
	let s:modes[a:mode] = {
        \ 'descr': a:descr,
		\ 'on_list': a:on_list,
		\ 'on_select': a:on_select,
        \ 'on_render': a:on_render,
        \ 'get_name': a:get_name}
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
    let b:beryl_select_descr = s:modes[a:mode].descr
	let l:window = -1
	windo if exists('w:dest') | let l:window = winnr() | endif
	let l:mode = a:mode
	while l:mode != ''
		let l:items = {s:modes[l:mode].on_list}()

		let l:context = {
				\ 'mode': l:mode,
				\ 'pos': l:pos,
				\ 'on_select': s:modes[l:mode].on_select,
                \ 'on_render': s:modes[l:mode].on_render,
                \ 'get_name': s:modes[l:mode].get_name,
				\ 'items': l:items, 
				\ 'file_bufnr': l:bufnr, 
				\ 'this_bufnr': bufnr('%'),
				\ 'total_count': len(l:items),
				\ 'filter': [], 'filter_str': '', 
				\ 'filtered_count': len(l:items)}
		setlocal modifiable noreadonly
		silent execute '%d'
		for l:item in l:items
			call append(line('$'), {l:context.on_render}(l:item))
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
		elseif l:char is# "\<ESC>"
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
	let l:name = {a:context.get_name}(getline('.'))
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
			call append(line('$'), {a:context.on_render}(l:item))
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


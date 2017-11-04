" beryl-templates/autoload/beryl_templates.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl_templates")
	finish
endif
let g:autoload_beryl_templates = 1

let g:beryl_templates_left = '<<'
let g:beryl_templates_right = '>>'
let g:beryl_templates_pattern = g:beryl_templates_left . '\i\+' . g:beryl_templates_right

function! beryl_templates#set_root_dir(dir)
    let g:beryl_templates_root = a:dir
endfunction

function! beryl_templates#resolve()
	for [key, val] in items(g:beryl_templates_values)
		call s:resolve(key, val)
	endfor
	for [key, val] in items(s:default_values())
		call s:resolve(key, val)
	endfor
endfunction

function! beryl_templates#unresolved()
	let l:view = winsaveview()
	silent execute 'normal 1G^'
	let [line, col] = searchpos(g:beryl_templates_pattern, 'cW')
	let l:unresolved = []
	while l:line != 0
		silent execute 'normal f>f>'
		let [x, eline, ecol, y] = getpos('.')
		let l:unresolved = add(l:unresolved, strpart(getline('.'), l:col - 1, l:ecol - l:col + 1)) 
		let [line, col] = searchpos(g:beryl_templates_pattern, 'W')
	endwhile
	call winrestview(l:view)
	return l:unresolved
endfunction

function! beryl_templates#match_under_cursor()
        let [line_pos, col_pos] = getpos('.')[1:2]
        let [line_bgn, col_bgn] = searchpos(g:beryl_templates_left, 'bcnW')
        let [line_end, col_end] = searchpos(g:beryl_templates_right, 'cenW')
        if l:line_bgn == l:line_pos && l:line_pos == l:line_end && l:col_bgn <= l:col_pos && l:col_pos <= l:col_end
		let l:current = strpart(getline('.'), l:col_bgn - 1, l:col_end - l:col_bgn + 1)
		if exists('b:beryl_templates_current_match_id')
			call matchdelete(b:beryl_templates_current_match_id)
		endif
		let b:beryl_templates_current_match_id = matchadd('BerylTemplatesCurrentPlaceholder', l:current, 11)
                return [l:current, l:col_bgn, l:col_end]
        else
                return []
        endif
endfunction

function! beryl_templates#start()
	if search(g:beryl_templates_pattern, 'wn') != 0
		if !exists('b:beryl_templates_match_id')
			let b:beryl_templates_match_id = matchadd('BerylTemplatesPlaceholders', g:beryl_templates_pattern, 10)
			silent execute 'imap <TAB> <ESC>`^:call beryl_templates#next()<CR>'
			silent execute 'nmap <TAB> l:call beryl_templates#next()<CR>'
			silent execute 'imap <DEL> <ESC>`^:call beryl_templates#delete(1)<CR>'
			call search(g:beryl_templates_pattern, 'w')
			silent execute 'aug BerylTemplates'
			silent execute 'au!'
			silent execute 'au BerylTemplates InsertCharPre * let v:char = beryl_templates#insert(v:char)'
			silent execute 'au BerylTemplates TextChangedI * let v:char = beryl_templates#text_changed()'
			silent execute 'aug END'
			let [ str, col_bgn, col_end ] = beryl_templates#match_under_cursor()
			silent execute 'startinsert'
		endif
	endif
endfunction

function! beryl_templates#next()
	if search(g:beryl_templates_pattern, 'w') > 0
		call beryl_templates#match_under_cursor()
		silent execute 'startinsert'
	else
		call beryl_templates#done()
	endif
endfunction

function! beryl_templates#insert(char)
	if beryl_templates#match_under_cursor() != []
		call feedkeys("\<DEL>" . a:char) 
		return ''
	else
		return a:char
	endif
endfunction

function! beryl_templates#delete(change)
	let l:match = beryl_templates#match_under_cursor()
	if l:match == [] | silent execute 'normal x' | return | endif
	let [ str, col_bgn, col_end ] = l:match
	call search(g:beryl_templates_left, 'bcW')
	let l:command = l:col_end < strlen(getline('.')) ? 'startinsert' : 'startinsert!'
	silent execute 'normal ' . string(l:col_end - l:col_bgn + 1) . 'x'
	if a:change | silent execute l:command | endif
endfunction

function! beryl_templates#text_changed()
	if search(g:beryl_templates_pattern, 'n') == 0
		call beryl_templates#done()
	end

endfunction

function! beryl_templates#done()
	if exists('b:beryl_templates_match_id')
		silent execute 'iunmap <TAB>'
		silent execute 'nunmap <TAB>'
		silent execute 'iunmap <DEL>'
		silent execute 'aug BerylTemplates'
		silent execute 'au!'
		silent execute 'aug END'
		silent execute 'aug! BerylTemplates'
		call matchdelete(b:beryl_templates_match_id)
		unlet b:beryl_templates_match_id
		redraw!
	endif
endfunction

function beryl_templates#mode()
	return exists('b:beryl_templates_match_id') ? 'RESOLVE' : ''
endfunction

function! s:resolve(key, val)
	try
		silent execute '%s/' . g:beryl_templates_left . a:key . g:beryl_templates_right . '/' . a:val . '/g'
	catch
		return
	endtry
endfunction

function! s:default_values()
	return {
		\ 'year': strftime('%Y')}
endfunction

function beryl_templates#oko()
	return "if <<oko>>\n    <<ucho>>\nend"
endfunction

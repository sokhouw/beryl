" beryl/autoload/beryl.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists('g:autoload_beryl')
	finish
endif
let g:autoload_beryl = 1

" language handler
let s:handler =	{ 'name'	: '',
		\ 'init'			: 'beryl#no_op',
		\ 'compile'			: 'beryl#no_op',
		\ 'tags_update'		: 'beryl#no_op',
		\ 'tags_jump'		: 'beryl#no_op',
		\ 'find_usages'		: 'beryl#no_op'}

let g:qf_lists = {}
let g:cur_qf_list = ''

" ---------------------------------------------------------------------------------------
" autodetection
" ---------------------------------------------------------------------------------------

" CalledBy: after/plugin/beryl.vim
" Purpose: autodetect language handler
" Scans all vim files in runtime path match 'autoload/beryl_*.vim' pattern and attempts 
" to call #autodetect(). If it returns true module is deemed as language handler
function! beryl#autodetect()
	for l:path in split(&runtimepath, ',')
		for l:script in split(glob(l:path . '/autoload/beryl_*.vim'), '\n')
			let l:module = fnamemodify(l:script, ':t:r')
			let l:autodetect = l:module . '#autodetect'
			let l:autodetected = 0
			try 
				let l:autodetected = {l:autodetect}()
			catch 'E117:.*'
				" display an error if the problem is inside autodetect function
				" duh, need to call it again but not inside try-catch
				if exists('*' . l:autodetect)
					call {l:autodetect}()
				endif
			endtry
			if l:autodetected
				call s:init_handler(l:module)
				return
			endif
		endfor
	endfor
endfunction

function! s:init_handler(name)
	let s:handler.name = substitute(a:name, 'beryl_', '', 'g')
	for l:s in ['init', 'compile', 'tags_init', 'tags_update', 'tags_jump', 'find_usages']
		let l:fname = a:name . '#' . l:s
		if exists('*' . l:fname)
			let s:handler[l:s] = l:fname
		endif
	endfor
endfunction

function! beryl#no_op()
endfunction

function! beryl#handler()
	return copy(s:handler)
endfunction

" ---------------------------------------------------------------------------------------
" initialization
" ---------------------------------------------------------------------------------------

" CalledBy: called by after/plugin/beryl.vim
" Purpose: initialize beryl and language handler
function! beryl#init()
	execute 'set tags+=' . g:beryl_project_tagfile
	call {s:handler.init}()
endfunction

" ---------------------------------------------------------------------------------------
" Integration with lang handler
" ---------------------------------------------------------------------------------------

" CalledBy: autocmd created by beryl#ftplugin()
" Purpose: trigger actions that are to happen after file is saved
function! beryl#after_save()
	let l:do_tags = 1
	if s:handler.compile !~# '^beryl#'
		let l:do_tags = beryl#compile()
	endif
	if l:do_tags
		call beryl#tags_update()
	endif
endfunction

function! beryl#compile()
    let key =  'compilation report - ' . expand('%')
    let descr = key
    call beryl#qf('compiling...',key, descr, s:handler.compile)
endfunction

function! beryl#find_usages()
    call beryl#qf('searching...', 'usages', 'usages', s:handler.find_usages)
endfunction

function! s:set_status2(buf, s)
	call setbufvar(a:buf, 'beryl_status', a:s)
	if exists('*lightline#update') | call lightline#update() | endif
	redraw
endfunction

function! s:set_status(buf, s, e, w)
	call setbufvar(a:buf, 'beryl_status', a:s)
	call setbufvar(a:buf, 'beryl_errors', a:e)
	call setbufvar(a:buf, 'beryl_warnings', a:w)
	if exists('*lightline#update') | call lightline#update() | endif
	redraw
endfunction

function! beryl#tags_update()
	let l:buf = expand('%')
	call setbufvar(l:buf, 'beryl_task', 'updating tags...')
	redraw!
	try
	       	return {s:handler.tags_update}()
	finally
		call setbufvar(l:buf, 'beryl_task', '')
		redraw!
	endtry
endfunction

function! beryl#tags_jump()
	let l:buf = expand('%')
	call setbufvar(l:buf, 'beryl_task', 'finding tag...')
	redraw!
	try
	       	return {s:handler.tags_jump}()
	finally
		call setbufvar(l:buf, 'beryl_task', '')
		redraw!
	endtry
endfunction

" ---------------------------------------------------------------------------------------
"  ftplugin:
" ---------------------------------------------------------------------------------------

" CalledBy: filtetype specific ftplugin.vim
" Purpose: add mapping and event handlers
function! beryl#ftplugin()
	nnoremap <buffer> <silent> <C-]> :call beryl#tags_jump()<cr>
	inoremap <buffer> <silent> <C-]> <Esc>:call beryl#tags_jump()<cr>
	execute 'autocmd BufWritePost ' . expand('%') . ' call beryl#after_save()'
endfunction

" ---------------------------------------------------------------------------------------
" quickfix
" ---------------------------------------------------------------------------------------

function beryl#qf_temp_close()
	windo if &l:buftype == 'quickfix' | let g:had_qf = 1 | endif
	ccl
endfunction

function beryl#qf_reopen()
	if exists('g:had_qf')
		silent execute 'copen ' . s:qf_height()
		unlet g:had_qf
	endif
endfunction

function! s:qf_height()
	return min([g:beryl_quickfix_max_height, max([1, len(getqflist())])])
endfunction

function! beryl#status()
	return getbufvar(expand('%'), 'beryl_status', 'OK')
endfunction

function! beryl#set_status(status)
    let b:beryl_status_save = exists('b:beryl_status') ? b:beryl_status : 'OK'
    let b:beryl_status = a:status
	if exists('*lightline#update') | call lightline#update() | endif
	redraw
endfunction

function! beryl#restore_status()
    let b:beryl_status = exists('b:beryl_status_save') ? b:beryl_status_save : 'OK'
	if exists('*lightline#update') | call lightline#update() | endif
	redraw
endfunction

function! beryl#mode()
	if exists('g:beryl_templates_match_id')
		return 'RESOLVE'
	else
		return 'OKO'
	endif
endfunction

function! s:describe_int(s, i)
	return a:i > 0 ? a:i . ' ' . a:s . (a:i > 1 ? 's' : '') : ''
endfunction

function! beryl#update_qf_matches()
	call clearmatches()
	let l:bufnr = bufnr(expand('%'))
	if exists('g:beryl_quickfix_highlight') && g:beryl_quickfix_highlight
		for l:v in getqflist()
			if l:v.bufnr == l:bufnr
				if l:v.type == 'E'
					call matchadd('berylQFError', '\%' . l:v.lnum . 'l', 2)
				elseif l:v.type == 'W'
					call matchadd('berylQFWarning', '\%' . l:v.lnum . 'l', 1)
				endif
			endif
		endfor
	endif
endfunction

" ---------------------------------------------------------------------------------------
" quickfix
" ---------------------------------------------------------------------------------------

function beryl#qftoggle()
	let l:qf = 0
	windo if &l:buftype == 'quickfix' | let l:qf = 1 | endif
	if l:qf == 1
		ccl
	else
        if len(g:qf_lists) == 1
    		silent execute 'copen ' . s:qf_height()
        elseif len(g:qf_lists) > 1
            call beryl_select#open('quickfix')
        endif
	endif
endfunction

function! beryl#getqflists()
    return g:qf_lists
endfunction

function! beryl#selectqflist(key)
    if has_key(g:qf_lists, a:key)
        let g:cur_qf_list = a:key
        call setqflist(g:qf_lists[a:key].list)
        silent execute 'copen ' . s:qf_height()
    endif
endfunction

function! beryl#curqfdescr()
    if has_key(g:qf_lists, g:cur_qf_list) 
        return '[' . g:qf_lists[g:cur_qf_list].descr . ']'
    else
        return '[Quickfix List]'
    endif
endfunction

function beryl#qf(status, key, descr, fun)
	let buf = expand('%')
	call s:set_status(l:buf, a:status, 0, 0)
	cgetexpr {a:fun}()
    call s:set_status(l:buf, 'OK', 0, 0)
	if len(getqflist()) == 0
        if has_key(g:qf_lists, a:key)
            if g:cur_qf_list == a:key
                let g:cur_qf_list = ''
                ccl
            endif
            unlet g:qf_lists[a:key]
        endif
        redraw
        return 1
    else 
        let g:qf_lists[a:key] = {'descr': a:descr, 'list': getqflist()}
        let g:cur_qf_list = a:key
        silent execute 'copen ' . s:qf_height()
        redraw
        return 0
	endif
endfunction

function! beryl#getqflists()
    let lists = {}
    for [k, v] in items(g:qf_lists)
        let l:lists[l:k] = l:v.descr
    endfor
    return l:lists
endfunction

" ---------------------------------------------------------------------------------------
" integration points for lightline
" ---------------------------------------------------------------------------------------

function! beryl#title()
    if &buftype == 'quickfix' 
        return beryl#curqfdescr()
    elseif &buftype == 'nofile'
        return ''
    else
        return expand('%')
    endif
endfunction

function! beryl#mode()
    return exists('b:beryl_select_descr') ? b:beryl_select_descr : lightline#mode()
endfunction

function! beryl#readonly()
	return &buftype != "quickfix" && &buftype != "nofile" && &readonly ? "\ue0a2" : ""
endfunction

function! beryl#modified()
	if &buftype != "quickfix" && &buftype != "nofile"
       if !&modifiable
          return '-' 
       elseif &modified
           return '+'
       endif
    endif
    return ''
endfunction


" beryl/autoload/beryl.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists('g:autoload_beryl')
	finish
endif
let g:autoload_beryl = 1

" language handler
let s:handler =	{ 
        \ 'name'        	: '',
        \ 'root'            : '',
		\ 'init'			: 'beryl#no_op',
		\ 'compile'			: 'beryl#no_op',
		\ 'tags_update'		: 'beryl#no_op',
		\ 'tags_jump'		: 'beryl#no_op',
		\ 'find_usages'		: 'beryl#no_op',
        \ 'new_file'        : 'beryl#no_op'}

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
                let s:handler['root'] = l:path
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
	let buf = expand('%')
	call s:set_status(l:buf, 'compiling...', 0, 0)
    call beryl#qf_set_title(expand('%f') . ' - compile report')
	cgetexpr {s:handler.compile}()
	let [l:errors, l:warnings] = [0, 0]
	for l:v in getqflist()
		let l:errors += l:v.type == 'E'
		let l:warnings += l:v.type == 'W'
	endfor
	if len(getqflist()) > 0
		silent execute 'copen ' . min([len(getqflist()), s:qf_height()])
    else
		silent execute 'ccl'
	endif
	call s:set_status(l:buf, l:errors + l:warnings == 0 ? 'OK' : '', l:errors, l:warnings)
	return l:errors == 0
endfunction

function! beryl#find_usages()
	let buf = expand('%')
    let status = getbufvar(l:buf, 'beryl_status')
	call s:set_status2(l:buf, 'searching...')
	cgetexpr {s:handler.find_usages}()
	if len(getqflist()) > 0
		silent execute 'copen ' . min([len(getqflist()), s:qf_height()])
    else
        silent execute 'ccl'
        echom 'Usages not found'
	endif
	call s:set_status2(l:buf, 'OK')
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

function beryl#qf_toggle()
	let l:qf = 0
	windo if &l:buftype == 'quickfix' | let l:qf = 1 | endif
	if l:qf == 1
		ccl
	else
		silent execute 'copen ' . s:qf_height()
	endif
endfunction

function! beryl#qf_set_title(title)
    let g:beryl_quickfix_title = a:title
endfunction

function! s:qf_height()
	return min([g:beryl_quickfix_max_height, max([1, len(getqflist())])])
endfunction

" ---------------------------------------------------------------------------------------
" location window
" ---------------------------------------------------------------------------------------

function beryl#ll_toggle()
	let l:ll = 0
	windo if &l:buftype == 'location' | let l:ll = 1 | endif
	if l:ll == 1
		lcl
	else
        try
    		silent execute 'lopen ' . s:ll_height()
        catch 'E776:.*'
            echom 'No location list'
        endtry
	endif
endfunction

function! s:ll_height()
    return min([g:beryl_loclist_max_height, max([1, len(getloclist(0))])])
endfunction

" ---------------------------------------------------------------------------------------
" location integrations
" ---------------------------------------------------------------------------------------

function! beryl#errors()
	return s:describe_int('error', getbufvar(expand('%'), 'beryl_errors', 0))
endfunction

function! beryl#warnings()
	return s:describe_int('warning', getbufvar(expand('%'), 'beryl_warnings', 0))
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
" lightline
" ---------------------------------------------------------------------------------------

function! beryl#relativepath()
    if &buftype == 'quickfix'
        return exists('g:beryl_quickfix_title') ? '[' . g:beryl_quickfix_title . ']' : '[Quickfix List]'
    else
        return expand('%f')
    endif
endfunction


" autoload/beryl.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl")
	finish
endif
let g:autoload_beryl = 1

" ---------------------------------------------------------------------------------------
" tree
" ---------------------------------------------------------------------------------------

function! beryl#tags_load()
endfunction

function! beryl#tags_select()
endfunction

" ---------------------------------------------------------------------------------------
" quickfix
" ---------------------------------------------------------------------------------------

function! beryl#quickfix_open(...)
    if a:0 > 0
        let g:beryl_quickfix_title = a:1
    endif
    let l:height = min([len(getqflist()), g:beryl_quickfix_max_height])
    if l:height > 0
        silent execute 'ccl|cw ' . l:height
    else
        ccl
    endif
endfunction

function beryl#quickfix_close()
 	ccl
endfunction

function beryl#quickfix_toggle()
	if s:is_quickfix_open()
		call beryl#quickfix_close()
	else
        call beryl#quickfix_open()
	endif
endfunction

function! s:is_quickfix_open()
	let l:qf = 0
	windo if &l:buftype == 'quickfix' | let l:qf = 1 | endif
    return l:qf
endfunction

" -------------------------------------------------------------------------------------
" debug
" -------------------------------------------------------------------------------------

function! beryl#log(msg)
    call system('echo ' . a:msg . ' >> /tmp/beryl')
endfunction

" -------------------------------------------------------------------------------------
" integrations - lightline
" -------------------------------------------------------------------------------------

function! beryl#errors()
    if getbufvar(expand('%'), 'beryl_task', '') == ''
	    return s:describe_int('error', getbufvar(expand('%'), 'beryl_errors', 0))
    else
        return ''
    endif
endfunction

function! beryl#warnings()
    if getbufvar(expand('%'), 'beryl_task', '') == ''
    	return s:describe_int('warning', getbufvar(expand('%'), 'beryl_warnings', 0))
    else
        return ''
    endif
endfunction

function! beryl#status()
    let task = getbufvar(expand('%'), 'beryl_task', '')
    if l:task == ''
        let errors = getbufvar(expand('%'), 'beryl_errors', 0)
        let warnings = getbufvar(expand('%'), 'beryl_warnings', 0)
        if l:errors == 0 && l:warnings == 0
            return 'OK'
        else
            return ''
        endif
    else
        return l:task
    endif
endfunction

function! beryl#task(task)
    call setbufvar(expand('%'), 'beryl_task', a:task)
    if get(g:, 'loaded_lightline', 0)
        call lightline#update()
        redraw!
    endif
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


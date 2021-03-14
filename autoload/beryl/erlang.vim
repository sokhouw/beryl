" autoload/beryl_erlang.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl_erlang")
	finish
endif
let g:autoload_beryl_erlang = 1

let s:compile_tool = g:beryl_root . '/tools/erlang/compile.erl'
let s:decompile_tool = g:beryl_root . '/tools/erlang/decompile.erl'
let s:tag_tool = g:beryl_root . '/tools/erlang/tags.erl'
let s:find_usages_tool = g:beryl_root . '/tools/erlang/find_usages.erl'
let s:find_tags_tool = g:beryl_root . '/tools/erlang/find_tags.erl'

" ---------------------------------------------------------------------------------------
" event handlers
" ---------------------------------------------------------------------------------------

function! beryl#erlang#before_save()
endfunction

function! beryl#erlang#after_save()
    if filereadable(g:beryl_erlang_project_tagfile)
        call beryl#task('updating tags...')
        call beryl#erlang#update_project_tagfile()
    endif
    call beryl#task('compiling...')
    cgetexpr system(s:compile_tool . ' ' . expand('%'))
	let [b:errors, b:warnings] = [0, 0]
	for l:v in getqflist()
		let b:errors += l:v.type == 'E'
		let b:warnings += l:v.type == 'W'
	endfor
    call beryl#task('')
    call beryl#quickfix_open(expand('%') . ' - compilation report')
endfunction

" ---------------------------------------------------------------------------------------
" dirs
" ---------------------------------------------------------------------------------------

function! beryl#erlang#project_dirs()
    let l:libs = split(globpath('lib', '*'), '\n')
    let g:beryl_erlang_libs_copy = map(copy(l:libs), '"_build/default/" . v:val')
    let l:deps = filter(split(globpath('_build/default/lib', '*'), '\n'), 'index(g:beryl_erlang_libs_copy, v:val) == -1')
    return l:libs + l:deps
endfunction

function! beryl#erlang#otp_src_dirs()
    let l:dirs = []
	for lib in g:beryl_erlang_otp_libs
		call add(l:dirs, glob(g:beryl_erlang_otp_root . '/lib/' . l:lib . '-*') . '/src')
	endfor
    return l:dirs
endfunction

" ---------------------------------------------------------------------------------------
" erlang
" ---------------------------------------------------------------------------------------

function! beryl#erlang#eval(code, ...)
	let l:format = '~s'
	if a:0 > 0
		let l:format = a:1
	endif
	return system('erl -noshell -eval "io:format(\"' . l:format . '\", [' . escape(a:code, '"') . ']),halt()"')
endfunction

function! beryl#erlang#decompile()
	setlocal modifiable
	silent execute '%d'

	silent execute 'read !' . s:decompile_tool . ' ' . expand('%')

	silent execute '1d'
	setlocal nobin
	setlocal foldmarker=%\ {{{,%\ }}}
	setlocal foldmethod=marker
	setf beam
	setlocal syntax=erlang
	setlocal nomodifiable
endfunction

" ---------------------------------------------------------------------------------------
" tags actions
" ---------------------------------------------------------------------------------------

function! beryl#erlang#goto_tag()
    let tags = beryl#erlang#tag_under_cursor('taglist')
    if (l:tags != [])
        execute 'ta ' . l:tags[0].name
    endif
endfunction

" ---------------------------------------------------------------------------------------
" tags file
" ---------------------------------------------------------------------------------------

function! beryl#erlang#update_project_tagfile()
    if !filereadable(g:beryl_erlang_project_tagfile)
        silent execute '!' . s:tag_tool . ' -m create -f ' . g:beryl_erlang_project_tagfile
                    \ . ' ' . join(beryl#erlang#project_dirs(), ' ')
        redraw!
    else
        call system(s:tag_tool . ' -m update -f ' . g:beryl_erlang_project_tagfile . ' ' . expand('%'))
    endif
endfunction

function! beryl#erlang#create_otp_tagfile()
	if !filereadable(g:beryl_erlang_otp_tagfile) || confirm("OTP tag file " .
                \ g:beryl_erlang_otp_tagfile . " already exists, re-create it?", "&Yes\n&No", 1, "Q") == 1
        silent execute '!' . s:tag_tool . ' -m create -f ' . g:beryl_erlang_otp_tagfile . ' ' .
                    \ join(beryl#erlang#otp_src_dirs(), ' ')
        redraw!
	endif
endfunction

function! beryl#erlang#create_project_tagfile()
	if !filereadable(g:beryl_erlang_project_tagfile) || confirm("Project tag file " .
                \ g:beryl_erlang_project_tagfile . " already exists, re-create it?", "&Yes\n&No", 1, "Q") == 1
        silent execute '!' . s:tag_tool . ' -m create -f ' . g:beryl_erlang_project_tagfile . ' ' .
                    \ join(beryl#erlang#project_dirs(), ' ')
		redraw!
	endif
endfunction

" ---------------------------------------------------------------------------------------
" finding usages
" ---------------------------------------------------------------------------------------

function! beryl#erlang#find_usages()
    call beryl#task('finding usages...')
    if getline('.') =~? '^-define(' . expand('<cword>') . ','
        cgetexpr system('grep -nIw "?' . expand('<cword>') . '" -r lib')
        call beryl#quickfix_open('uses of ?' . expand(<cword>'))
    elseif getline('.') =~? '^-record(' . expand('<cword>') . ','
        cgetexpr system('grep -nI "#' . expand('<cword>') . '" -r lib')
        call beryl#quickfix_open('uses of #' . expand('<cword>') . '{}')
    elseif getline('.') =~? '^-type \+' . expand('<cword>') . ' *( *)'
        cgetexpr system('grep -nIw "' . expand('<cword>') . ' *( *)" -r lib')
        call beryl#quickfix_open('uses of type ' . expand('<cword>'))
    else
        let tags = beryl#erlang#tag_under_cursor('taglist')
        if len(l:tags) > 0
            if l:tags[0].kind == 'f'
                cgetexpr system(s:find_usages_tool . ' ' . l:tags[0].name)
                call beryl#quickfix_open('uses of ' . l:tags[0].name)
            elseif l:tags[0].kind == 'r' || l:tags[0].kind == 'd'
                let v = substitute(l:tags[0].name, '_:', '', '')
                cgetexpr system('grep -nI "' . l:v . '" -r lib')
                call beryl#quickfix_open('uses of ' . l:v)
            endif
        endif
    endif
    call beryl#task('')
endfunction

" ---------------------------------------------------------------------------------------
" selecting tag
" ---------------------------------------------------------------------------------------

function! beryl#erlang#list_tags()
    return beryl#tree#tags(split(system(s:tag_tool . ' -m list ' . expand('%')), '\n'))
endfunction

function! beryl#erlang#render_tag(item)
    return '  ' . a:item.name
endfunction

function! beryl#erlang#select_tag(tag)
    execute 'ta ' . a:tag.tag
endfunction

" ---------------------------------------------------------------------------------------
" getting current tag under cursor
" ---------------------------------------------------------------------------------------

function! beryl#erlang#tag_under_cursor(t)
	let [orig_pos, orig_iskeyword, module] = [getpos('.'), &iskeyword, expand('%:t:r')]

	" ----------------------- extract data from buffer --------------------
	set iskeyword+=:
	set iskeyword+=?
	set iskeyword+=#

	let raw = expand('<cword>')

	normal! w
	let after = getline('.')[col('.') - 1:]
	let arity_c = l:after =~# '(' ? s:arity_c() : ''
	let arity_r = l:after =~# '/' ? s:arity_r() : ''
	normal! bb
	if expand('<cword>') == '::' && l:raw =~# '^[a-z]'
		let l:raw = expand('<cword>') . l:raw
	endif
	call setpos('.', l:orig_pos)
	let &iskeyword = l:orig_iskeyword

	" ----------------------- work out tags -------------------------------
	if l:raw =~# '^?[^?]'
		return s:match(a:t, '?',   [l:module, '_'],           l:raw[1:], l:arity_c)
	elseif l:raw =~# '^#[^#]'
		return s:match(a:t, '#',   [l:module, '_'],           l:raw[1:], '')
	elseif l:raw =~# '^::[^:]' && l:arity_c != ''
		return s:match(a:t, '::',  [l:module, '_'],           l:raw[2:], l:arity_c)
	elseif l:arity_c != ''
		return s:match(a:t, '',    [l:module, '_', 'erlang'], l:raw,     l:arity_c)
	elseif l:arity_r != ''
		return s:match(a:t, '',    [l:module, '_'],           l:raw,     l:arity_r)
	else
		return []
	endif
endfunction

function! s:match(t, prefix, locations, raw, arity)
	if a:t == 'taglist'
		return s:taglist(a:prefix, a:locations, a:raw, a:arity)
	elseif a:t == 'target'
		return a:prefix . a:locations[0] . ':' . a:raw . a:arity
	endif
endfunction

function! s:taglist(prefix, locations, raw, arity)
	let parts = split(a:raw, ':')
	if (len(l:parts) == 1)
		return taglist('^' . escape(a:prefix . '(' . join(a:locations, '|') . '):' . a:raw . a:arity, '/(|)\'))
	elseif (len(l:parts) == 2)
		return taglist('^' . escape(a:prefix . a:raw . a:arity, '/(|)\'))
	else
		return []
	endif
endfunction

function! s:arity_r()
	return '/' . matchstr(getline('.')[col('.'):], '[0-9]\+')
endfunction

function! s:arity_c()
	let begin = getpos('.')
	normal! %
	let end = getpos('.')
	normal! %
	let content = 'f()->g' . substitute(s:substr(begin, end), '?[A-Za-z0-9_]*', 'blah', 'g') . '.'
	let tmpfile = tempname()
	call writefile([l:content], l:tmpfile)
    let arity = beryl#erlang#eval('begin {ok, [_,{_, _, _, _, [{_, _, _, _, [{_, _, _, X}]}]}|_]} = epp:parse_file("' . l:tmpfile . '", []), length(X) end', '~p')
	call delete(l:tmpfile)
	return '/' . l:arity
endfunction

function! s:get_ref_arity()
	return '/0'
endfunction

function! s:substr(begin, end)
	let lines = getline(a:begin[1], a:end[1])
	let lines[-1] = l:lines[-1][: a:end[2] - 1]
	let lines[0] = l:lines[0][a:begin[2] - 1:]
	return join(l:lines, "\n")
endfunction

" ---------------------------------------------------------------------------------------
" omni code completion
" ---------------------------------------------------------------------------------------

function! beryl#erlang#omnifunc(findstart, base)
    if a:findstart
        if exists('b:beryl_omni') || beryl#erlang#omni_update(1)
            let b:beryl_omni.start = col('.') - strlen(b:beryl_omni.base) - 1
            return b:beryl_omni.start
        else
            return -3
        endif
    else
        return b:beryl_omni.tags
    endif
endfunction

function! s:on_text_changed()
    if beryl#erlang#omni_update(0)
        if !pumvisible()
            call feedkeys("\<C-x>\<C-o>\<Down>", 'n')
        endif
    endif
endfunction

function! beryl#erlang#omni_update(manual)
    if mode() == 'i' && !exists('b:snip_state')
        let module = expand('%:t:r')
        let l:base = matchstr(strpart(getline('.'), 0, col('.') - 1), '[A-Za-z0-9_:]\+$')
        if l:base != ''
            if a:manual || strlen(l:base) > 1
                let l:tags = s:local_call_tags(taglist('^' . l:module . ':' . l:base))
                         \ + s:remote_call_tags(taglist('^' . l:base))
                if len(l:tags) > 0
                    let b:beryl_omni = {'base': base, 'col': col('.'), 'line': line('.'), 'tags': l:tags, 'resolve': 1}
                    return 1
                endif
            endif
        elseif strpart(getline('.'), col('.') - 2, 1) == '?'
            let l:tags = s:object_tags(taglist('^?' . l:module . ':'), 'd', '?')
                     \ + s:object_tags(taglist('^?_:'), 'd', '?')
            if len(l:tags) > 0
                let b:beryl_omni = {'base': '?', 'col': col('.'), 'line': line('.'), 'tags': l:tags, 'resolve': 0}
                return 1
            endif
        elseif strpart(getline('.'), col('.') - 2, 1) == '#'
            let l:tags = s:object_tags(taglist('^#' . l:module . ':'), 'r', '#')
                     \ + s:object_tags(taglist('^#_:'), 'r', '#')
            if len(l:tags) > 0
                let b:beryl_omni = {'base': '#', 'col': col('.'), 'line': line('.'), 'tags': l:tags, 'resolve': 0}
                return 1
            endif
        endif
    endif
    return 0
endfunction

function! s:local_call_tags(tags)
    let l:tags = []
    for tag in a:tags
        if tag.kind == 'f'
            let l:colon = stridx(tag.name, ':')
            if l:colon >= 0
                let l:fa = strpart(tag.name, l:colon + 1, len(tag.name) - l:colon - 1)
                let l:fs = strpart(l:fa, 0, stridx(l:fa, '/')) . tag.signature
                call add(l:tags, {'word': l:fs, 'kind': tag.kind})
            endif
        endif
    endfor
    return l:tags
endfunction

function! s:remote_call_tags(tags)
    let l:tags = []
    for tag in a:tags
        if tag.exported == 1 && tag.kind == 'f'
            let l:mfs = strpart(tag.name, 0, stridx(tag.name, '/')) . tag.signature
            call add(l:tags, {'word': l:mfs, 'kind': tag.kind})
        endif
    endfor
    return l:tags
endfunction

function! s:object_tags(tags, kind, prefix)
    let l:tags = []
    for tag in a:tags
        if tag.kind == a:kind
            let l:colon = stridx(tag.name, ':')
            if l:colon >= 0
                let l:macro = strpart(tag.name, l:colon + 1, len(tag.name) - 1)
                call add(l:tags, {'word': a:prefix . l:macro, 'kind': tag.kind})
            endif
        endif
    endfor
    return l:tags
endfunction

function! s:omni_complete_done()
    if mode() == 'i' && b:beryl_omni.resolve && b:beryl_omni.col != col('.') && b:beryl_omni.line == line('.')
        " call beryl#set_status(string(col('.')))
        call feedkeys("\<Esc>hv[(l\"aygv")
        call feedkeys("xi")
        call feedkeys("\<C-r>=beryl#erlang#snip_visual(@a)\<CR>", 'n')
    endif
    unlet b:beryl_omni
endfunction

function! s:omni_tag(s)
    if a:s.kind == 'f'
        if a:s.exported == 1
            return {'word': strpart(a:s.name, 0, stridx(a:s.name, '/')) . a:s.signature, 'kind': a:s.kind}
        endif
    endif
    return {}
endfunction

function! beryl#erlang#snip_visual(s)
    let l:template = ''
    let l:c = 1
    for a in split(strpart(a:s, 0, len(a:s)), ',')
        if l:template != ''
            let l:template .= ', '
        endif
        let l:template .= '${' . c . ':' . substitute(a, '\v^\s*([^ ]+)\s*$', '\1', '') . '}'
        let l:c += 1
    endfor
    return snipMate#expandSnip(l:template, 0, col('.'))
endfunction

inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"
inoremap <expr> <C-e> pumvisible() ? "\<Esc>\<Esc>" : "\<C-e>"
imap <expr> <Tab> pumvisible() ? "\<Down>" : (beryl#erlang#omni_update(1) ? "\<C-x>\<C-o>\<Down>" : "\<Tab>")
"autocmd TextChangedI * call s:on_text_changed()
autocmd CompleteDone * call s:omni_complete_done()
inoremap <C-d> <C-r>=(exists('b:snip_state') ? string(b:snip_state) : {})<CR>
snoremap <C-d> <C-r>=(exists('b:snip_state') ? string(b:snip_state) : {})<CR>


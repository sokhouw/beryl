" beryl-select/autoload/beryl_select.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl_select")
    finish
endif
let g:autoload_beryl_select = 1

" -------------------------------------------------------------------------------------
" plugin
" -------------------------------------------------------------------------------------

function! beryl#select#configure(mode, handler)
    let g:beryl_select_modes[a:mode] = copy(a:handler)
    let g:beryl_select_modes[a:mode].mode = a:mode
endfunction

function! beryl#select#open(mode, ...)
    if has_key(g:beryl_select_modes[a:mode], 'on_list')
        let items = {g:beryl_select_modes[a:mode].on_list}()
    elseif a:0 > 1
        let items = a:2
    else
        echohl Error
        echom 'beryl#select#open failed: ' . a:0
        echom string(a:2)
        echohl None
        return
    endif

    if len(l:items) == 0 | return | endif
    call beryl#quickfix_close()
    let l:bufnr = bufnr('%')
    let l:pos = getpos('.')
    let w:dest = 1
    silent below new
    silent setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nonu cursorline filetype=files
    let l:context = copy(g:beryl_select_modes[a:mode])
    let l:context.pos = l:pos
    let l:context.file_bufnr = l:bufnr
    let l:context.this_bufnr = bufnr('%')
    let l:context.total_count = len(l:items)
    let l:context.filter = []
    let l:context.filter_str = ''
    let l:context.filtered_count = len(l:items)
    let l:context.items = l:items
    setlocal modifiable noreadonly
    silent execute '%d'
    for l:item in l:items
        let l:item.line = line('$')
        call append(line('$'), {l:context.render}(l:item))
    endfor
    silent execute '1d'
    silent setlocal readonly nomodifiable
    silent execute "resize " . min([line("$"), g:beryl_select_max_height])
    call s:loop(l:context)
    windo if exists('w:dest') | unlet w:dest | endif
endfunction

" -------------------------------------------------------------------------------------
" API - selecting buffer
" -------------------------------------------------------------------------------------

function! beryl#select#list_buffers()
    redir => l:result
    silent execute "files"
    redir END
    let l:items = []
    let l:index = 0
    for s in split(l:result, "\n")
        let l:item = {
            \ 'name':    (split(strpart(s, 9), "\""))[0],
            \ 'modified':    strpart(s, 7, 1) == '+',
            \ 'bufnr':    str2nr(strpart(s, 0, 3))}
        let l:items = l:items + [l:item]
    endfor
    return l:items
endfunction

function! beryl#select#open_buffer(item)
    silent execute 'b ' . a:item.bufnr
endfunction

function! beryl#select#delete_buffer(context, item)
    setlocal modifiable noreadonly
    silent execute "d"
    let a:context.items = filter(a:context.items, 'v:val.bufnr != '. a:item.bufnr)
    let l:next = s:find(a:context)
    if len(a:context.items) > 0
        windo if exists('w:dest') && bufname('%') == a:item.name | execute 'b ' . l:next.bufnr | endif
        silent setlocal nomodifiable readonly
        silent execute 'resize ' . min([line("$"), g:beryl_select_max_height])
        silent execute 'bw ' . a:item.bufnr
        return 1
    else
        silent execute 'bw ' . a:context.this_bufnr
        silent execute 'bw ' . a:item.bufnr
        redraw!
        return 0
    endif
endfunction

call beryl#select#configure('buffers', {
            \ 'on_list': 'beryl#select#list_buffers',
            \ 'on_select': 'beryl#select#open_buffer',
            \ 'on_delete': 'beryl#select#delete_buffer',
            \ 'render': 'beryl#select#render_file',
            \ 'access_key': g:beryl_select_buffer_key})

" -------------------------------------------------------------------------------------
" API - selecting file
" -------------------------------------------------------------------------------------

function! beryl#select#list_files()
    if exists('g:beryl_select_files_ignore')
        let l:filters = deepcopy(g:beryl_select_files_ignore)
    else
        let l:filters = []
    endif
    if (!g:beryl_select_hidden_files)
        let l:filters = l:filters + ['^\\.', '/\\.']
    endif
    let l:postprocess = ' | cut -c 3- | grep -ve "' . join(l:filters, '\|') . '" | sort'
    let l:cmd = 'LC_COLLATE=C find -L -type f' . l:postprocess
    let l:items = map(split(system(l:cmd), '\n'), "{'name': v:val, 'modified': 0}")
    return l:items
endfunction

function! beryl#select#open_file(item)
    silent execute 'badd ' . a:item.name
    silent execute 'b ' . a:item.name
endfunction

function! beryl#select#render_file(item)
    return (a:item.modified ? '+' : ' ') . ' ' . a:item.name
endfunction

call beryl#select#configure('files', {
            \ 'on_list': 'beryl#select#list_files',
            \ 'on_select': 'beryl#select#open_file',
            \ 'render': 'beryl#select#render_file',
            \ 'access_key': g:beryl_select_file_key})

" -------------------------------------------------------------------------------------
" choosing tag from taglist
" -------------------------------------------------------------------------------------

function beryl#select#render_tag(item)
    return '  ' . a:item.name
endfunction

call beryl#select#configure('taglist', {
            \ 'on_select': 'beryl#select#goto_tag',
            \ 'render': 'bery_select#render_tag'})

" -------------------------------------------------------------------------------------
" selecting colorscheme
" -------------------------------------------------------------------------------------

function! beryl#select#list_colorschemes()
    let l:items = []
    for l:path in split(globpath(&rtp, "colors/*.vim"), '\n')
        let name = fnamemodify(l:path, ':t:r')
        call add(l:items, {'name': l:name})
    endfor
    return l:items
endfunction

function! beryl#select#select_colorscheme(item)
    silent execute 'colorscheme ' . a:item.name
endfunction

function! beryl#select#render_colorscheme(item)
    return ' oko ' . a:item.name
endfunction

call beryl#select#configure('colorschemes', {
            \ 'on_list': 'beryl#select#list_colorschemes',
            \ 'on_select': 'beryl#select#select_colorscheme',
            \ 'render': 'beryl#select#render_colorscheme'})

" -------------------------------------------------------------------------------------
" event loop
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
            return
        elseif l:char is# "\<ESC>" || has_key(a:context, 'access_key') && type(l:code) == type(0) &&
                    \ eval('nr2char(' . l:code . ') is# "\' . a:context.access_key . '"')
            call s:close(a:context)
            redraw!
            return
        elseif l:code is# "\<DEL>"
            let l:item = s:find(a:context)
            if a:context.on_delete != ''
                if !{a:context.on_delete}(a:context, l:item)
                    return
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
endfunction

function! s:find(context)
    let l:line = line('.')
    for l:item in a:context.items
        if l:line == l:item.line
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
            let l:item.line = line('$')
            call append(line('$'), {a:context.render}(l:item))
            let a:context.filtered_count += 1
        else
            let l:item.line = -1
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
    silent execute "resize " . min([line("$"), g:beryl_select_max_height])
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


" beryl-select/autoload/beryl_tree.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl_tree")
    finish
endif
let g:autoload_beryl_tree = 1

if g:beryl_tree_open_on_startup
    call beryl#tree#toggle('files')
endif

let s:state = {}
let s:modes = {}

" -------------------------------------------------------------------------------------
" API
" -------------------------------------------------------------------------------------

function! beryl#tree#register(name, mode)
    let s:modes[a:name] = a:mode
endfunction

function! beryl#tree#toggle(name)
    let l:name = get(s:state, 'name', '')
    if l:name == a:name
        call s:close()
    elseif l:name != ''
        call s:close()
        call s:open(a:name)
    elseif l:name == ''
        call s:open(a:name)
    endif
endfunction

function! beryl#tree#tags(tags)
    let l:tags = []
    for s in a:tags
        let l:parts = split(s, "\t")
        if len(l:parts) >= 4
            call add(l:tags, {
                        \ 'name':   l:parts[0],
                        \ 'path':   l:parts[1],
                        \ 'line':   l:parts[2],
                        \ 'column': 1,
                        \ 'class':  s:class(l:parts[3]),
                        \ 'descr':  l:parts[0]})
        endif
    endfor
    return l:tags
endfunction

function! s:class(kind)
    if a:kind == 'd' | return 'Definitions' | endif
    if a:kind == 'i' | return 'Imports' | endif
    if a:kind == 'f' | return 'Functions' | endif
    if a:kind == 'm' | return 'Methods' | endif
    if a:kind == 't' | return 'Types' | endif
    if a:kind == 'v' | return 'Variable' | endif
    return 'Unknown'
endfunction

" -------------------------------------------------------------------------------------
" Internals - open/close/tree
" -------------------------------------------------------------------------------------

function! s:open(name)
    let s:state = {s:modes[a:name].load}()

    execute 'silent botright vnew +setf\ tree ' . fnamemodify('.', ':p')
    silent execute 'vertical resize ' . g:beryl_tree_max_width

    let s:state.bufnr = bufnr('%')

    let s:state.name = a:name
    let s:state.mode = s:modes[a:name]
    if len(get(s:state.root, 'dirs', [])) > 0 || len(get(s:state.root, 'files', [])) > 0
        let s:state.index = 1
    else
        let s:state.index = 0
    endif

    autocmd CursorMoved,CursorMovedI <buffer> call beryl#tree#on_moved()

    nmap <silent> <buffer> <Left> :call beryl#tree#on_left()<CR>
    nmap <silent> <buffer> <Right> :call beryl#tree#on_right()<CR>
    nmap <silent> <buffer> <S-Tab> :call beryl#tree#on_page('up')<CR>
    nmap <silent> <buffer> <Tab> :call beryl#tree#on_page('down')<CR>
    nmap <silent> <buffer> <Enter> :call beryl#tree#on_enter()<CR>

    silent setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nonu cursorline filetype=tree tabstop=1

    call s:render_tree()
endfunction

function! s:close()
    execute 'bwipe ' . s:state.bufnr
    let s:mode = {}
    let s:state = {}
endfunction

function! s:pull_up(node)
    if has_key(a:node, 'dirs')
        call s:pull_up_dirs(a:node)
        if len(a:node.dirs) == 1 && len(a:node.files) == 0
            let l:child = a:node.dirs[0]
            let a:node.name .= l:child.name
            let a:node.path .= l:child.name
            let a:node.dirs = l:child.dirs
            let a:node.files = l:child.files
        endif
    endif
endfunction

function! s:pull_up_dirs(node)
    for node in get(a:node, 'dirs', [])
        call s:pull_up(node)
    endfor
endfunction

" -------------------------------------------------------------------------------------
" Internals - rendering
" -------------------------------------------------------------------------------------

function! s:render_tree()
    let s:state.rendered = []
    silent execute '%d'
    if !get(s:state.root, 'is_hidden', 0)
        call s:render_root()
    endif
    call s:render_children(s:state.root, 1)
    if get(s:state.root, 'is_hidden', 0)
        silent execute '1d'
    endif
    call s:update_pos()
    redraw!
endfunction

function! s:render_root()
    if !get(s:state.root, 'hidden', 0)
        call setline(1, "\t" . s:state.root.name)
        call add(s:state.rendered, s:state.root)
    else
        silent execute '1d'
    endif
endfunction

function! s:render_item(node, level)
    call add(s:state.rendered, a:node)
    let l:hidden = a:node.name[0] == '.'
    if has_key(a:node, 'is_folded')
        " dir
        if len(get(a:node, 'dirs', [])) != 0 || len(get(a:node, 'files', [])) != 0
            " ... non-empty
            if a:node.is_folded
                " ... folded
                if get(a:node, 'contains_loaded', 0)
                    " ... contains loaded
                    let l:mark = g:beryl_tree_theme['#']
                else
                    " ... doesn't contain loaded
                    let l:mark = g:beryl_tree_theme['+']
                endif
            else
                " ... unfolded
                if get(a:node, 'contains_loaded', 0)
                    " ... contains loaded
                    let l:mark = g:beryl_tree_theme['=']
                else
                    " ... doesn't contain loaded
                    let l:mark = g:beryl_tree_theme['-']
                endif
            endif
        else
            " empty
            let l:mark = g:beryl_tree_theme[' ']
        endif
        call append(line('$'), repeat(' ', 2 * a:level - 1) . l:mark . a:node.name . "\t")
        call s:render_children(a:node, a:level + 1)
    else
        if get(a:node, 'is_loaded', 0)
            let l:mark = g:beryl_tree_theme['*']
        else
            let l:mark = ''
        endif
        call append(line('$'),  repeat(' ', 2 * a:level + 1) . l:mark . a:node.name)
    endif
endfunction

function! s:render_children(node, level)
    if !get(a:node, 'is_folded', 0)
        for child in get(a:node, 'dirs', [])
            call s:render_item(child, a:level)
        endfor
        for child in get(a:node, 'files', [])
            call s:render_item(child, a:level)
        endfor
    endif
endfunction

function! s:update_pos()
    call setpos('.', [s:state.bufnr, s:state.index + 1, 1])
    redraw!
endfunction

function! s:prun(side, text, width)
    if strlen(a:text) > a:width
        if a:side == 'left'
            return '..' . eval('"' . a:text . '"[-' . (a:width - 2) . ':]')
        endif
    endif
endfunction

" -------------------------------------------------------------------------------------
" Event handlers
" -------------------------------------------------------------------------------------

function! beryl#tree#on_moved()
    let s:state.index = line('.') - 1
    call setpos('.', [s:state.bufnr, line('.'), 1])
endfunction

function! beryl#tree#on_up()
    if s:state.index > 0
        let s:state.index -= 1
        call s:update_pos()
    endif
endfunction

function! beryl#tree#on_down()
    if s:state.index + 1 < len(s:state.rendered)
        let s:state.index += 1
        call s:update_pos()
    endif
endfunction

function! beryl#tree#on_left()
    let l:item = s:state.rendered[s:state.index]
    if has_key(l:item, 'is_folded')
        if !l:item.is_folded
            let l:item.is_folded = 1
            call s:render_tree()
        else
            call beryl#tree#on_up()
        endif
    endif
endfunction

function! beryl#tree#on_right()
    let l:item = s:state.rendered[s:state.index]
    if has_key(l:item, 'is_folded')
        if l:item.is_folded
            let l:item.is_folded = 0
            call s:render_tree()
        else
            call beryl#tree#on_down()
        endif
    endif
endfunction

function! beryl#tree#on_page(direction)
    let l:index = s:state.index
    while 1
        if a:direction == 'up'
            let l:index -= 1
            if l:index < 0
                let l:index = len(s:state.rendered) - 1
            endif
        elseif a:direction == 'down'
            let l:index += 1
            if l:index >= len(s:state.rendered)
                let l:index = 0
            endif
        endif
        if l:index == s:state.index
            return
        endif
        let l:item = s:state.rendered[l:index]
        if has_key(l:item, 'is_folded') && !get(l:item, 'is_root', 0) && (len(get(l:item, 'dirs', [])) > 0 || len(get(l:item, 'files', [])) > 0)
            let s:state.index = l:index
            call s:update_pos()
            break
        endif
    endwhile
endfunction

function! beryl#tree#on_enter()
    let l:item = s:state.rendered[s:state.index]
    if l:item.name != '.'
        if has_key(l:item, 'is_folded') && (len(get(l:item, 'dirs', [])) > 0 || len(get(l:item, 'files', [])) > 0)
            if l:item.is_folded
                let l:item.is_folded = 0
                call s:render_tree()
                call beryl#tree#on_down()
                call s:update_pos()
            else
                let l:item.is_folded = 1
                call s:render_tree()
                call s:update_pos()
            endif
        else
            let l:state = s:state
            call s:close()
            call {l:state.mode.select}(l:state, l:item)
        endif
    endif
endfunction


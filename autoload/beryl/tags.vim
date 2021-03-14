" beryl-select/autoload/beryl_ags.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl_tags")
    finish
endif
let g:autoload_beryl_tags = 1

" -------------------------------------------------------------------------------------
" API - tree
" -------------------------------------------------------------------------------------

function! beryl#tags#init()
    call beryl#tree#register('tags', {'load': 'beryl#tags#load', 'select': 'beryl#tags#select'})
endfunction

function! beryl#tags#load()
    if has_key(b:, 'beryl_list_tags')
        let l:tags = {b:beryl_list_tags}()
        let l:lookup = {}
        let l:state = {'root': {'name': expand('%'), 'path': expand('%'), 'is_root': 1, 'is_folded': 0, 'dirs': []}, 'target_bufnr': bufnr('%')}
        for tag in l:tags
            let l:parent = get(l:lookup, tag.class, {})
            if l:parent == {}
                let l:parent = {'path': tag.class, 'name': tag.class, 'is_folded': 0, 'files': []}
                let l:lookup[tag.class] = l:parent
                call add(l:state.root.dirs, l:parent)
            endif
            call add(l:parent.files, l:tag)
        endfor
        return l:state
    endif
endfunction

function! beryl#tags#select(state, item)
    execute 'b ' . a:state.target_bufnr
    call setpos('.', [a:state.target_bufnr, a:item.line, a:item.column])
endfunction

" -------------------------------------------------------------------------------------
" API - goto
" -------------------------------------------------------------------------------------

" function! beryl#tags#goto()
"     let l:tags_tool = get(b:, 'beryl_tags_tool', '')
"     let l:result = split(system(l:tags_tool . ' --goto ' . expand('<cword>')), "\n")
"     let l:tags = []
"     if len(l:result) == 1
"         let l:parts = split(s, "\t")
"         let l:path = l:parts[1]
"         let l:line = l:parts[2]

"        endif
"     endfor
"     if len(l:tags) == 1
"         let l:tag = l:tags[0]
"         execute 'badd ' . l:tag.path
"         execute 'b ' . l:tag.path
"         call setpos('.', [bufnr(l:tag.path), l:tag.line, l:tag.column])
"     elseif len(l:tags) > 1
"         echo 'too many tags'
"     else
"         echo 'not found'
"     endif
" endfunction


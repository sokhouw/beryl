" beryl-select/autoload/beryl_tree.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl_buffers")
    finish
endif
let g:autoload_beryl_buffers = 1

" -------------------------------------------------------------------------------------
" API - tree
" -------------------------------------------------------------------------------------

function! beryl#buffers#init()
    call beryl#tree#register('buffers', {'load': 'beryl#buffers#load', 'select': 'beryl#buffers#select'})
endfunction

function! beryl#buffers#load()
    let l:state = {'root': {'name': 'buffers' . "\t", 'is_root': 1, 'is_folded': 0, 'dirs': [], 'files': []}}
    let l:lookup = {'.': l:state.root}

    redir => l:result
    silent execute "files"
    redir END

    for s in split(l:result, "\n")
        let l:path = (split(strpart(s, 9), "\""))[0]
        let l:item = {'path': l:path, 'name': fnamemodify(l:path, ':t'), 'parent': l:state.root}
        call add(l:state.root.files, l:item)
    endfor

    return l:state
endfunction

function! beryl#buffers#select(state, item)
    execute 'b ' . a:item.path
endfunction


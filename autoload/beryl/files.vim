" beryl-select/autoload/beryl_tree.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl_files")
    finish
endif
let g:autoload_files_tree = 1

" -------------------------------------------------------------------------------------
" API - tree
" -------------------------------------------------------------------------------------

function! beryl#files#init()
    call beryl#tree#register('files', {'load': 'beryl#files#load', 'select': 'beryl#files#select'})
endfunction

function! beryl#files#load()
    if exists('g:beryl_tree_files_ignore')
        let l:filters = deepcopy(g:beryl_tree_files_ignore)
    else
        let l:filters = []
    endif
    if (!g:beryl_tree_hidden_files)
        let l:filters = l:filters + ['^\\.', '/\\.', '^\.$']
    endif

    let l:postprocess = '| grep -ve "' . join(l:filters, '\|') . '" | sort'
    let l:dirs_cmd = 'LC_COLLATE=C find -L -type d ' . l:postprocess
    let l:files_cmd = 'LC_COLLATE=C find -L -type f ' . l:postprocess

    let l:state = {'root': {'name': '..', 'path': fnamemodify('.', ':p'), 'is_root': 1, 'is_folded': 0, 'dirs': [], 'files': []}}
    let l:lookup = {'.': l:state.root}

    for path in split(system(l:dirs_cmd))
        if (path != '.')
            let l:parent = l:lookup[fnamemodify(path, ':h')]
            let l:item = {'name': fnamemodify(path, ':t') . "/", 'path': path[2:], 'parent': l:parent, 'is_folded': 1, 'dirs': [], 'files': []}
            let l:lookup[path] = l:item
            call add(l:parent.dirs, l:item)
        endif
    endfor
    for path in split(system(l:files_cmd))
        let l:parent = l:lookup[fnamemodify(path, ':h')]
        let l:is_loaded = bufexists(path[2:])
        let l:item = {'name': fnamemodify(path, ':t'), 'path': path[2:], 'parent': l:parent, 'is_loaded': l:is_loaded}
        call add(l:parent.files, l:item)
        if l:is_loaded && !get(l:parent, 'contains_loaded', 0)
            while 1
                let l:parent.contains_loaded = 1
                if has_key(l:parent, 'parent')
                    let l:parent = l:parent.parent
                else
                    break
                endif
            endwhile
        endif
    endfor
    return l:state
endfunction

function! beryl#files#select(state, item)
    execute 'badd ' . a:item.path
    execute 'b ' . a:item.path
endfunction


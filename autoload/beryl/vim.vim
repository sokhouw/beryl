" autoload/beryl_vim.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl_vim")
	finish
endif
let g:autoload_beryl_vim = 1

let s:tags_tool = g:beryl_root . '/tools/vim/tags_tool.sh'

" ---------------------------------------------------------------------------------------
" init
" ---------------------------------------------------------------------------------------

function! beryl#vim#init()
    if g:beryl_layout == 'vim-plugin'
        call s:update_tags_file()
    endif
endfunction

" ---------------------------------------------------------------------------------------
" event handlers
" ---------------------------------------------------------------------------------------

function! beryl#vim#after_save()
    if g:beryl_layout == 'vim-plugin'
        call s:update_tags_file()
    endif
endfunction

" ---------------------------------------------------------------------------------------
" tags
" ---------------------------------------------------------------------------------------

function! beryl#vim#list_tags()
    let l:tags = []
    let l:result = split(system(s:tags_tool . ' --list_tags ' . expand('%')), "\n")
    for s in l:result
        let l:parts = split(s, "\t")
        call add(l:tags, {
                    \ 'name':   l:parts[0],
                    \ 'path':   l:parts[1],
                    \ 'line':   l:parts[2],
                    \ 'column': 1,
                    \ 'class':  s:class(l:parts[3], l:parts[0]),
                    \ 'descr':  l:parts[4]})
    endfor
    return l:tags
endfunction

function! s:update_tags_file()
    call system(s:tags_tool . ' --ctags > .tags')
endfunction

function! s:class(kind, name)
    if a:kind == 'f' | return 'Functions' | endif
    if a:kind == 'v' | return 'Variables' | endif
    return 'Unknown'
endfunction


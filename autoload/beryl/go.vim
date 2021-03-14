" autoload/beryl_go.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_beryl_go")
	finish
endif
let g:autoload_beryl_go = 1

let s:tags_tool = 'go run ' . g:beryl_root . '/tools/go/tags_tool.go'
let s:format_tool = 'go fmt'
let s:compile_tool = 'go build -o /dev/null 2>&1'


function! beryl#go#init()
    " command! BerylRootTags call beryl#go#create_root_tagfile()
    " command! BerylTags call beryl#go#update_tagfile()
    "call s:update_tags_file()
endfunction

" ---------------------------------------------------------------------------------------
" event handlers
" ---------------------------------------------------------------------------------------

function! beryl#go#after_save()
    call beryl#task('formatting...')
    call s:format()
    call beryl#task('updating tags...')
    "call s:update_tags_file()
    call beryl#task('compiling...')
    call s:compile()
    call beryl#task('')
endfunction

" ---------------------------------------------------------------------------------------
" tags
" ---------------------------------------------------------------------------------------

function! beryl#go#goto_tag()
    let l:offset = line2byte(line('.')) + col('.') - 1
    let l:tag = system(s:tags_tool . ' find ' . expand('%') . ' ' . l:offset)
    execute 'ta ' . l:tag

    " let tags = beryl#erlang#tag_under_cursor('taglist')
    " if (l:tags != [])
    "     execute 'ta ' . l:tags[0].name
    " endif
endfunction

function! beryl#go#create_root_tagfile()
    execute '!find ${GOPATH}/src -name "*.go" | grep -v "cmd\|debug\|internal\|runtime\|syscall\|test\|vendor" | gotags -L - -tag-relative -f ${GOPATH}/src/.tags'
endfunction

function! beryl#go#list_tags()
    return beryl#tree#tags(split(system(s:tags_tool . ' list ' . expand('%')), "\n"))
endfunction

function! s:update_tags_file()
    silent execute '!' . s:tag_tool . ' ' . g:beryl_go_project_tagfile . ' .'
endfunction

" ---------------------------------------------------------------------------------------
" Internals
" ---------------------------------------------------------------------------------------

function! s:format()
    silent execute '!' . s:format_tool . ' ' . expand('%')
    let l:view = winsaveview()
	silent execute '%!cat ' . expand('%')
    set nomodified
    call winrestview(l:view)
endfunction

function! s:compile()
    silent cgetexpr system(s:compile_tool . ' ' . expand('%:h') . '/*.go')
	let [b:errors, b:warnings] = [0, 0]
	for l:v in getqflist()
		let b:errors += l:v.type == 'E'
		let b:warnings += l:v.type == 'W'
	endfor
    call beryl#quickfix_open(expand('%') . ' - compilation report')
endfunction

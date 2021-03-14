" beryl-select/autoload/FILENAME.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("g:autoload_FILENAME")
	finish
endif
let g:autoload_FILENAME = 1

" " ---------------------------------------------------------------------------------------
" " quickfix & location list
" " ---------------------------------------------------------------------------------------

" " ---------------------------------------------------------------------------------------
" " location list
" " ---------------------------------------------------------------------------------------

" function FILENAME#ll_toggle()
" 	let l:ll = 0
" 	windo if &l:buftype == 'location' | let l:ll = 1 | endif
" 	if l:ll == 1
" 		lcl
" 	else
"         try
"     		silent execute 'lopen ' . s:ll_height()
"         catch 'E776:.*'
"             echom 'No location list'
"         endtry
" 	endif
" endfunction

" function! s:ll_height()
"     return min([g:beryl_loclist_max_height, max([1, len(getloclist(0))])])
" endfunction


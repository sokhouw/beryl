" beryl/after/plugin/beryl.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists('g:after_beryl')
	finish
endif
let g:after_beryl = 1

" ---------------------------------------------------------------------------------------
"  Initialization
" ---------------------------------------------------------------------------------------

call beryl#autodetect()
call beryl#init()


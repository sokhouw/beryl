" plugin/beryl_go.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists('g:plugin_beryl_go')
	finish
endif
let g:plugin_beryl_go = 1

" -------------------------------------------------------------------------------------
" global variables
" -------------------------------------------------------------------------------------

if !exists('g:beryl_go_root')
    let g:beryl_go_root = $GOPATH
endif

if !exists('beryl_go_root_tagfile')
    let g:beryl_go_root_tagfile = g:beryl_go_root . '/src/.tags'
endif

if !exists('g:beryl_go_project_tagfile')
    let g:beryl_go_project_tagfile = '.tags'
endif

" -------------------------------------------------------------------------------------
" layout
" -------------------------------------------------------------------------------------

if isdirectory('cmd') && len(globpath('cmd', '**/*.go')) > 0
    let g:beryl_layout = 'go-go'
    call beryl#go#init()
endif


" plugin/beryl_vim.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists('g:plugin_beryl_vim')
	finish
endif
let g:plugin_beryl_vim = 1

" -------------------------------------------------------------------------------------
" layout
" -------------------------------------------------------------------------------------

if isdirectory('autoload') || isdirectory('ftdetect') || isdirectory('ftplugin') || isdirectory('plugin')
    if len(globpath('autoload', '*.vim')) > 0
                \ || len(globpath('ftdetect', '*.vim')) > 0
                \ || len(globpath('ftplugin', '*.vim')) > 0
                \ || len(globpath('plugin', '*.vim')) > 0
        let g:beryl_layout = 'vim-plugin'
        call beryl#vim#init()
    endif
endif


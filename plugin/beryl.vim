" beryl/plugin/beryl.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists('g:plugin_beryl')
	finish
endif
let g:plugin_beryl = 1

" ---------------------------------------------------------------------------------------
" helpers
" ---------------------------------------------------------------------------------------

function! s:set_key_mapping(var, default, command)
    let l:key = a:default
    if exists(a:var)
        let l:key = a:var
    else
        execute 'let ' . a:var . ' = "' . a:default '"'
    endif
    execute 'nnoremap <silent> ' . l:key . ' :' . a:command . '<CR>'
   	execute 'inoremap <silent> ' . l:key . ' <ESC>:' . a:command . '<CR>'
endfunction

function! s:set_default(var, default) 
    if !exists(a:var)
        if type(a:default) == type('')
            let l:value = "'" . a:default . "'"
        else
            let l:value = a:default
        endif
        execute 'let ' . a:var . ' = ' . l:value
    endif
endfunction

" ---------------------------------------------------------------------------------------
" global variables
" ---------------------------------------------------------------------------------------

sign define beryl_select_no_entries text== texthl=Error

" location of the beryl plugin
let g:beryl_root 			    = expand('<sfile>:p:h:h')

let g:beryl_project_tagfile		= getcwd() . '/.beryl/project.tags'

command! BerylToggleQF          call beryl#qf_toggle()
command! BerylToggleLL          call beryl#ll_toggle()
command! BerylFindUsages        call beryl#find_usages()
command! BerylSelectFile        call beryl_select#open('files')
command! BerylSelectBuffer      call beryl_select#open('buffers')
command! BerylSelectTemplate    call beryl_select#open('templates')
command! BerylSelectColorscheme call beryl_select#open('colorschemes')

" ---------------------------------------------------------------------------------------
" project configuration 
" ---------------------------------------------------------------------------------------

function! beryl#oko()
    let l:lang = 'erlang'
    let l:type = 'module'
    let l:snippet = values(values(snipMate#GetSnippets([l:lang], l:type))[0])[0]
    enew
    execute 'set ft=' . l:lang
    call snipMate#expandSnip(l:snippet[0], l:snippet[1], 1)
	call cursor(1, 1)

endfunction

call s:set_key_mapping('g:beryl_qf_toggle_key',         '<C-\>', 'BerylToggleQF')
call s:set_key_mapping('g:beryl_ll_toggle_key',         '<C-l>', 'BerylToggleLL')
call s:set_key_mapping('g:beryl_find_usages_key',       '<C-_>', 'BerylFindUsages')
call s:set_key_mapping('g:beryl_select_buffer_key',     '<C-f>', 'BerylSelectBuffer')
call s:set_key_mapping('g:beryl_select_file_key',       '<C-o>', 'BerylSelectFile')
call s:set_key_mapping('g:beryl_select_template_key',   '<C-n>', 'BerylSelectTemplate')

call s:set_default('g:beryl_quickfix_open',         'on-errors')
call s:set_default('g:beryl_quickfix_max_height',   16)
call s:set_default('g:beryl_quickfix_highlight',    1)
call s:set_default('g:beryl_loclist_max_height',    16)
call s:set_default('g:beryl_loclist_highlight',     1)
call s:set_default('g:beryl_select_hidden_files',   0)
call s:set_default('g:beryl_select_max_size',       10)
call s:set_default('g:beryl_colorscheme',           'beryl_distinguished')

hi! berylQFError ctermbg=052
hi! berylQFWarning ctermbg=094

highlight link BerylTemplatesPlaceholders Search
highlight link BerylTemplatesCurrentPlaceholder Visual

" -------------------------------------------------------------------------------------
" set up select window modes
" -------------------------------------------------------------------------------------

" if exists('g:beryl_templates_snippet_key')
"  	execute 'nnoremap <silent> ' . g:beryl_templates_snippet_key . ' :BerylTemplatesSnippet<CR>'
"  	execute 'inoremap <silent> ' . g:beryl_templates_snippet_key . ' <Esc>:BerylTemplatesSnippet<CR>'
"	execute 'vnoremap <silent> ' . g:beryl_templates_snippet_key . ' :call beryl_select#open("templates_snippet_visual")<CR>'
" endif

call beryl_select#configure('files',      
			\ 'beryl_select#list_files',         
			\ 'beryl_select#open_file',
            \ g:beryl_select_file_key)

call beryl_select#configure('buffers',     
			\ 'beryl_select#list_buffers',       
			\ 'beryl_select#open_buffer',
            \ g:beryl_select_buffer_key)

call beryl_select#configure('colorschemes', 
			\ 'beryl_select#list_colorschemes', 
			\ 'beryl_select#select_colorscheme',
            \ '')

call beryl_select#configure('templates',    
			\ 'beryl_select#list_templates',
			\ 'beryl_select#new_file_from_template',
            \ g:beryl_select_template_key)


" beryl/plugin/beryl.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists('g:plugin_beryl')
	finish
endif
let g:plugin_beryl = 1

" ---------------------------------------------------------------------------------------
" global variables
" ---------------------------------------------------------------------------------------

" location of the beryl plugin
let g:beryl_root 			= expand('<sfile>:p:h:h')

let g:beryl_project_tagfile		= getcwd() . '/.beryl/project.tags'

command! BerylToggleQuickfix call beryl#qftoggle()

command! BerylFindUsages call beryl#find_usages()

" ---------------------------------------------------------------------------------------
" project configuration 
" ---------------------------------------------------------------------------------------

if !exists('g:beryl_quickfix_open')
	let g:beryl_quickfix_open	= 'on-errors'
endif

if !exists('g:beryl_quickfix_max_height')
	let g:beryl_quickfix_max_height	= 16
endif

if !exists('g:beryl_quickfix_highlight')
	let g:beryl_quickfix_highlight	= 1
endif

hi! berylQFError ctermbg=052
hi! berylQFWarning ctermbg=094

" colorscheme can be auto-selected for projects under beryl's control
if !exists('g:beryl_colorscheme')
	let g:beryl_colorscheme		= 'beryl_distinguished'
endif

if exists('g:beryl_quickfix_toggle_key')
	execute 'nnoremap <silent> ' . g:beryl_quickfix_toggle_key . ' :BerylToggleQuickfix<CR>'
	execute 'inoremap <silent> ' . g:beryl_quickfix_toggle_key . ' <ESC>:BerylToggleQuickfix<CR>'
endif

if exists('g:beryl_find_usages_key')
    execute 'nnoremap <silent> ' . g:beryl_find_usages_key . ' :BerylFindUsages<CR>'
    execute 'inoremap <silent> ' . g:beryl_find_usages_key . ' <ESC>:BerylFindUsages<CR>'
endif

" ---------------------------------------------------------------------------------------
" select
" ---------------------------------------------------------------------------------------

if !exists('g:beryl_select_ignore')
    let g:beryl_select_ignore = []
endif

sign define beryl_select_no_entries text== texthl=Error

command! BerylSelectFile call beryl_select#open('files')
command! BerylSelectBuffer call beryl_select#open('buffers')
command! BerylSelectQuickfix call beryl_select#open('quickfix')
command! BerylSelectColorscheme call beryl_select#open('colorschemes')

" -------------------------------------------------------------------------------------
" API - open file or buffer
" -------------------------------------------------------------------------------------

call beryl_select#configure('files', 'Open File', 
			\ 'beryl_select_file#list',         
			\ 'beryl_select_file#open',
            \ 'beryl_select_file#render',
            \ 'beryl_select_file#get_name')

call beryl_select#configure('buffers', 'Select Buffer',
			\ 'beryl_select_buffer#list',       
			\ 'beryl_select_buffer#open',
            \ 'beryl_select_buffer#render',
            \ 'beryl_select_buffer#get_name')

call beryl_select#configure('quickfix', 'Select QuickFix List',
            \ 'beryl_select_qf#list',
            \ 'beryl_select_qf#open',
            \ 'beryl_select_qf#render',
            \ 'beryl_select_qf#get_name')

call beryl_select#configure('colorschemes', 'Select Color Scheme',
			\ 'beryl_select_colorscheme#list', 
			\ 'beryl_select_colorscheme#open',
            \ 'beryl_select_colorscheme#render',
            \ 'beryl_select_colorscheme#get_name')

if exists('g:beryl_select_buffer_key')
	execute 'nnoremap <silent> ' . g:beryl_select_buffer_key . ' :BerylSelectBuffer<CR>'
	execute 'inoremap <silent> ' . g:beryl_select_buffer_key . ' <ESC>:BerylSelectBuffer<CR>'
endif

if exists('g:beryl_select_file_key')
	execute 'nnoremap <silent> ' . g:beryl_select_file_key . ' :BerylSelectFile<CR>'
	execute 'inoremap <silent> ' . g:beryl_select_file_key . ' <ESC>:BerylSelectFile<CR>'
endif

if exists('g:beryl_select_quickfix_key')
	execute 'nnoremap <silent> ' . g:beryl_select_qf_key . ' :BerylSelectQuickfix<CR>'
	execute 'inoremap <silent> ' . g:beryl_select_qf_key . ' <ESC>:BerylSelectQuickfix<CR>'
endif

if !exists('g:beryl_select_hidden_files')
	let g:beryl_select_hidden_files	= 0
endif

if !exists('g:beryl_select_max_size')
	let g:beryl_select_max_size	= 10
endif

" ---------------------------------------------------------------------------------------
" templates
" ---------------------------------------------------------------------------------------

command! BerylTemplatesFile    call beryl_select#open('templates_file')
command! BerylTemplatesSnippet call beryl_select#open('templates_snippet')
command! BerylTemplatesNext    call beryl_templates#next()
command! BerylTemplatesDone    call beryl_templates#done()

"command! -range BerylTemplatesSnippetVisual call beryl_select#open('templates_snippet') 

"autocmd! BufLeave * call beryl_templates#done()

" -------------------------------------------------------------------------------------
" API - open file or buffer
" -------------------------------------------------------------------------------------

call beryl_select#configure('templates_file', 'New File', 
			\ 'beryl_templates_file#list',
			\ 'beryl_templates_file#new',
            \ 'beryl_templates_file#render',
            \ 'beryl_templates_file#get_name')

call beryl_select#configure('templates_snippet', 'Insert Snippet',
			\ 'beryl_templates_snippet#list',
			\ 'beryl_templates_snippet#normal',
            \ 'beryl_tempaltes_snippet#render',
            \ 'beryl_templates_snippet#get_name')

call beryl_select#configure('templates_snippet_visual', 'Insert Snippet',
			\ 'beryl_templates_snippet#list',
			\ 'beryl_templates_snippet#visual',
            \ 'beryl_templates_snippet#render',
            \ 'beryl_templates_snippet#get_name')

if exists('g:beryl_templates_file_key')
	execute 'nnoremap <silent> ' . g:beryl_templates_file_key . ' :BerylTemplatesFile<CR>'
	execute 'inoremap <silent> ' . g:beryl_templates_file_key . ' <ESC>:BerylTemplatesFile<CR>'
endif

if exists('g:beryl_templates_snippet_key')
	execute 'nnoremap <silent> ' . g:beryl_templates_snippet_key . ' :BerylTemplatesSnippet<CR>'
	execute 'inoremap <silent> ' . g:beryl_templates_snippet_key . ' <Esc>:BerylTemplatesSnippet<CR>'
	execute 'vnoremap <silent> ' . g:beryl_templates_snippet_key . ' :call beryl_select#open("templates_snippet_visual")<CR>'
endif

highlight link BerylTemplatesPlaceholders Search
highlight link BerylTemplatesCurrentPlaceholder Visual


" plugin/beryl.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists('g:plugin_beryl')
	finish
endif
let g:plugin_beryl = 1

let g:beryl_root = expand('<sfile>:p:h:h')

" -------------------------------------------------------------------------------------
" defaults
" -------------------------------------------------------------------------------------

" 25e2 ◢  25e3 ◣  25e4 ◤  25e5 ◥

" Fold    Unfold  Loaded
" 25b6 ▶  25bc ▼  25a0 ■  | 25b2 ▲  25c0 ◀  25c6 ◆  25cf ●
" 25b7 ▷  25bd ▽  25a1 □  | 25b3 △  25c1 ◁  25c7 ◇  25ef ◯
" 25b8 ▸  25be ▾  25aa ▪  | 25b4 ▴  25c2 ◂
" 25b9 ▹  25bf ▿  25ab ▫  | 25b5 ▵  25c3 ◃

" ▶▷▸▹
" ▼▽▾▿
" ■□▪▫
"                                  Fold            Unfold     Loaded          UnfoldedContains FoldedContains
let g:beryl_tree_themes = {
            \ 'big_fill'   : {'+': "\u25b6 ", '-': "\u25bc ", '*': "\u25a0 ", '#': "\u25b6\t", '=': "\u25bc\t", ' ': "  "},
            \ 'big'        : {'+': "\u25b7 ", '-': "\u25bd ", '*': "\u25a1 ", '#': "\u25b7\t", '=': "\u25bd\t", ' ': "  "},
            \ 'small_fill' : {'+': "\u25b8 ", '-': "\u25be ", '*': "\u25aa ", '#': "\u25b8\t", '=': "\u25be\t", ' ': "  "},
            \ 'small'      : {'+': "\u25b9 ", '-': "\u25bf ", '*': "\u25ab ", '#': "\u25b9\t", '=': "\u25bf\t", ' ': "  "},
            \ 'ascii'      : {'+': "+ "     , '-': "- "     , '*': "* "     , '#': "#\t"     , '=': "=\t"     , ' ': "  "}}

let g:beryl_select_buffer_key           = get(g:, 'beryl_select_buffer_key', '<C-F>')
let g:beryl_select_file_key             = get(g:, 'beryl_select_file_key', '<C-O>')
let g:beryl_quickfix_toggle_key         = get(g:, 'beryl_quickfix_toggle_key', '<C-\>')
let g:beryl_find_usages_key             = get(g:, 'beryl_find_usages_key', '<C-_>')
let g:beryl_tree_tags_key               = get(g:, 'beryl_tree_tags_key', '<C-L>')
let g:beryl_tree_open_key               = get(g:, 'beryl_tree_open_key', '<C-K>')
let g:beryl_select_hidden_files         = get(g:, 'beryl_select_hidden_files', 1)
let g:beryl_select_files_ignore         = get(g:, 'beryl_select_files_ignore', ['^\.git', '^_build/', '\.swp$'])
let g:beryl_select_max_height           = get(g:, 'beryl_select_max_height', 20)
let g:beryl_tree_hidden_files           = get(g:, 'beryl_tree_hidden_files', 1)
let g:beryl_tree_max_width              = get(g:, 'beryl_tree_max_width', 45)
let g:beryl_tree_files_key              = get(g:, 'beryl_tree_files_key', '<C-K>')
let g:beryl_tree_buffers_key            = get(g:, 'beryl_tree_buffers_key', '<C-J>')
let g:beryl_tree_open_on_startup        = get(g:, 'beryl_tree_open_on_startup', 0)
let g:beryl_tree_pull_up                = get(g:, 'beryl_tree_pull_up', 1)
let g:beryl_tree_orientation            = get(g:, 'beryl_tree_orientation', 'right')
let g:beryl_tree_files_ignore           = get(g:, 'beryl_tree_files_ignore', ['^./.git', '^./_build', '\.swp$'])
let g:beryl_tree_theme_name             = get(g:, 'beryl_tree_theme', 'small_fill')
let g:beryl_tree_theme                  = g:beryl_tree_themes[g:beryl_tree_theme_name]
let g:beryl_select_max_size             = get(g:, 'beryl_select_max_height', 10)
let g:beryl_quickfix_max_height         = get(g:, 'beryl_quickfix_max_height', 10)
let g:beryl_select_modes                = get(g:, 'beryl_select_modes', {})
let g:beryl_layout                      = get(g:, 'beryl_layout', '')

" -------------------------------------------------------------------------------------
" key mapping
" -------------------------------------------------------------------------------------

execute 'nnoremap <silent> ' . g:beryl_select_buffer_key . ' :call beryl#select#open("buffers")<CR>'
execute 'inoremap <silent> ' . g:beryl_select_buffer_key . ' <ESC>:call beryl#select#open("buffers")<CR>'

execute 'nnoremap <silent> ' . g:beryl_select_file_key . ' :call beryl#select#open("files")<CR>'
execute 'inoremap <silent> ' . g:beryl_select_file_key . ' <ESC>:call beryl#select#open("files")<CR>'

execute 'nnoremap <silent> ' . g:beryl_tree_files_key . ' :call beryl#tree#toggle("files")<CR>'
execute 'inoremap <silent> ' . g:beryl_tree_files_key . ' <ESC>:call beryl#tree#toggle("files")<CR>'

execute 'nnoremap <silent> ' . g:beryl_tree_buffers_key . ' :call beryl#tree#toggle("buffers")<CR>'
execute 'inoremap <silent> ' . g:beryl_tree_buffers_key . ' <ESC>:call beryl#tree#toggle("buffers")<CR>'

execute 'nnoremap <silent> ' . g:beryl_tree_tags_key . ' :call beryl#tree#toggle("tags")<CR>'
execute 'inoremap <silent> ' . g:beryl_tree_tags_key . ' <ESC>:call beryl#tree#toggle("tags")<CR>'

execute 'nnoremap <silent> ' . g:beryl_quickfix_toggle_key . ' :call beryl#quickfix_toggle()<CR>'
execute 'inoremap <silent> ' . g:beryl_quickfix_toggle_key . ' <ESC>:call beryl#quickfix_toggle()<CR>'

" wraparound is better than E553 error
nnoremap <silent> ' :try<bar>cnext<bar>catch /^Vim\%((\a\+)\)\=:E\%(553\<bar>42\):/<bar>cfirst<bar>endtry<CR>
nnoremap <silent> " :try<bar>cprev<bar>catch /^Vim\%((\a\+)\)\=:E\%(553\<bar>42\):/<bar>clast<bar>endtry<CR>

" -------------------------------------------------------------------------------------
" some wiring
" -------------------------------------------------------------------------------------

call beryl#files#init()
call beryl#buffers#init()
call beryl#tags#init()


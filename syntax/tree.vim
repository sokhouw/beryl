" syntax/beryl_tree.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists("b:current_syntax")
    finish
endif
let b:current_syntax = 'tree'

syn match btTabAtEOL                    /\t$/ contained

syn match btDir                         /[^\.].*[^\t]/ contained nextgroup=btTabAtEOL
syn match btHiddenDir                   /\..*[^\t]/ contained nextgroup=btTabAtEOL
syn match btFile                        /[^\.].*[^\t]$/ contained
syn match btHiddenFile                  /\..*[^\t]$/ contained

syn match btScopeTag                    /\([bglsw]:\)\|\([a-zA-Z0-9_]\+#\)\+/ contained nextgroup=btFunctionName
syn match btFunctionName                /[a-zA-Z0-9_]/ contained nextgroup=btOpenBracket
syn match btOpenBracket                 /(/ contained

syn match btGap                         /^\s*/ nextgroup=btFoldedMark,btUnfoldedMark,btFoldedContainsLoadedMark,btUnfoldedContainsLoadedMark,btLoadedFileMark,btDir,btHiddenDir,btFile,btHiddenFile,btScopeTag

execute 'syn match btFoldedMark                  /' . g:beryl_tree_theme['+'] . '/ contained nextgroup=btDir,btHiddenDir'
execute 'syn match btUnfoldedMark                /' . g:beryl_tree_theme['-'] . '/ contained nextgroup=btDir,btHiddenDir'

execute 'syn match btFoldedContainsLoadedMark    /' . g:beryl_tree_theme['#'] . '/ contained nextgroup=btDir,btHiddenDir'
execute 'syn match btUnfoldedContainsLoadedMark  /' . g:beryl_tree_theme['='] . '/ contained nextgroup=btDir,btHiddenDir'
execute 'syn match btLoadedFileMark              /' . g:beryl_tree_theme['*'] . '/ contained nextgroup=btFile,btHiddenFile'

syn match btRoot                        /^\t.*$/

hi def link btScopeTag Comment

hi def link btFoldedMark                    Type
hi def link btUnfoldedMark                  Type
hi def link btFoldedContainsLoadedMark      FCLM
hi def link btUnfoldedContainsLoadedMark    FCLM
hi def link btLoadedFileMark                FCLM

hi def link btRoot                          Keyword
hi def link btDir                           Keyword
hi def link btHiddenDir                     Comment
hi def link btFile                          Normal
hi def link btHiddenFile                    Comment

hi CursorLine                               ctermfg=NONE ctermbg=017

hi FCLM ctermfg=064

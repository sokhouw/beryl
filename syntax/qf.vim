
if exists("b:current_syntax")
	finish
endif
let b:current_syntax = 'qf'

syn match	qfFileName	'^[^|]\+'

syn match	qfError		' error|[^|]\+' contains=qfErrorMsg
syn match	qfWarning	' warning|[^|]\+' contains=qfWarningMsg

syn match	qfErrorMsg	'[^|]\+$'	contained
syn match	qfWarningMsg	'[^|]\+$'	contained

hi def link qfFileName	Directory

hi qfErrorMsg	ctermfg=196

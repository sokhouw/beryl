" plugin/beryl_erlang.vim
" Author:       Marcin Sokolowski <marcin.sokolowski@gmail.com>
" Version:      0.1

if exists('g:plugin_beryl_erlang')
	finish
endif
let g:plugin_beryl_erlang = 1

" -------------------------------------------------------------------------------------
" global variables
" -------------------------------------------------------------------------------------

if !exists('g:beryl_erlang_otp_root')
    let g:beryl_erlang_otp_root = fnamemodify(system('whereis erl | cut -d " " -f 2')[:-2], ':h:h')
endif

" list of OTP libraries that will be scanned to create OTP tag file
if !exists('g:beryl_erlang_otp_libs')
	let g:beryl_erlang_otp_libs = [
        \ 'common_test', 'compiler', 'crypto', 'erts',
		\ 'eunit', 'inets', 'kernel', 'mnesia', 'os_mon',
		\ 'parsetools', 'reltool', 'runtime_tools', 'sasl',
		\ 'snmp', 'ssh', 'ssl', 'stdlib', 'syntax_tools',
		\ 'test_server', 'tools', 'xmerl' ]
endif

if !exists('beryl_erlang_otp_tagfile')
    let g:beryl_erlang_otp_tagfile = g:beryl_erlang_otp_root . '.tags'
endif

if !exists('g:beryl_erlang_project_tagfile')
    let g:beryl_erlang_project_tagfile = '.tags'
endif

if !exists('g:beryl_erlang_default_build_dir')
    let g:beryl_erlang_default_build_dir = '_build/default'
endif

if !exists('g:beryl_erlang_test_build_dir')
    let g:beryl_erlang_test_build_dir = '_build/test'
endif

function! s:init_layout()
    command! BerylOtpTags call beryl#erlang#create_otp_tagfile()
    command! BerylTags call beryl#erlang#create_project_tagfile()
endfunction

" -------------------------------------------------------------------------------------
" layout
" -------------------------------------------------------------------------------------

if filereadable('rebar.config') || filereadable('rebar.config.script')
    if isdirectory('lib') && len(globpath('lib', '*/src/*.erl')) > 0
        let g:beryl_layout = 'erlang-multi'
        call s:init_layout()
    elseif isdirectory('src') && len(globpath('src', '*.erl')) > 0
        let g:beryl_layout = 'erlang-single'
        call s:init_layout()
    endif
endif


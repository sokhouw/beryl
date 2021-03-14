#!/usr/bin/env escript

-mode(compile).

-define(FOLD_OPEN, "% {{{").
-define(FOLD_CLOSE, "% }}}").

main([File|_]) ->
    case beam_lib:chunks(File, [compile_info, abstract_code]) of
        {ok, {_, [{compile_info, CI}, {abstract_code, {_, AC}}]}} ->
            R = string:copies("-", 110),
            H = "%% " ++ R ++ "\n%% `Decompiled " ++ File ++ "'\n%% " ++ re:replace(io_lib:format("~p~n", [CI]), "\n", "\n%% ", [global]) ++ R ++ "\n",
            [ErlFile|_] = [F || {attribute, _, file, {F, _}} <- AC ],
            AC2 = erl_syntax:form_list(AC),
            F1 = erl_prettypr:format(AC2, [{paper, 80}, {ribbon, 1000}]),

            F2 = re:replace(F1, "\n", "<NL>", [global]),
            F3 = re:replace(F2, "^-file\\(\\\"" ++ ErlFile ++ "\\\", [0-9]\+\\)\\.<NL>", "", [ungreedy]),
            F4 = re:replace(F3, "-file\\(\\\"" ++ ErlFile ++ "\\\", [0-9]\+\\)\\.<NL>", ?FOLD_CLOSE "<NL>", [global, ungreedy]),
            F5 = re:replace(F4, "-file\\(\\\"(.*)\\\"", ?FOLD_OPEN " include \\1 <NL>-file(\"\\1\"", [global, ungreedy]),
            F6 = re:replace(F5, "-spec\\((.*)\\)\\.<NL>", ?FOLD_OPEN " spec <NL>-spec(\\1).<NL>" ?FOLD_CLOSE "<NL>", [global, ungreedy]),

            io:put_chars([H, re:replace(F6, "<NL>", "\n", [global])]),
            ok;
        _ ->
            ok
    end.


#!/usr/bin/env escript

-mode(compile).

main(FuncSpec) ->
     FuncSpecBin = list_to_binary(FuncSpec),
     [MBin, FA] = binary:split(FuncSpecBin, <<":">>),
     [FBin, ABin] = binary:split(FA, <<"/">>),
     M = binary_to_atom(MBin, latin1),
     F = binary_to_atom(FBin, latin1),
     A = binary_to_integer(ABin),

     [ process_lib(Lib, {M, F, A}) || Lib <- filelib:wildcard("*", "lib") ].

process_lib(Lib, {M, F, A}) ->
    Path = "_build/default/lib/" ++ Lib ++ "/ebin",
    Beams = filelib:wildcard("*.beam", Path),
    [ begin
         {ok, Bin} = file:read_file(Path ++ "/" ++ Beam),
         Module = list_to_atom(filename:basename(Beam, ".beam")),
         {ok, {_, [{abstract_code, {_, Tree}}]}} = beam_lib:chunks(Bin, [abstract_code]),
         Usages = find_usages(Module, Tree),
         Source = "lib/" ++ Lib ++ "/src/" ++ atom_to_list(Module) ++ ".erl",
         [ io:format("~s:~p:~p:~p/~p~n", [Source, Line, M2, F2, A2]) 
           || {usage, _Module, Line, {M2, F2, A2}} <- Usages, M =:= M2, F =:= F2, A =:= A2 ]
      end || Beam <- Beams ],

    ok.

find_usages(Module, Tree) ->
    lists:reverse(find_usages(Module, Tree, [])).

find_usages(Module, [{'fun', Line, {function, F, A}}|T], Acc) when is_integer(Line), is_atom(F), is_integer(A) ->
    Acc2 = [{usage, Module, Line, {Module, F, A}}|Acc],
    find_usages(Module, T, Acc2);

find_usages(Module, [{'fun', Line, {function, {atom, _Line2, M}, {atom, _Line3, F}, {integer, _Line4, A}}}|T], Acc) ->
    Acc2 = [{usage, Module, Line, {M, F, A}}|Acc],
    find_usages(Module, T, Acc2);

find_usages(Module, [{call, Line, {atom, _Line2, F}, Args}|T], Acc) ->
    Acc2 = [{usage, Module, Line, {Module, F, length(Args)}} | Acc],
    Acc3 = find_usages(Module, Args, Acc2),
    find_usages(Module, T, Acc3);

find_usages(Module, [{call, Line, {remote, _Line2, {atom, _Line3, M}, {atom, _Line4, F}}, Args}|T], Acc) ->
    Acc2 = [{usage, Module, Line, {M, F, length(Args)}}|Acc],
    Acc3 = find_usages(Module, Args, Acc2),
    find_usages(Module, T, Acc3);

find_usages(Module, [H|T], Acc) when is_list(H) ->
    Acc2 = find_usages(Module, H, Acc),
    find_usages(Module, T, Acc2);

find_usages(Module, [H|T], Acc) when is_tuple(H) ->
    Acc2 = find_usages(Module, tuple_to_list(H), Acc),
    find_usages(Module, T, Acc2);

find_usages(Module, [_|T], Acc) ->
    find_usages(Module, T, Acc);

find_usages(_Module, [], Acc) ->
    Acc.


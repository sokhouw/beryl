#!/usr/bin/env escript

-mode(compile).

-define(TAB, 9).

main([SrcPath]) ->
    BeamPath = get_beam(SrcPath),
    process_beam(SrcPath, BeamPath);
main(_) ->
    ok.

process_beam(SrcPath, BeamPath) ->
    {ok, Bin} = file:read_file(BeamPath),
    Module = list_to_atom(filename:basename(BeamPath, ".beam")),
    {ok, {_, [{abstract_code, {_, Tree}}]}} = beam_lib:chunks(Bin, [abstract_code]),
    Tags = find_tags(SrcPath, Module, Tree),
    [ io:format("~s~n", [format_tag(SrcPath, Tag)]) || Tag <- Tags],
    ok.

find_tags(SrcPath, Module, Tree) ->
    lists:reverse(find_tags(SrcPath, false, Module, Tree, [])).

find_tags(SrcPath, true, Module, [{function, Line, F, A, _Clauses}|T], Acc) when is_integer(Line), is_atom(F), is_integer(A) ->
    Acc2 = [{function, Module, Line, {Module, F, A}}|Acc],
    find_tags(SrcPath, true, Module, T, Acc2);

find_tags(SrcPath, true, Module, [{attribute, Line, record, {Record, _Fields}}|T], Acc) when is_integer(Line), is_atom(Record) ->
    Acc2 = [{record, Module, Line, Record}|Acc],
    find_tags(SrcPath, true, Module, T, Acc2);

find_tags(SrcPath, _Scan, Module, [{attribute, _, file, {AttrSrcPath, _}}|T], Acc) ->
    Subject = list_to_binary(AttrSrcPath),
    Match = list_to_binary(SrcPath),
    Scan = try binary:part(Subject, byte_size(Subject) - byte_size(Match), byte_size(Match)) =:= Match catch _:_ -> false end,
    % io:format("----~n~p~n~p~n~p~n-----~n", [Scan, SrcPath, AttrSrcPath]),
    find_tags(SrcPath, Scan, Module, T, Acc);

find_tags(SrcPath, Scan, Module, [{attrbiute, _, type, {Type, _, _}}|T], Acc) ->
    find_tags(SrcPath, Scan, Module, T, [{type, Type}|Acc]);

find_tags(SrcPath, true, Module, [H|T], Acc) when is_list(H) ->
    Acc2 = find_tags(SrcPath, true, Module, H, Acc),
    find_tags(SrcPath, true, Module, T, Acc2);

find_tags(SrcPath, true, Module, [H|T], Acc) when is_tuple(H) ->
    Acc2 = find_tags(SrcPath, true, Module, tuple_to_list(H), Acc),
    find_tags(SrcPath, true, Module, T, Acc2);

find_tags(SrcPath, Scan, Module, [_|T], Acc) ->
    find_tags(SrcPath, Scan, Module, T, Acc);

find_tags(_SrcPath, _Scan, _Module, [], Acc) ->
    Acc.

%% -----------------------------------------------------------------------------------------------------------
%% Internals
%% -----------------------------------------------------------------------------------------------------------

format_tag(SrcPath, {function, Module, Line, {Module, F, A}}) ->
    io_lib:format("~p/~p\tfunction\t~s\t~p", [F, A, SrcPath, Line]);
format_tag(SrcPath, {record, _Module, Line, Record}) ->
    io_lib:format("#~p\trecord\t~s\t~p", [Record, SrcPath, Line]).

get_lib_name(Path) ->
    filename:basename(filename:dirname(filename:dirname(filename:absname(Path)))).

get_beam(Path) ->
    Beam = filename:basename(Path, ".erl") ++ ".beam",
    case profile_name(Path) of
        default ->
            filename:join(["_build", "default", "lib", get_lib_name(Path), "ebin", Beam]);
        test ->
            filename:join(["_build", "test", "lib", get_lib_name(Path), "test", Beam])
    end.

profile_name(Path) ->
    case filename:basename(filename:dirname(Path)) of
        "test" ->
            test;
        _ ->
            default
    end.


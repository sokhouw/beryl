#!/usr/bin/env escript

-define(TMP_MODULE, "beryltmpmodule").

%% -----------------------------------------------------------------------------------------------------------
%% main
%% ----------------------------------------------------------------------------------------------------------- 

main([Path]) ->
    try
        case get_command(Path) of
            {ok, {escript, _}} ->
                report(compile_escript(Path));
            {ok, {module, _, Beam, Opts}} ->
                report(compile_module(Path, Beam, Opts));
            {ok, {header, _}} ->
                report(compile_header(Path));
            {ok, {file, _}} ->
                report(compile_file(Path));
            {error, Reason} ->
                io:format("~s:1:E:beryl: ~p~n", [Path, Reason])
        end
    catch
        E:R ->
            io:format("~s:1:E:beryl: ~p:~p~n", [Path, E, R])
    end.

get_command(Path) ->
    case filelib:is_file(Path) of
        true ->
            {ok, Content} = file:read_file(Path),
            case is_escript(Content) of
                true ->
                    {ok, {escript, Path}};
                false ->
                    case filename:extension(Path) of
                        ".erl" ->
                            Beam = get_beam(Path),
                            filelib:ensure_dir(Beam),
                            case get_opts(Path, Beam) of
                                {ok, Opts} ->
                                    {ok, {module, Path, Beam, Opts}};
                                error ->
                                    {error, no_beam}
                            end;
                        ".hrl" ->
                            {ok, {header, Path}};
                        _ ->
                            {ok, {file, Path}}
                    end
            end;
        false ->
            {error, file_not_found}
    end.

is_escript(Content) ->
    case re:run(Content, "#!.*escript") of
        {match, _} ->
            case re:run(Content, "main\\S*(.*)\\S*->") of
                {match, _} ->
                    true;
                nomatch ->
                    false
            end;
        nomatch -> 
            false
    end.

profile_name(Path) ->
    case filename:basename(filename:dirname(Path)) of
        "test" ->
            test;
        _ ->
            default
    end.

%% -----------------------------------------------------------------------------------------------------------
%% Internals - compilation
%% ----------------------------------------------------------------------------------------------------------- 

compile_module(Path, Beam, Opts) ->
    case profile_name(Path) of
        default ->
            code:add_paths(filelib:wildcard("_build/default/lib/*/ebin"));
        test ->
            code:add_paths(filelib:wildcard("_build/test/lib/*/ebin")),
            code:add_paths(filelib:wildcard("_build/test/lib/*/test"))
    end,
    case compile:file(Path, [return, {outdir, filename:dirname(Beam)}|Opts]) of
        {ok, _ModuleName} ->
            xref(Path, Opts);
        {ok, _ModuleName, []} ->
            xref(Path, Opts);
        {ok, _ModuleName, Warnings} ->
            lists:flatten([ convert(warning, W) || W <- Warnings ]) ++
            xref(Path, Opts);
        {error, Errors, Warnings} ->
            lists:flatten([ convert(error, E) || E <- Errors ] ++ 
                          [ convert(warning, W) || W <- Warnings ])
    end.

compile_header(Path) ->
    TmpName = temp_name(),
    Source = TmpName ++ ".erl",
    try
        file:write_file(Source, [
                    "-module(", TmpName, ").\n"
                    "-include(\"", filename:absname(Path), "\").\n"]),
        {ok, Opts} = get_opts(Source, Path),
        case compile:file(Source, [binary,return|Opts]) of
            {ok, _ModuleName, _} ->
                [];
            {ok, _ModuleName, _, []} ->
                [];
            {ok, _ModuleName, _, Warnings} ->
                lists:flatten([ convert(warning, W) || W <- Warnings ]);
            {error, Errors, Warnings} ->
                lists:flatten([ convert(error, E) || E <- Errors ] ++ 
                              [ convert(warning, W) || W <- Warnings ])
        end
    after
        file:delete(Source)
    end.

compile_file(Path) ->
    case file:script(Path) of
        {ok, _} ->
            [];
        {error, {Line, Mod, Term}} ->
            [{{Path, Line}, {error, Mod, Term}}];
        {error, Reason} ->
            [{{Path, 1}, {error, beryl, io_lib:format("~p", [Reason])}}]
    end.

compile_escript(Path) ->
    {ok, Content} = file:read_file(Path),
    TmpPath = filename:join([filename:dirname(Path), ?TMP_MODULE ++ ".erl"]),
    Content2 = re:replace(Content, "(\\S*#!.*escript\\S*)", "-module(" ++ ?TMP_MODULE ++ ").%\\1\n-export([main/1])."),
    ok = file:write_file(TmpPath, [Content2]),
    try
        case compile:file(TmpPath, [return, strong_validation]) of
            {ok, _ModuleName} ->
                [];
            {ok, _ModuleName, []} ->
                [];
            {ok, _ModuleName, Warnings} ->
                fix_escript_report(lists:flatten([ convert(warning,V) || V <- Warnings ]), Path, TmpPath);
            {error, Errors, Warnings} ->
                fix_escript_report(lists:flatten([ convert(error, V) || V <- Errors ] ++ 
                                                 [ convert(warning, V) || V <- Warnings ]), Path, TmpPath)
        end
    after
        file:delete(TmpPath)
    end.

convert(Type, {FileName, Messages}) ->
    [{{FileName, Line}, {Type, From, Message}} || {Line, From, Message} <- Messages].

fix_escript_report(Msgs, Path, TmpPath) ->
    lists:map(fun({{Path2, Line}, V}) when TmpPath =:= Path2 ->
                  {{Path, Line - 1}, V};
              (V) ->
                  V
              end, Msgs).

temp_name() ->
        {X, Y, Z} = os:timestamp(),
        "beryl_" ++ integer_to_list(X) ++ "_" ++ integer_to_list(Y) ++ "_" ++ integer_to_list(Z).

%% -----------------------------------------------------------------------------------------------------------
%% Internals - xref
%% ----------------------------------------------------------------------------------------------------------- 

xref(Path, Opts) ->
    Module = list_to_atom(filename:basename(Path, ".erl")),
    case xref:m(Module) of
        Result when is_list(Result) ->
            case lists:keyfind(undefined, 1, Result) of
                {undefined, UndefCalls0} ->
                    UndefCalls = [ UndefCall || {_, UndefCall} <- UndefCalls0 ],
                    Calls = lists:filter(fun({_, Call}) -> 
                                             lists:member(Call, UndefCalls) 
                                         end, find_calls(Module, Path, Opts)),
                    [ {{Path, Line}, {error, beryl_xref, {undefined, {M, F, A}}}} || {Line, {M, F, A}} <- Calls ];
                _ ->
                    []
            end;
        {error, _, Reason} ->
            [ {{"beryl", 1}, {error, beryl, Reason}} ]
    end.

%add_paths(Profile, Dirs) ->
%    [ code:add_path(filename:join([LibDir, Dir]))
%            || LibDir <- filelib:wildcard(filename:join(["_build", Profile, "lib", "*"])),
%                        Dir <- Dirs ],
%    ok.

%% Extracts a list of calls within a module: {Line, Module, Function, Arity}
find_calls(Module, File, Opts) ->
    IncludePath = [ Dir || {i, Dir} <- Opts ],
    {ok, Clauses} = epp:parse_file(File, IncludePath, []),
    do_find_calls(Module, Clauses, []).

do_find_calls(_Module, [], Calls) ->
    lists:reverse(Calls);
do_find_calls(Module, [{call, Line, {remote, _, {atom, _, M}, {atom, _, F}}, Args}|T], Calls) ->
    do_find_calls(Module, Args ++ T, [{Line, {M, F, length(Args)}}|Calls]);
do_find_calls(Module, [{call, Line, {atom, _, F}, Args}|T], Calls) ->
    do_find_calls(Module, Args ++ T, [{Line, {Module, F, length(Args)}}|Calls]);
do_find_calls(Module, [H|T], Calls) when is_list(H) ->
    do_find_calls(Module, H ++ T, Calls);
do_find_calls(Module, [H|T], Calls) when is_tuple(H) ->
    do_find_calls(Module, tuple_to_list(H) ++ T, Calls);
do_find_calls(Module, [_X|T], Calls) ->
    do_find_calls(Module, T, Calls).

%% -----------------------------------------------------------------------------------------------------------
%% Internals - reporting
%% ----------------------------------------------------------------------------------------------------------- 

report(R) ->
    [ io:format("~s:~p:~s:~s~n", [FileName, Line, type(Type), message(From, Message)]) 
      || {{FileName, Line}, {Type, From, Message}} <- lists:sort(R) ],
    halt(1).

type(error) ->
    "E";
type(warning) ->
    "W";
type(X) ->
    atom_to_list(X).

message(beryl_xref, {undefined, {M, F, A}}) ->
    io_lib:format("function ~p:~p/~p undefined", [M, F, A]);
message(beryl, not_compiled) ->
    "target beam file not found, could not extract compile options";
message(Source, Message) ->
    try
        Source:format_error(Message) 
    catch 
        _:_ -> 
              io_lib:format("~p", [{Source, Message}]) 
    end.

%% -----------------------------------------------------------------------------------------------------------
%% Internals
%% ----------------------------------------------------------------------------------------------------------- 

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
        
%% -----------------------------------------------------------------------------------------------------------
%% Internals - reading compile opts
%% ----------------------------------------------------------------------------------------------------------- 

get_opts(Module, Beam) ->
    case read_opts([Beam]) of
        {ok, Opts} ->
            {ok, Opts};
        _ ->
            % try to read from other beams in the same directory
            case read_opts(filelib:wildcard(filename:dirname(Beam) ++ "/*.beam")) of
                {ok, Opts} ->
                    {ok, Opts};
                {error, not_compiled} ->
                    get_default_opts(Module, Beam)
            end
    end.

read_opts([Beam|T]) ->
    case beam_lib:chunks(Beam, [compile_info]) of
        {ok, {_, [{compile_info, CI}]}} ->
            case lists:keyfind(options, 1, CI) of
                {options, Opts} ->
                    {ok, prepare_opts(Opts, [])};
                _ ->
                    read_opts(T)
            end;
        _ ->
            read_opts(T)
    end;
read_opts([]) ->
    {error, not_compiled}.

get_default_opts(Module, Beam) ->
    {ok, [
          get_default_outdir(Beam),
          debug_info,
          warnings_as_errors] ++ get_default_include_dirs(Module)}.
          
get_default_outdir(Beam) ->
    {outdir, filename:dirname(Beam)}.

get_default_include_dirs(Module) ->
    [{i, filename:dirname(Module)},
     {i, filename:join([filename:dirname(filename:dirname(Module)), "include"])},
     {i, filename:dirname(filename:dirname(Module))}].

%% get rid of parse transforms
prepare_opts([{parse_transform, _}|T], Acc) ->
    prepare_opts(T, Acc);
prepare_opts([H|T], Acc) ->
    prepare_opts(T, [H | Acc]);
prepare_opts([], Acc) ->
    lists:reverse(Acc).


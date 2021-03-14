#!/usr/bin/env escript

-mode(compile).

-define(a2b(V)  , (atom_to_binary(V, latin1))/binary).
-define(i2b(V)  , (integer_to_binary(V))/binary).
-define(l2b(V)  , (list_to_binary(V))/binary).
-define(iol2b(V), (iolist_to_binary(V))/binary).
-define(tab     , "\t").
-define(nl      , "\n").
-define(ext     , ";\"").
-define(tag(T, V, C), "!TAG_", T, ?tab, V, ?tab, "/", C, "/", ?nl).

main(Args) ->
    Opts = parse_args(Args, [{verbosity, 0}]),
    TagsFile = proplists:get_value(tag_file, Opts, "tags"),
    Files = proplists:get_value(files, Opts),
    Mode = proplists:get_value(mode, Opts),
    Tags = lists:sort([ ctag(Tag) || Tag <- scan(Files, [])]),
    case Mode of
        "create" ->
            create(TagsFile, Tags);
        "update" ->
            update(TagsFile, Tags, Files);
        "list" ->
            io:format("~s", [[Tags]])
    end.

create(TagsFile, Tags) ->
    case TagsFile of
        "-" ->
            io:format("~s", [[header(), Tags]]);
        _ ->
            case filelib:ensure_dir(TagsFile) of
                ok ->
                    case file:write_file(TagsFile, [header(), iolist_to_binary(Tags)], [write]) of
                        ok ->
                            info("tags file written: \"~s\"", [TagsFile]);
                        {error, Reason} ->
                            fail("failed to write to tags file \"~s\": ~p", [TagsFile, Reason])
                    end;
                {error, Reason} ->
                    fail("failed to dir \"~s\": ~p", [filename:dirname(TagsFile), Reason])
            end
    end.

update(TagsFile, Tags, Files) ->
    Files2 = [ list_to_binary(F) || {top, F} <- Files ],
    {ok, B} = file:read_file(TagsFile),
    B1 = binary:split(B, <<"\n">>, [global, trim]),
    B2 = skip_header(B1),
    B3 = [ { binary:split(X, <<"\t">>, [global]), X} || X <- B2 ],
    B4 = lists:filter(fun
                          ({[<<"!", _/binary>>|_], _}) ->
                              true;
                          ({[_, F|_], _}) ->
                              not lists:member(F, Files2);
                          (_) ->
                              true
                      end, B3),
    B5 = [ <<X/binary, "\n">> || {_, X} <- B4],
    Tags2 = lists:sort(Tags ++ B5),
    create(TagsFile, Tags2).

skip_header([<<"!", _/binary>>|T]) ->
    skip_header(T);
skip_header(T) ->
    T.

parse_args([F, TagFile|T], Opts) when F =:= "-f"; F =:= "-o" ->
    parse_args(T, [{tag_file, TagFile} | Opts]);
parse_args(["-v"|T], Opts) ->
    parse_args(T, [{verbosity, 1}|Opts]);
parse_args(["-m", Mode|T], Opts) ->
    parse_args(T, [{mode, Mode}|Opts]);
parse_args([[$-|_] = Opt|_], _) ->
    fail("Unknown option: ~s", [Opt]);
parse_args(L, Opts) ->
    [{files, parse_file_args(L)}|Opts].

parse_file_args([]) ->
    fail("No files specified.", []);
parse_file_args(L) ->
    [ case filelib:is_dir(F) orelse filelib:is_file(F) of
         true -> {top, F};
         false -> fail("Warning: cannot open source file \"~s\" : No such file or directory", [F])
      end || F <- L ].

scan([], Acc) ->
    lists:flatten(Acc);
scan([{top, Name}|T], Acc) ->
    info("processing ~s", [Name]),
    scan([Name|T], Acc);
scan([Name|T], Acc) ->
    case filename:basename(Name) of
        [$.|_] ->
            scan(T, Acc); % skip hidden files
        _ ->
            case filelib:is_dir(Name) of
                true ->
                    scan(T, scan(filelib:wildcard(Name ++ "/*"), Acc));
                false ->
                    case filename:extension(Name) == ".erl" orelse filename:extension(Name) == ".hrl" of
                        true ->
                            scan(T, scan_file(Name, Acc));
                        false ->
                            scan(T, Acc)
                    end;
                _ ->
                    Acc
            end
    end.

header() ->
    <<
        ?tag("FILE_FORMAT", "2", "extended format"),
        ?tag("FILE_SORTED", "1", "0=unsorted, 1=sorted, 2=foldcase"),
        ?tag("PROGRAM_AUTHOR", "Marcin Sokolowski", "marcin.sokolowski@bet365.com"),
        ?tag("PROGRAM_NAME", "Beryl Tags", ""),
        ?tag("PROGRAM_URL", "http://beryl.dev", "Beryl's Official Site"),
        ?tag("PROGRAM_VERSION", "0.1", "")>>.

ctag({function, Exported, Module, Fun, Args, {File, Line}}) ->
    <<
        ?l2b(Module), ":", ?a2b(Fun), "/", ?i2b(length(Args)), ?tab,
        ?l2b(rel(File)), ?tab,
        ?i2b(Line), ?ext, ?tab,
        "f", ?tab,
        "signature:", "(", ?iol2b(string:join(Args, ", ")), ")", ?tab,
        "exported:", (case Exported of true -> <<"1">>; false -> <<"0">> end)/binary, ?nl>>;
ctag({record, Module, Record, {File, Line}}) ->
    <<
        "#", ?l2b(Module), ":", ?a2b(Record), ?tab,
        ?l2b(rel(File)), ?tab,
        ?i2b(Line), ?ext, ?tab,
        "r", ?nl>>;
ctag({type, Module, Type, Args, {File, Line}}) ->
    <<
        "::", ?l2b(Module), ":", ?a2b(Type), "/", ?i2b(length(Args)), ?tab,
        ?l2b(rel(File)), ?tab,
        ?i2b(Line), ?ext, ?tab,
        "t", ?nl>>;
ctag({macro, Module, Macro, {File, Line}}) ->
    <<
        "?", ?l2b(Module), ":", ?l2b(Macro), ?tab,
        ?l2b(rel(File)), ?tab,
        ?i2b(Line), ?ext, ?tab,
        "d", ?nl>>;
ctag(_X) ->
    info("no match ~p", [_X]),
    <<>>.

rel(File) ->
    case filename:pathtype(File) of
        relative -> File;
        _        -> File
    end.

scan_file(File, Acc) ->
    M = case filename:extension(File) of
          ".erl" -> filename:basename(File, ".erl");
          ".hrl" -> "_"
    end,
    File2 = File ++ ".tmp",
    os:cmd("cat " ++ File ++ " | sed -e \"s/^-include.*$//\" | sed -e \"s/?[A-Za-z0-9_]*/blah/g\" > " ++ File2),
    try
        case epp:parse_file(File2, [], []) of
            {ok, Clauses} ->
                Specs    = [ {{F, A}, Spec} || {attribute, _, spec, {{F, A}, Spec}} <- Clauses ],
                Exports  = lists:flatten([ Exports || {attribute, _, export, Exports} <- Clauses ]),
                Funs     = [ {{F, A}, Fun, L} || {function, L, F, A, Fun} <- Clauses ],
                Records  = [ {record, M, R, {File, L}} || {attribute, L, record, {R, _Fields}} <- Clauses ],
                Types    = [ {type, M, T, Args, {File, L}} || {attribute, L, type, {T, _, Args}} <- Clauses, is_atom(T) ],
                Macros   = [ macro(File, M, S) || S <- re:split(os:cmd("grep -ne \"^-define\" " ++ File ++
                                                                    " | sed -e \"s/-define(//\" | cut -f 1 -d \",\""), "\n") ],
                Data     = [ [ function(Exports, M, F, [spec_args(F, A, Specs) | fun_args(Fun)], {File, L})
                               || {{F, A}, Fun, L} <- Funs ], Records, Types, Macros ],
                [ Data | Acc ];
             Reason ->
                fail("Failed to parse file \"~s\": ~p", [File, Reason])
        end
    after
        file:delete(File2)
    end.

spec_args(F, A, Specs) ->
    case lists:keyfind({F, A}, 1, Specs) of
        {{F, A}, Spec} ->
            spec_args(A, Spec);
        false ->
            default_args(A)
    end.

spec_args(A, [{type, _, bounded_fun, Fun}])                       -> spec_args(A, Fun);
spec_args(_, [{type, _, 'fun', [{type, _, product, Args} |_]}|_]) -> Args;
spec_args(A, _)                                                   -> default_args(A).

fun_args(Fun) ->
    [ Args || {clause, _, Args, _, _} <- Fun ].

default_args(A) ->
    [ {var, 0, '_'} || _ <- lists:seq(1, A) ].

function(Exports, M, F, Args, L) ->
    TArgs = [ best_arg_name([arg_name(Arg) || Arg <- TArg ]) || TArg <- transpose(Args)],
    {function, lists:member({F,erlang:length(TArgs)}, Exports), M, F, TArgs, L}.

macro(File, M, S) when is_binary(S) ->
    case binary:split(S, <<":">>) of
        [L, Macro] ->
            {macro, M, binary_to_list(Macro), {File, binary_to_integer(L)}};
        _ ->
            []
    end.

arg_name({var,     _, '_'   }) -> "_";
arg_name({var,     _, Name  }) -> {name, atom_to_list(Name)};
arg_name({atom,    _, _     }) -> "_";
arg_name({integer, _, _     }) -> "_";
arg_name({bin,     _, _     }) -> "_";
arg_name({record,  _, _, _  }) -> "_";
arg_name({match,   _, M1, M2}) -> best_arg_name([arg_name(M1), arg_name(M2)]);
arg_name({ann_type, _, [V|_]}) -> arg_name(V);
arg_name({tuple, _, _       }) -> {type, tuple};
arg_name({cons, _, _, _     }) -> {type, list};
arg_name({nil, _            }) -> {type, list};
arg_name({type, _, record, [{atom, _, R}]}) -> {type, {record, R}};
arg_name({type, _, T, _     }) -> {type, T};
arg_name({remote_type, _, [{atom, _, M}, {atom, _, T}, _]}) -> {type, {remote, M, T}};
arg_name(_X                  ) ->
%   info("Warning: unrecognized ~200p", [_X]),
    "_".

best_arg_name(L) ->
    [H|_] = lists:sort(fun(A1, A2) -> arg_name_rank(A1) > arg_name_rank(A2) end, L),
    case H of
        {name, Name}              -> Name;
        {type, tuple}             -> "{...}";
        {type, list}              -> "[...]";
        {type, {record, R}}       -> "#" ++ atom_to_list(R) ++ "{}";
        {type, {remote, M, T}} when is_atom(M), is_atom(T) ->
                                     case L of
                                         [_] -> list_to_atom(M) ++ ":" ++ list_to_atom(T) ++ "()";
                                         _   -> "_"
                                     end;
        {type, T} when is_atom(T) -> case L of
                                         [_] -> list_to_atom(T) ++ "()";
                                         _   -> "_"
                                     end;
        Name when is_list(Name)   -> Name;
        _                         -> info("Warning: dodgy arg_name \"~p\"", [H]), "_"
    end.

arg_name_rank({name, Name}) -> 200 + length(Name);
arg_name_rank({type, _   }) -> 100;
arg_name_rank(_           ) -> 0.

transpose([[]|_]) -> [];
transpose(M) ->
      [lists:map(fun erlang:hd/1, M) | transpose(lists:map(fun erlang:tl/1, M))].

info(F, A) ->
    io:format(F ++ "\n", A).

fail(F, A) ->
    io:put_chars(standard_error, io_lib:format(F ++ "\n", A)),
    halt(1).


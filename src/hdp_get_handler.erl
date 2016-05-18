-module(hdp_get_handler).
-export([init/3]).
-export([handle/2]).
-export([terminate/3]).


init(_Transport, Req, []) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	io:format("Get Req ::~p~n~n",[Req]),
	{Method, Req2} = cowboy_req:method(Req),
	{AllValues, Req3} = cowboy_req:qs_vals(Req2),
	UserId = proplists:get_value(<<"user_id">>,AllValues),
	io:format("user_id::~p~n",[UserId]),
	{ok, Req4} = get_user_val(Method, UserId, Req3),
	{ok, Req4, State}.

get_user_val(<<"GET">>, undefined, Req) ->
	cowboy_req:reply(400, [], <<"Missing mtq parameter.">>, Req);
get_user_val(<<"GET">>, UserId, Req) ->
	Reply = hdp:get_user_vals_4_py(UserId),
	io:format("Reply::~p~n",[Reply]),	
	cowboy_req:reply(200, [
		{<<"content-type">>, <<"text/plain; charset=utf-8">>}
	], Reply, Req);
get_user_val(_, _, Req) ->
	%% Method not allowed.
	cowboy_req:reply(405, Req).

terminate(_Reason, _Req, _State) ->
	ok.
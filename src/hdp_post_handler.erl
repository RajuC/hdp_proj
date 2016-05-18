-module(hdp_post_handler).
-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

-define(BUC,"reg_details").

init(_Transport, Req, _Optns) ->
	{ok, Req, undefined}.

handle(Req, State) ->
	io:format("Req to server :~p~n",[Req]),
	{Method, Req2} = cowboy_req:method(Req),
	HasBody = cowboy_req:has_body(Req2),
	{ok, Req3} = post_qn_vals(Method, HasBody, Req2),
	{ok, Req3, State}.
	post_qn_vals(<<"POST">>, true, Req) ->
		PostValss =
		case cowboy_req:body_qs(Req) of
			{ok, [{PostVals,_}], _} ->
				PostVals;
			{ok, PostVals, _} ->
				PostVals
		end, 		
	Reply = 
	case proplists:get_value(<<"action">>,PostValss) of
			<<"login">> ->
				hdp:login(PostValss);
			<<"signup">> ->
				hdp:signup(PostValss);
			<<"user_info">> ->
				hdp:user(PostValss);
			<<"prediction">> ->
				hdp:prediction(PostValss);	
			_Other ->
				<<"unknown_action">>
	end,
	
%%Reply = <<"success">>,
	cowboy_req:reply(200, [
		{<<"content-type">>, <<"text/plain; charset=utf-8">>}
	], Reply, Req);
post_qn_vals(<<"POST">>, false, Req) ->
	cowboy_req:reply(400, [], <<"Missing body.">>, Req);
post_qn_vals(_, _, Req) ->
	%% Method not allowed.
	cowboy_req:reply(405, Req).


terminate(_Reason, _Req, _State) ->
	ok.

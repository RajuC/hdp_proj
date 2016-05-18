-module(hdp_proj_app).
-behaviour(application).

-export([start/2]).
-export([stop/1]).

start(_Type, _Args) ->
	start_web(),
	hdp_proj_sup:start_link().

stop(_State) ->
	ok.

start_web() ->
    PrivDir = code:priv_dir(hdp_proj),
    Dispatch = cowboy_router:compile([
      {'_', [
        {"/", cowboy_static, {priv_file, hdp_proj, "index.html"}},
        {"/signup", hdp_post_handler, []},
        {"/login", hdp_post_handler, []},
        {"/user", hdp_post_handler, []},
        {"/pypost", hdp_post_handler, []}, 
        {"/pyget", hdp_get_handler, []}, 
        {"/[...]", cowboy_static, {priv_dir, hdp_proj, ""
            }},
        {"/[...]", cowboy_static, {PrivDir++"/css/", hdp_proj, ""
            }},
        {"/[...]", cowboy_static, {PrivDir++"/images/", hdp_proj, ""
            }},
        {"/[...]", cowboy_static, {PrivDir++"/META-INF/", hdp_proj, ""
            }},
        {"/[...]", cowboy_static, {PrivDir++"/WEB-INF/", hdp_proj, ""
            }},                  
        {"/[...]", cowboy_static, {PrivDir++"/fonts/", hdp_proj, ""
            }},    
        {"/[...]", cowboy_static, {PrivDir++"/js/", hdp_proj, ""
            }},
        {"/[...]", cowboy_static, {PrivDir++"/spark/", hdp_proj, ""
            }}           
        ]}
     ]),
    Port = application:get_env(hdp_proj, http_port, 80),
    {ok, _} = cowboy:start_http(http, 100, [{port, Port}], [
        {env, [{dispatch, Dispatch}]}
       ]).

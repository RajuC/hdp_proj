PROJECT = hdp_proj
DEPS = cowboy jsx riakc riak_store erlport

dep_riak_store = git git@github.com:RajuC/riak_store.git master

include erlang.mk
%%%-------------------------------------------------------------------
%% @doc foobar public API
%% @end
%%%-------------------------------------------------------------------

-module(foobar_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    foobar_sup:start_link().

stop(_State) ->
    ok.

%% internal functions

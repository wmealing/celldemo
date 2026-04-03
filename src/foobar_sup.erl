%%%-------------------------------------------------------------------
%% @doc foobar top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(foobar_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 5,
        period => 10
    },
    ChildSpecs = [
        #{
            id => data,
            start => {data, start_link, []},
            restart => permanent,
            type => worker
        }
    ],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions

-module(data).

-behaviour(gen_server).

%% API
-export([start_link/0, save_customer/4, update_customer/5, get_all_customers/0, search_by_email/1, stop/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(customer, {
    id,
    first_name,
    last_name,
    phone,
    email
}).

-define(SERVER, ?MODULE).
-define(DB_FILE, "customers.dets").

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

save_customer(FirstName, LastName, Phone, Email) ->
    gen_server:call(?SERVER, {save_customer, FirstName, LastName, Phone, Email}).

update_customer(Id, FirstName, LastName, Phone, Email) ->
    gen_server:call(?SERVER, {update_customer, Id, FirstName, LastName, Phone, Email}).

get_all_customers() ->
    gen_server:call(?SERVER, get_all_customers).

search_by_email(Email) ->
    gen_server:call(?SERVER, {search_by_email, Email}).

stop() ->
    gen_server:stop(?SERVER).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    case dets:open_file(customers, [
        {file, ?DB_FILE},
        {type, set},
        {keypos, #customer.id}
    ]) of
        {ok, _} -> {ok, #{}};
        {error, Reason} -> {stop, Reason}
    end.

handle_call({save_customer, FirstName, LastName, Phone, Email}, _From, State) ->
    Id = erlang:unique_integer([positive]),
    Customer = #customer{
        id = Id,
        first_name = FirstName,
        last_name = LastName,
        phone = Phone,
        email = Email
    },
    Result = dets:insert(customers, Customer),
    dets:sync(customers),
    {reply, {Result, Id}, State};

handle_call({update_customer, Id, FirstName, LastName, Phone, Email}, _From, State) ->
    Customer = #customer{
        id = Id,
        first_name = FirstName,
        last_name = LastName,
        phone = Phone,
        email = Email
    },
    Result = dets:insert(customers, Customer),
    dets:sync(customers),
    {reply, {Result, Id}, State};

handle_call(get_all_customers, _From, State) ->
    Customers = dets:match_object(customers, '_'),
    {reply, Customers, State};

handle_call({search_by_email, Email}, _From, State) ->
    All = dets:match_object(customers, '_'),
    Results = lists:filter(fun(#customer{email = E}) ->
        string:find(string:lowercase(E), string:lowercase(Email)) =/= nomatch
    end, All),
    {reply, Results, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Request, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    dets:close(customers),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

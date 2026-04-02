-module(data).

-export([init/0, save_customer/4, update_customer/5, get_all_customers/0, search_by_email/1, close/0]).

-record(customer, {
    id,
    first_name,
    last_name,
    phone,
    email
}).

-define(DB_FILE, "customers.dets").

init() ->
    {ok, _} = dets:open_file(customers, [
        {file, ?DB_FILE},
        {type, set},
        {keypos, #customer.id}
    ]),
    ok.

save_customer(FirstName, LastName, Phone, Email) ->
    Id = erlang:unique_integer([positive]),
    Customer = #customer{
        id = Id,
        first_name = FirstName,
        last_name = LastName,
        phone = Phone,
        email = Email
    },
    ok = dets:insert(customers, Customer),
    ok = dets:sync(customers),
    {ok, Id}.

update_customer(Id, FirstName, LastName, Phone, Email) ->
    Customer = #customer{
        id = Id,
        first_name = FirstName,
        last_name = LastName,
        phone = Phone,
        email = Email
    },
    ok = dets:insert(customers, Customer),
    ok = dets:sync(customers),
    {ok, Id}.

get_all_customers() ->
    case dets:info(customers) of
        undefined -> [];
        _ -> dets:match_object(customers, '_')
    end.

search_by_email(Email) ->
    case dets:info(customers) of
        undefined -> [];
        _ ->
            All = dets:match_object(customers, '_'),
            lists:filter(fun(#customer{email = E}) ->
                string:find(string:lowercase(E), string:lowercase(Email)) =/= nomatch
            end, All)
    end.

close() ->
    dets:close(customers).

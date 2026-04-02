-module(customer_search).

-behavior(cellium).
-include_lib("cellium/include/cellium.hrl").

-export([init/1, render/1, update/2, start/0, build_search_screen/1, build_form_screen/1]).

init(_Args) ->
    data:init(),

    Model = #{
        current_screen => search,
        search_email => text_input:state(""),
        first_name => text_input:state(""),
        last_name => text_input:state(""),
        phone_number => text_input:state(""),
        email => text_input:state(""),
        focused_id => undefined,
        search_results => [],
        selected_result_index => 0,
        editing_customer_id => undefined
    },

    SearchTree = cellium_dsl:from_dsl(build_search_screen(Model)),
    SearchScreen = screen:new(search_screen, SearchTree),
    screen:replace(SearchScreen),

    {ok, Model}.

update(Model, Msg) ->
    case Msg of
        {key, _, _, _, _, <<"q">>} ->
            cellium:stop(),
            Model;
        {key, _, _, _, _, <<"Q">>} ->
            cellium:stop(),
            Model;
        {focus_changed, NewFocusedId} ->
            Model#{focused_id => NewFocusedId};
        {key, _, _, _, _, _} = KeyEvent ->
            case focus_manager:get_focused() of
                {ok, Id} -> handle_focused_key(Id, KeyEvent, Model);
                _ -> Model
            end;
        _ ->
            Model
    end.

handle_focused_key(search_input, {key, _, _, _, _, enter_key}, Model) ->
    SearchEmail = maps:get(text, maps:get(search_email, Model)),
    Results = data:search_by_email(SearchEmail),
    case Results of
        [] ->
            Model#{search_results => Results, selected_result_index => 0};
        _ ->
            focus_manager:set_focus(results_list),
            Model#{search_results => Results, selected_result_index => 0}
    end;
handle_focused_key(search_input, Event, Model) ->
    NewState = text_input:handle_event(Event, maps:get(search_email, Model)),
    Model#{search_email => NewState};
handle_focused_key(results_list, Event, Model) ->
    OldState = results_list:state(
        maps:get(search_results, Model),
        maps:get(selected_result_index, Model)
    ),
    NewState = results_list:handle_event(Event, OldState),
    case maps:get(selected_customer, NewState, undefined) of
        undefined ->
            Model#{selected_result_index => maps:get(selected_index, NewState)};
        Customer ->
            CustomerId = element(2, Customer),
            FirstName = element(3, Customer),
            LastName = element(4, Customer),
            Phone = element(5, Customer),
            Email = element(6, Customer),

            UpdatedModel = Model#{
                current_screen => form,
                first_name => text_input:state(FirstName),
                last_name => text_input:state(LastName),
                phone_number => text_input:state(Phone),
                email => text_input:state(Email),
                editing_customer_id => CustomerId,
                selected_result_index => maps:get(selected_index, NewState)
            },

            {ok, SearchScreen} = screen:current(),
            FormTree = cellium_dsl:from_dsl(build_form_screen(UpdatedModel)),
            FormScreen = screen:new(form_screen, FormTree),
            screen:transition(SearchScreen, FormScreen),

            UpdatedModel
    end;
handle_focused_key(new_customer_btn, {key, _, _, _, _, Key}, Model) when Key == enter_key; Key == <<" ">> ->
    UpdatedModel = Model#{
        current_screen => form,
        first_name => text_input:state(""),
        last_name => text_input:state(""),
        phone_number => text_input:state(""),
        email => text_input:state(""),
        editing_customer_id => undefined
    },

    {ok, SearchScreen} = screen:current(),
    FormTree = cellium_dsl:from_dsl(build_form_screen(UpdatedModel)),
    FormScreen = screen:new(form_screen, FormTree),
    screen:transition(SearchScreen, FormScreen),

    UpdatedModel;
handle_focused_key(exit_btn, {key, _, _, _, _, Key}, Model) when Key == enter_key; Key == <<" ">> ->
    cellium:stop(),
    Model;
handle_focused_key(first_name_input, Event, Model) ->
    NewState = text_input:handle_event(Event, maps:get(first_name, Model)),
    Model#{first_name => NewState};
handle_focused_key(last_name_input, Event, Model) ->
    NewState = text_input:handle_event(Event, maps:get(last_name, Model)),
    Model#{last_name => NewState};
handle_focused_key(phone_input, Event, Model) ->
    NewState = text_input:handle_event(Event, maps:get(phone_number, Model)),
    Model#{phone_number => NewState};
handle_focused_key(email_input, Event, Model) ->
    NewState = text_input:handle_event(Event, maps:get(email, Model)),
    Model#{email => NewState};
handle_focused_key(save_btn, {key, _, _, _, _, Key}, Model) when Key == enter_key; Key == <<" ">> ->
    FirstName = maps:get(text, maps:get(first_name, Model)),
    LastName = maps:get(text, maps:get(last_name, Model)),
    Phone = maps:get(text, maps:get(phone_number, Model)),
    Email = maps:get(text, maps:get(email, Model)),
    EditingId = maps:get(editing_customer_id, Model),
    case EditingId of
        undefined ->
            {ok, _Id} = data:save_customer(FirstName, LastName, Phone, Email);
        _ ->
            {ok, _Id} = data:update_customer(EditingId, FirstName, LastName, Phone, Email)
    end,

    UpdatedModel = Model#{
        current_screen => search,
        first_name => text_input:state(""),
        last_name => text_input:state(""),
        phone_number => text_input:state(""),
        email => text_input:state(""),
        editing_customer_id => undefined
    },

    {ok, FormScreen} = screen:current(),
    SearchTree = cellium_dsl:from_dsl(build_search_screen(UpdatedModel)),
    SearchScreen = screen:new(search_screen, SearchTree),
    screen:transition(FormScreen, SearchScreen),

    UpdatedModel;
handle_focused_key(cancel_btn, {key, _, _, _, _, Key}, Model) when Key == enter_key; Key == <<" ">> ->
    UpdatedModel = Model#{
        current_screen => search,
        first_name => text_input:state(""),
        last_name => text_input:state(""),
        phone_number => text_input:state(""),
        email => text_input:state(""),
        editing_customer_id => undefined
    },

    {ok, FormScreen} = screen:current(),
    SearchTree = cellium_dsl:from_dsl(build_search_screen(UpdatedModel)),
    SearchScreen = screen:new(search_screen, SearchTree),
    screen:transition(FormScreen, SearchScreen),

    UpdatedModel;
handle_focused_key(_Id, _Event, Model) ->
    Model.

render(Model) ->
    case maps:get(current_screen, Model) of
        search -> build_search_screen(Model);
        form -> build_form_screen(Model)
    end.

build_search_screen(Model) ->
    Results = maps:get(search_results, Model),
    SelectedIndex = maps:get(selected_result_index, Model),

    StatusText = io_lib:format("Tab: Navigate | Q: Quit | Up/Down: Select", []),

    {vbox, [{id, main}, {padding, 0}], [
        {vbox, [{id, content}, {expand, true}, {padding, 1}], [
            {header, [{id, header}, {color, cyan}], "Customer Search"},
            {spacer, [{size, 1}]},

            {hbox, [{id, search_row}, {size, 3}], [
                {vbox, [{id, search_label_container}, {size, 15}], [
                    {spacer, [{size, 1}]},
                    {text, [{id, search_label}], "Email Address: "}
                ]},
                {box, [{id, search_box}, {size, 3}, {expand, true}, {color, white}], [
                    {text_input, [{id, search_input}, {state, maps:get(search_email, Model)}, {expand, true}]}
                ]}
            ]},

            {spacer, [{size, 1}]},

            {box, [{id, results_box}, {expand, true}, {color, yellow}], [
                {custom, results_list, [{id, results_list}, {state, results_list:state(Results, SelectedIndex)}]}
            ]},

            {spacer, [{size, 1}]},

            {hbox, [{id, button_row}, {size, 3}], [
                {spacer, [{expand, true}]},
                {button, [{id, new_customer_btn}, {color, green}, {size, 15}], "New Customer"},
                {spacer, [{size, 2}]},
                {button, [{id, exit_btn}, {color, red}, {size, 10}], "Exit"},
                {spacer, [{expand, true}]}
            ]},

            {spacer, [{size, 1}]}
        ]},
        {status_bar, [{id, status}, {color, white}], lists:flatten(StatusText)}
    ]}.

build_form_screen(Model) ->
    StatusText = io_lib:format("Tab: Navigate | Q: Quit", []),

    {vbox, [{id, main}, {padding, 0}], [
        {vbox, [{id, content}, {expand, true}, {padding, 1}], [
            {header, [{id, header}, {color, cyan}], "Customer Information Form"},
            {spacer, [{size, 1}]},

            {hbox, [{id, name_row}, {size, 3}], [
                {vbox, [{id, first_label_container}, {size, 15}], [
                    {spacer, [{size, 1}]},
                    {text, [{id, first_label}], "First Name: "}
                ]},
                {box, [{id, first_box}, {size, 3}, {expand, true}, {color, white}], [
                    {text_input, [{id, first_name_input}, {state, maps:get(first_name, Model)}, {expand, true}]}
                ]}
            ]},

            {spacer, [{size, 1}]},

            {hbox, [{id, last_row}, {size, 3}], [
                {vbox, [{id, last_label_container}, {size, 15}], [
                    {spacer, [{size, 1}]},
                    {text, [{id, last_label}], "Last Name: "}
                ]},
                {box, [{id, last_box}, {size, 3}, {expand, true}, {color, white}], [
                    {text_input, [{id, last_name_input}, {state, maps:get(last_name, Model)}, {expand, true}]}
                ]}
            ]},

            {spacer, [{size, 1}]},

            {hbox, [{id, phone_row}, {size, 3}], [
                {vbox, [{id, phone_label_container}, {size, 15}], [
                    {spacer, [{size, 1}]},
                    {text, [{id, phone_label}], "Phone Number: "}
                ]},
                {box, [{id, phone_box}, {size, 3}, {expand, true}, {color, white}], [
                    {text_input, [{id, phone_input}, {state, maps:get(phone_number, Model)}, {expand, true}]}
                ]}
            ]},

            {spacer, [{size, 1}]},

            {hbox, [{id, email_row}, {size, 3}], [
                {vbox, [{id, email_label_container}, {size, 15}], [
                    {spacer, [{size, 1}]},
                    {text, [{id, email_label}], "Email: "}
                ]},
                {box, [{id, email_box}, {size, 3}, {expand, true}, {color, white}], [
                    {text_input, [{id, email_input}, {state, maps:get(email, Model)}, {expand, true}]}
                ]}
            ]},

            {spacer, [{size, 2}]},

            {hbox, [{id, button_row}, {size, 3}], [
                {spacer, [{expand, true}]},
                {button, [{id, cancel_btn}, {color, red}, {size, 10}], "Cancel"},
                {spacer, [{size, 2}]},
                {button, [{id, save_btn}, {color, green}, {size, 10}], "Save"},
                {spacer, [{expand, true}]}
            ]},

            {spacer, [{expand, true}]}
        ]},
        {status_bar, [{id, status}, {color, white}], lists:flatten(StatusText)}
    ]}.

start() ->
    application:ensure_all_started(cellium),
    cellium:start(#{
        module => ?MODULE,
        auto_focus => true
    }).

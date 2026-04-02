-module(results_list).

-export([render/2, render_focused/2, new/1, handle_event/2, state/2]).

-include("cellium.hrl").
-import(widget, [get_common_props/1]).

-spec new(term()) -> map().
new(Id) ->
    (widget:new())#{id => Id,
                    widget_type => results_list,
                    focusable => true,
                    type => widget}.

-spec state(list(), integer()) -> map().
state(Results, SelectedIndex) ->
    #{results => Results, selected_index => SelectedIndex}.

-spec handle_event(term(), map()) -> map().
handle_event({key, _, _, _, _, up_key}, State) ->
    CurrentIndex = maps:get(selected_index, State, 0),
    NewIndex = max(0, CurrentIndex - 1),
    State#{selected_index => NewIndex};
handle_event({key, _, _, _, _, down_key}, State) ->
    CurrentIndex = maps:get(selected_index, State, 0),
    Results = maps:get(results, State, []),
    NewIndex = min(length(Results) - 1, CurrentIndex + 1),
    State#{selected_index => NewIndex};
handle_event({key, _, _, _, _, enter_key}, State) ->
    Results = maps:get(results, State, []),
    SelectedIndex = maps:get(selected_index, State, 0),
    case length(Results) > SelectedIndex of
        true ->
            Customer = lists:nth(SelectedIndex + 1, Results),
            State#{selected_customer => Customer};
        false ->
            State
    end;
handle_event(_, State) ->
    State.

-spec render(map(), map()) -> map().
render(Widget, Buffer) ->
    render_list(Widget, Buffer, false).

-spec render_focused(map(), map()) -> map().
render_focused(Widget, Buffer) ->
    render_list(Widget, Buffer, true).

render_list(Widget, Buffer, _IsFocused) ->
    #{x := X, y := Y, fg := Fg, bg := Bg} = get_common_props(Widget),

    State = maps:get(state, Widget, #{results => [], selected_index => 0}),
    Results = maps:get(results, State, []),
    SelectedIndex = maps:get(selected_index, State, 0),

    case Results of
        [] ->
            cellium_buffer:put_string(X, Y, Fg, Bg, "No customers found", Buffer);
        _ ->
            render_results(X, Y, Fg, Bg, Results, SelectedIndex, 0, Buffer)
    end.

render_results(_X, _Y, _Fg, _Bg, [], _SelectedIndex, _CurrentIndex, Buffer) ->
    Buffer;
render_results(X, Y, Fg, Bg, [Customer | Rest], SelectedIndex, CurrentIndex, Buffer) ->
    Text = io_lib:format("~s ~s - ~s - ~s", [
        element(3, Customer),
        element(4, Customer),
        element(6, Customer),
        element(5, Customer)
    ]),

    {DisplayFg, DisplayBg} = case CurrentIndex of
        SelectedIndex -> {Bg, Fg};  % Invert colors for selected item
        _ -> {Fg, Bg}
    end,

    NewBuffer = cellium_buffer:put_string(X, Y + CurrentIndex, DisplayFg, DisplayBg, lists:flatten(Text), Buffer),
    render_results(X, Y, Fg, Bg, Rest, SelectedIndex, CurrentIndex + 1, NewBuffer).

foobar
=====

A demo OTP application showcasing Erlang/OTP patterns.

Build
-----

    $ rebar3 compile

Run
---

Run examples using:

    $ make run example=customer_search

Available examples:
- customer_search
- customer_form
- results_list

Custom Widgets
--------------

This demo includes custom widgets not part of cellium:

- `results_list` - Custom widget for displaying search results with keyboard navigation. Used in customer_search via `{custom, results_list, [...]}` syntax.

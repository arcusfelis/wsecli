%% @hidden
-module(wsecli_socket).
-include("wsecli.hrl").

-export([open/5]).
-export([send/2]).
-export([close/1]).

-export([notify_client/2]).

%%========================================
%% Types
%%========================================
-type socket_type()       :: plain | ssl.
-type client_notification() :: close | {data, binary()} | {error, term()}.


%%========================================
%% Constants
%%========================================
-define(DEFAULT_SOCKET_OPTIONS, [binary, {reuseaddr, true}, {packet, raw}]).

%%========================================
%% Client API
%%========================================
-spec open(
  Host    :: string(),
  Port    :: inet:port_number(),
  Type    :: socket_type(),
  Client  :: pid(),
  Opts    :: list()
  ) ->
  {ok, socket()} |
  {error, term()}.
open(Host, Port, Type, Client, Opts) ->
  Opts2 = substitute_default_options(Opts),
  open_2(Host, Port, Type, Client, Opts2).

open_2(Host, Port, plain, Client, Opts) ->
  wsecli_socket_plain:start_link(Host, Port, Client, Opts);
open_2(Host, Port, ssl, Client, Opts) ->
  wsecli_socket_ssl:start_link(Host, Port, Client, Opts).

%% You can pass `[default]' as an option list and it will be rewritten
substitute_default_options([default|T]) ->
  ?DEFAULT_SOCKET_OPTIONS ++ substitute_default_options(T);
substitute_default_options([H|T]) ->
  [H|substitute_default_options(T)];
substitute_default_options([]) ->
  [].

-spec send(
  Data   :: iolist(),
  Socket :: socket()
  ) -> ok.
send(Data, Socket) ->
  Socket ! {socket, send, Data},
  ok.

-spec close(
  Socket :: socket()
  ) -> ok.
close(Socket) ->
  Socket ! {socket, close},
  ok.

%%========================================
%% Socket API to interact with client
%%========================================
-spec notify_client(
  What   :: client_notification(),
  Client :: pid()
  ) -> ok.
notify_client(What, Client) ->
  Client ! {socket, What},
  ok.

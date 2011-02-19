-module(getr).
-export([getr/1]).
-export([init/1, handle_event/2]).
-export([loop/2]).
-export([info/0, start/0, stop/0]).

% derived from
% poor man's irc client at http://alphajor.blogspot.com/2010/12/poor-mans-erlang-irc-client-i-need.html
% this one just sends a GET request to my site
% that's all
% and there isn't any more
% erl
% c(getr).
% getr:start().
%
getr(ClientPid) ->
	Result = gen_tcp:connect("www.bilalhusain.com", 80, [binary,
								{active, true},
								{packet, line},
								{keepalive, true},
								{nodelay, true}]),
	io:format("connecting...~n"),

	case Result of
		{ok, Socket} ->
			io:format("connected...~n"),
			Pid = spawn(fun() -> loop(ClientPid, Socket) end),
			gen_tcp:controlling_process(Socket, Pid),
			Pid ! {send, self(), "GET /404 HTTP/1.1\r\nHost: bilalhusain.com\r\nConnection: Close\r\n\r\n"},
			Pid;
		{error, Reason} ->
			io:format("Error ~p~n", [Reason]),
			error
	end.

info() ->
	io:format("nothing here~n").

start() ->
	gen_event:start({local, ?MODULE}),
	gen_event:add_handler(?MODULE, ?MODULE,[]).

stop() ->
	gen_event:stop(?MODULE).

loop(ClientPid, Socket) ->
	receive
		{tcp, _Socket, Data} ->
			gen_event:notify(?MODULE, {recv, Data}),
			loop(ClientPid, Socket);
		{tcp_closed, _Socket} ->
			io:format("Closed.~n"),
			ok;
		{tcp_error, _Socket, Reason} ->
			io:format("Error ~p~n", [Reason]),
			ok;
		{send, ClientPid, Data} ->
			io:format("sending...~p~n", [Data]),
			gen_tcp:send(Socket, Data),
			loop(ClientPid, Socket);
		{close, ClientPid} ->
			gen_tcp:close(Socket),
			io:format("Connected closed~n"),
			ok;
		Msg ->
			io:format("Received ~p~n", [Msg])
	end.

init(ARGS) ->
	Pid = getr(self()),
	State = {disconnected, Pid},
	{ok, State}.

handle_event({recv, Line}, State) ->
	io:format("Got ~s", [binary_to_list(Line)]),
	{ok, State}.

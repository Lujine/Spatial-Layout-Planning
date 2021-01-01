:-use_module(library('plot/axis')).

plot(Apartments, P):-
    new(P, picture('Floor Demo')),
    % get(P, size, size(10, 10)),
    send(P, open),
    % send(P, display, new(_, box(FloorWidth,FloorHeight))),
    plot_apartments(Apartments, P).

plot_apartments([], _).
plot_apartments([AH | AT], P):-
    plot_rooms(AH, P),
    plot_apartments(AT, P).

plot_rooms([], _).
plot_rooms([RH | RT], P):-
    print("plotting room: "), print(RH), nl,
    RH = r(X, W, Y, H),
    X1 is X * 10,
    W1 is W * 10,
    Y1 is Y * 10,
    H1 is H * 10,
    send(P, display, new(_, box(W1,H1)), point(X1,Y1)),
    plot_rooms(RT, P).



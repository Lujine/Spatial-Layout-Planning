:-include('main.pl').
:-include('plot.pl').

test(Apartments, Types, OuterHallways,Elevator,GlobalConstraints):-
	Width = 38,
	Height = 38,

	% Apt type 1
	NumRooms = 8,
	RoomTypes = [0, 4, 0, 2, 1, 3, 5, 7],
	RoomSizes = [5, 5, 5, 5, 5, 5, 5, 5],
	Landscapes = [0,1,0,1],
	Open = [0,1,0,0],
	input(Width, Height, Landscapes, Open, [apt_type(NumRooms, RoomTypes, RoomSizes, _, _)], [2], Apartments, Types, OuterHallways,Elevator,GlobalConstraints),
	plot(Apartments, P),
	plot_rooms(OuterHallways, P).
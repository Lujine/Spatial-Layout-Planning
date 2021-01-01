:-include('main.pl').

test(Apartments, Hallways):-
	Width = 38,
	Height = 38,

	% Apt type 1
	NumRooms = 8,
	RoomTypes = [0, 4, 0, 2, 1, 3, 5, 8],
	RoomSizes = [5,5,5,5,5,5,5,5],
	input(Width, Height, _, _, [apt_type(NumRooms, RoomTypes, RoomSizes, _, _)], [2], Apartments, Hallways).
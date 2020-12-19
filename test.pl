:-include('main.pl').

test(Apartments, Hallways):-
	 input(10, 10, _, _, [apt_type(2, [room1, room2], [5,5], _, _)], [3], Apartments, Hallways).
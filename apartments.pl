:-use_module(library(clpfd)).

sun_room(FloorWidth, FloorHeight, Coord, IsSunRoom):-
	Coord = [X, W, Y, H],
	X #= 0 #<==> IsAtLeft,
	Y #= 0 #<==> IsAtTop,
	X + W #= FloorWidth #<==> IsAtRight,
	Y + H #= FloorHeight #<==> IsAtBottom,
	(IsAtLeft #\/ IsAtTop #\/ IsAtRight #\/ IsAtBottom) #<==> IsSunRoom.

/* 
    Send AptH + AptType to predicate 
    6 (dressing) adj to next which must be 0 (bedroom)
    4 (minor bath) adj to next, unless at end of list
    2 (dining) adj to next, which must be 1 kitchen
*/
adjacentRooms([_], [_]).
adjacentRooms([RoomH1 | RoomT], [TypeH | TypeT]):-

	RoomT = [RoomH2 | _],
	TypeT = [TypeH2 | _],

	adjacent(RoomH1, RoomH2, Adj),

	TypeH #= 6 #<==> IsDressing,
	IsDressing #==> Adj,
	IsDressing #==> TypeH2 #= 0,

	TypeH #= 4 #<==> IsMinorBath,
	IsMinorBath #==> Adj,

	TypeH #= 2 #<==> IsDining,
	IsDining #==> TypeH2 #= 1,
	IsDining #==> Adj,

	adjacentRooms(RoomT, TypeT).

addHalls(FloorWidth, FloorHeight, Rooms, NumRooms, Hallways, Types, NumHallways, Coords):-
	length(Hallways, NumHallways),
	Max #= (NumRooms div 2),
	NumHallways in 1..Max,

	createInnerHalls(FloorWidth, FloorHeight, Hallways, Types, Coords),
	room_hall_connect(Rooms, Hallways).

createInnerHalls(_, _, [], [], []).
createInnerHalls(FloorWidth, FloorHeight, [HallH | HallT], [TypeH | TypeT], Coord):-
	create_rect(FloorWidth, FloorHeight, HallH, CoordH),
	TypeH #= 8,
	createInnerHalls(FloorWidth, FloorHeight, HallT, TypeT, CoordT),
	append(CoordH ,CoordT, Coord).

room_hall_connect([], _).
room_hall_connect([RoomH | RoomT], Halls):-
	roomToHallwayConnectivity1(RoomH, Halls, Count),
	% print(RoomH), print(" count "), print(Count), nl,
	Count #> 0,
	room_hall_connect(RoomT, Halls).

roomToHallwayConnectivity1(_,[],0).
roomToHallwayConnectivity1(Room, [HallH | HallT], Count):-
	adjacent(Room, HallH, Adj),
	roomToHallwayConnectivity1(Room, HallT, Count2),
	Count #= Count2 + Adj.
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

addInnerHalls(FloorWidth, FloorHeight, Rooms, NumRooms, Hallways, Types, NumHallways, Coords):-
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

addOuterHalls(FloorWidth, FloorHeight, InHallways, OutHall, OutHallCoordH):-
	create_rect(FloorWidth, FloorHeight, OutHall, OutHallCoordH),
	roomToHallwayConnectivity2(OutHall, InHallways, Count),
	Count #>= 1.

% add_ducts(FloorWidth, FloorHeight, Rooms, Types, Ducts, TypesDuct):-
% 	findall(Room, (nth1(N, Rooms, Room), nth1(N, Types, Type), Type #= 1), Kitchens),
% 	findall(Room, (nth1(N, Rooms, Room), nth1(N, Types, Type), Type #= 3), Bathrooms),
% 	findall(Room, (nth1(N, Rooms, Room), nth1(N, Types, Type), Type #= 4), MinorBathrooms),
% 	append(Bathrooms, MinorBathrooms, Bathrooms),
% 	append(Bathrooms, Kitchens, NeedDucts),
% 	put_ducts(FloorWidth, FloorHeight, NeedDucts, Ducts, TypesDuct).

% put_ducts(FloorWidth, FloorHeight, NeedDucts, Ducts, TypesDuct):-
% 	true.

roomToHallwayConnectivity1(_,[],0).
roomToHallwayConnectivity1(Room, [HallH | HallT], Count):-
	adjacent(Room, HallH, Adj),
	roomToHallwayConnectivity1(Room, HallT, Count2),
	Count #= Count2 + Adj.

roomToHallwayConnectivity2(_,[],0).
roomToHallwayConnectivity2(Hall, [RoomH | RoomT], Count):-
	adjacent(Hall, RoomH, Count1),
	roomToHallwayConnectivity1(Hall, RoomT, Count2),
	Count #= Count1 + Count2.

create_elevator(FloorWidth, FloorHeight, OuterHallways, Elevator, ElevatorCoord):-
	create_rect(FloorWidth, FloorHeight, Elevator, ElevatorCoord),
	roomToHallwayConnectivity2(Elevator, OuterHallways, Count),
	Count #> 0.

create_ducts(_, _, [], [], [], []).
create_ducts(FloorWidth, FloorHeight, [AptH|AptT], [TypeH|TypeT], [DH|DT], [CoH|CoT]):-
	create_rect(FloorWidth, FloorHeight, DH, CoH),
	ductToKitchenBathroomConnectivity(DH,AptH,TypeH),
	create_ducts(FloorWidth, FloorHeight, AptT, TypeT, DT, CoT).

ductToKitchenBathroomConnectivity(_,[],[]).
ductToKitchenBathroomConnectivity(DH,[RoomH|RoomT],[TypeH|TypeT]):-
	adjacent(RoomH, DH, Adj),
	% (TypeH#=3 #\/ TypeH#=4 #\/ TypeH#=1) #<==> Adj,
	ductToKitchenBathroomConnectivity(DH,RoomT,TypeT).

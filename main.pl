:-use_module(library(clpfd)).
:-include('rectangle_helpers.pl').

/**********************************************************************
*******************************Structs*********************************
Generic rectangle:
	r(UpperLeftCornerX, Width, UpperLeftCornerY, Height)
Apartment Type:
	apt_type(Num, RoomsTypes, MinRoomSize, Widths, Heights)
		Num = number of rooms in the apartment
		RoomsTypes is a list of the room types ex. [bedroom, bathroom, kitchen]
		MinRoomSize is a list of the minimum size for each room
		Widths is an optional list of the width of each room
		Heights is an optional list of the height of each room
		
Specific retangles:
	apt(UpperLeftCornerX, Width, UpperLeftCornerY, Height)
	hall(UpperLeftCornerX, Width, UpperLeftCornerY, Height)

Room types:
0 Bedroom
1 Kitchen
2 Dining Room
3 Master bathroom
4 Minor bathroom
5 Living Room
6 Dressing room
7 Sun room

8 Hallway
**********************************************************************
**********************************************************************/
	
input(FloorWidth, FloorHeight, Landscapes, Open, AptTypes, NumApts, Apartments, Hallways):-
	% Test Cases
	/*
	FloorWidth = 10, 
	FloorHeight = 10,
	AptTypes = [
				apt_type(_,_,[24], _,_),
				apt_type(_,_,[24], _,_)
	],
	NumApts = [2, 2],
	*/
	% Domains
	FloorWidth in 10..500,
	FloorHeight in 10..500,
	NumApts ins 1..10,

	% Variables
	TotalArea #= FloorWidth * FloorHeight,
	sum(NumApts, #=, TotalNumApts),
	
	% Apartment and External Hallways Layout Constraints
	maplist(createApts(FloorWidth, FloorHeight), AptTypes, NumApts, ApartmentsList, AptCoordList),
	append(ApartmentsList, Apartments),
	append(AptCoordList, Coords),
	% NumHallways#=TotalNumApts,
	MinLengthHall #= FloorHeight div TotalNumApts,
	MinWidthHall #= FloorWidth div TotalNumApts,
	createHallways(FloorWidth, FloorHeight, TotalNumApts,MinLengthHall ,MinWidthHall,NumHallways, Hallways, HallCoordList),
	checkAdjacency(Hallways),

	checkConnectivity(Apartments,Hallways,NumConnected),
	
	NumConnected#=TotalNumApts,

	append(Apartments, Rooms),
	append(Rooms, Hallways, Floor),
	disjoint2(Floor),

	% Utility of Apartments and Hallways
	apts_util(Apartments, ApartmentsArea),
	calc_util(Hallways, HallsArea),
	TotalArea #= ApartmentsArea + HallsArea,
	
	append([NumHallways| HallCoordList], Coords, Label),
	labeling([], Label).
	
/****************************createApts*********************************
creates all apartments of some type "AptType"
this apartment type exists "NumApts" times on the floor
***********************************************************************/
createApts(_, _, _, 0, [], []).	
createApts(FloorWidth, FloorHeight, AptType, NumApts, [AptH | AptT], Coords):-
	NumApts #> 0,

	createAptRooms(FloorWidth, FloorHeight, AptType, AptH, CoorH),
	append(CoorH, CoorT, Coords),

	% Dressing room adj to bedroom
	% Minor bathroom adjacent to room
	% dining adjacent to kitchen
	% print(AptH),nl,nl,
	AptType = apt_type(_, Types, _, _, _),
	adjacentRooms(AptH, Types),


	Counter #= NumApts - 1,
	createApts(FloorWidth, FloorHeight, AptType, Counter, AptT, CoorT).

/**************************createAptRooms*******************************
creates the rooms in an apartment
***********************************************************************/
createAptRooms(_, _, apt_type(0, _, _, _, _), [], []).
createAptRooms(FloorWidth, FloorHeight, AptType, [RoomH | RoomT], Coords):-

	%AptType = apt_type(NumRooms, RoomTypes, MinRoomSize, Widths, Heights),
	AptType = apt_type(NumRooms, [TypeH | TypeT], [MinSizeH | MinSizeT], _, _),
	NumRooms #> 0,
	
	createRoom(FloorWidth, FloorHeight, TypeH, MinSizeH, RoomH, CoorH),
	NumRoomsRem #= NumRooms - 1 ,
	AptTypeRem = apt_type(NumRoomsRem, TypeT, MinSizeT, _, _),
	createAptRooms(FloorWidth, FloorHeight, AptTypeRem, RoomT, CoorT),
	append(CoorH, CoorT, Coords).

/****************************createRoom*********************************
creates a single room
**********************************************************************/
createRoom(FloorWidth, FloorHeight, Type, MinRoomSize, Room, Coord):-
	create_rect_min_area(FloorWidth, FloorHeight, MinRoomSize, Room, Coord),
	
	% sun room exposed to day light
	(Type #= 7) #<==> ShouldBeSunRoom,
	sun_room(FloorWidth, FloorHeight, Coord, IsSunRoom),
	ShouldBeSunRoom #==> IsSunRoom.

/**************************createHallways*******************************
creates a variable number of hallways using the helper createHallwaysHelper
**********************************************************************/
createHallways(FloorWidth, FloorHeight, TotalNumApts,MinLengthHall ,MinWidthHall,NumHallways, Hallways, CoordList):-
	length(Hallways, NumHallways),
	NumHallways in 1..200,
	createHallwaysHelper(FloorWidth, FloorHeight, TotalNumApts,MinLengthHall ,MinWidthHall, Hallways, CoordList).
	
createHallwaysHelper(_, _, _, _, _, [], []).
createHallwaysHelper(FloorWidth, FloorHeight, TotalNumApts,MinLengthHall ,MinWidthHall, [HallH | HallT], Coord):-
	create_rect(FloorWidth, FloorHeight, HallH, CoordH),
	HallH= r(_,W,_,H),
	H#>MinLengthHall, %TODO figure out
	W#>MinWidthHall,
	createHallwaysHelper(FloorWidth, FloorHeight, TotalNumApts, MinLengthHall ,MinWidthHall,HallT, CoordT),
	append(CoordH ,CoordT, Coord).
	
/***************************apts_util*********************************
calculates the area of all appartments to check the utility
uses the helper calc_util which calculates the area of a list of rectangles
**********************************************************************/
apts_util([], 0).
apts_util([AH | AT], ApartmentsArea):-
	calc_util(AH, A1),
	apts_util(AT, A2),
	ApartmentsArea #= A1 + A2.
	
calc_util([], 0).	
calc_util([H | T], Area):-
	H = r(_, Width, _, Height),
	A1 #= Width * Height,
	calc_util(T, A2),
	Area #= A1 + A2.
	

/****************************checkConnectivity*********************************
makes sure all apartments are connected through hallways
takes in list of apartments, and list of hallways
***********************************************************************/
checkConnectivity([],_,0).
checkConnectivity([AptH|AptT],Hallways,B):-
	appartmentToHallwayConnectivity(AptH,Hallways,ConnectedRooms),
	ConnectedRooms#>=1 #<==> B1,
	checkConnectivity(AptT,Hallways,B2),
	B #=B1+B2.

/****************************appartmentToHallwayConnectivity*********************************
counts the number of rooms inside an apartment that are connected to hallways
takes in list of rooms, and list of hallways, returns a counter
***********************************************************************/
appartmentToHallwayConnectivity([],_,0).
appartmentToHallwayConnectivity([RoomH|RoomT],Hallways,Count):-
	roomToHallwayConnectivity(RoomH,Hallways,Count1),
	appartmentToHallwayConnectivity(RoomT,Hallways,Count2),
	Count #= Count1+Count2.


/****************************roomToHallwayConnectivity*********************************
counts the number of hallways 1 room is connected to
takes in a rooms, and a list of hallways, returns a counter
***********************************************************************/
roomToHallwayConnectivity(_,[],0).
roomToHallwayConnectivity(Room,[HallH|HallT],Count):-
	adjacent(Room,HallH,Adj),
	roomToHallwayConnectivity(Room,HallT,Count2),
	Count #= Count2+Adj.



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

	% print(RoomH1), print(" of type "), print(TypeH), nl,
	% print(RoomH2),  print(" of type "), print(TypeH2), nl,
	% print("Are adj? "), print(Adj), nl,

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

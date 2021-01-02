:-use_module(library(clpfd)).
:-include('rectangle_helpers.pl').
:-include('apartments.pl').

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
9 duct
**********************************************************************
**********************************************************************/
	
input(FloorWidth, FloorHeight, Landscapes, Open, AptTypes, NumApts, Apartments, Types, OuterHallways):-
	statistics(walltime, [_ | [_]]),

	% Domains
	FloorWidth in 10..500,
	FloorHeight in 10..500,
	NumApts ins 1..10,

	% Variables
	TotalArea #= FloorWidth * FloorHeight,
	sum(NumApts, #=, TotalNumApts),
	
	% Apartment and External Hallways Layout Constraints
	maplist(createApts(FloorWidth, FloorHeight), 
		AptTypes, NumApts, 
		ApartmentsList, Types,
		AptCoordList, XsList, WsList, YsList, HsList,
		InnerHallwaysList, NumInnerHallways
		),

	append(InnerHallwaysList, InnerHallways),
	% print(InnerHallways),nl,

	append(ApartmentsList, Apartments),
	append(AptCoordList, Coords),

	% append(XsList, Xs),
	% append(WsList, Ws),
	% append(YsList, Ys),
	% append(HsList, Hs),

	% append(Xs, Ws, HorizCoord),
	% append(Ys, Hs, VertCoord),
	% append(HorizCoord, VertCoord, CoordsOrg),

	addOuterHalls(FloorWidth, FloorHeight, TotalNumApts, OuterHallways, NumHallways, OuterHallwaysCoords),
	% checkConnectivity(InnerHallways, OuterHallways),
	% checkAdjacency(OuterHallways),

	% no overlap constraint
	append(Apartments, Rooms),
	append(Rooms, OuterHallways, Floor),
	disjoint2(Floor),

	% Utility of Apartments and Hallways
	apts_util(Apartments, ApartmentsArea),
	calc_util(OuterHallways, HallsArea),
	TotalArea #= ApartmentsArea + HallsArea,

	append(Coords, OuterHallwaysCoords, Label),
	labeling([], Label),


	statistics(walltime, [_ | [ExecutionTime]]),
	T is ExecutionTime / 60000,
	print("Execution took:"), print(T), print("seconds"), nl.
	
/*********************************************************************
Appartment Creation 
***********************************************************************/
% creates all apartments of some type "AptType"
% this apartment type exists "NumApts" times on the floor
createApts(_, _, _, 0, [], [], [], [], [], [], [], [], []).	
createApts(FloorWidth, FloorHeight, AptType, NumApts, 
			[AptH | AptT], [TypesAptH | TypesAptT],
			Coords, Xs, Ws, Ys, Hs, 
			[HallwaysH | HallwaysT], [NumHallwaysH | NumHallwaysT]
			):-

	NumApts #> 0,

	createAptRooms(FloorWidth, FloorHeight, AptType, AptRoomsH, CoorH, XsH, WsH, YsH, HsH),
	
	% Dressing room adj to bedroom + Minor bathroom adjacent to room + dining adjacent to kitchen
	AptType = apt_type(NumRooms, Types, _, _, _),
	adjacentRooms(AptRoomsH, Types),

	% add hallways
	addHalls(FloorWidth, FloorHeight, AptRoomsH, NumRooms, HallwaysH, TypesHallH, NumHallwaysH, HallCoordH),
	append(Types, TypesHallH, TypesAptH),
	append(CoorH, HallCoordH, AptCoords),
	append(AptRoomsH, HallwaysH, AptH),
	% add ducts
	% add_ducts(AptRoomsH, Types, Ducts);
	
	Counter #= NumApts - 1,
	createApts(FloorWidth, FloorHeight, AptType, Counter, AptT, TypesAptT, CoorT, XsT, WsT, YsT, HsT, HallwaysT, NumHallwaysT),
	append(AptCoords, CoorT, Coords),
	% append(HallwaysH, HallwaysT, Hallways),
	% print("Apt num: "), print(NumApts), print(" Coords: "), print(Coords), nl,

	append(XsH, XsT, Xs),
	append(WsH, WsT, Ws),
	append(YsH, YsT, Ys),
	append(HsH, HsT, Hs).


% creates the rooms in an apartment
createAptRooms(_, _, apt_type(0, _, _, _, _), [], [], [], [], [], []).
createAptRooms(FloorWidth, FloorHeight, AptType, [RoomH | RoomT], Coords, [X | XT], [W | WT], [Y | YT], [H | HT]):-

	%AptType = apt_type(NumRooms, RoomTypes, MinRoomSize, Widths, Heights),
	AptType = apt_type(NumRooms, [TypeH | TypeT], [MinSizeH | MinSizeT], _, _),
	NumRooms #> 0,
	
	createRoom(FloorWidth, FloorHeight, TypeH, MinSizeH, RoomH, CoorH, X, W, Y, H),
	NumRoomsRem #= NumRooms - 1,
	AptTypeRem = apt_type(NumRoomsRem, TypeT, MinSizeT, _, _),
	createAptRooms(FloorWidth, FloorHeight, AptTypeRem, RoomT, CoorT, XT, WT, YT, HT),
	append(CoorH, CoorT, Coords).


% creates a single room
createRoom(FloorWidth, FloorHeight, Type, MinRoomSize, Room, Coord, X, W, Y, H):-
	create_rect_min_area(FloorWidth, FloorHeight, MinRoomSize, Room, Coord),
	
	% sun room exposed to day light
	(Type #= 7) #<==> ShouldBeSunRoom,
	sun_room(FloorWidth, FloorHeight, Coord, IsSunRoom),
	Coord = [X, W, Y, H],
	ShouldBeSunRoom #==> IsSunRoom.

/**********************************************************************
 * Hallway Creation
 **********************************************************************/

% creates a variable number of hallways using the helper createOuterHalls	
addOuterHalls(FloorWidth, FloorHeight, NumApts, Hallways, NumHallways, Coords):-
	length(Hallways, NumHallways),
	Max #= (NumApts div 2),
	NumHallways in 1..Max,
	createOuterHalls(FloorWidth, FloorHeight, Hallways, Coords).

createOuterHalls(_, _, [], []).
createOuterHalls(FloorWidth, FloorHeight, [HallH | HallT], Coords):-
	create_rect(FloorWidth, FloorHeight, HallH, CoordH),
	createOuterHalls(FloorWidth, FloorHeight, HallT, CoordT),
	append(CoordH, CoordT, Coords).

% makes sure all apartments are connected through hallways
% takes in list of apartments, and list of hallways
checkConnectivity([], _).
checkConnectivity([AptH | AptT], Hallways):-
	% print("Apartments as Hallways"), print([AptH | AptT]),
	appartmentToHallwayConnectivity(AptH, Hallways, ConnectedRooms),
	ConnectedRooms #>=1,
	checkConnectivity(AptT, Hallways).

% counts the number of rooms inside an apartment that are connected to hallways
% takes in list of rooms, and list of hallways, returns a counter
appartmentToHallwayConnectivity([], _, 0).
appartmentToHallwayConnectivity([RoomH | RoomT], Hallways, Count):-
	% print("Hallways 1 apt"), print([RoomH | RoomT]), nl,
	roomToHallwayConnectivity(RoomH, Hallways, Count1),
	appartmentToHallwayConnectivity(RoomT, Hallways, Count2),
	Count #= Count1 + Count2.

% counts the number of hallways 1 room is connected to
% takes in a rooms, and a list of hallways, returns a counter 
roomToHallwayConnectivity(_, [], 0).
roomToHallwayConnectivity(Room, [HallH | HallT], Count):-
	% print("Hall"), print(Room), nl,
	adjacent(Room, HallH, Count1),
	roomToHallwayConnectivity(Room , HallT, Count2),
	Count #= Count1 + Count2.

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

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
	
	createHallways(FloorWidth, FloorHeight, TotalNumApts, NumHallways, Hallways, HallCoordList),
	checkAdjacency(Hallways),


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
	
	createRoom(FloorWidth, FloorHeight, MinSizeH, RoomH, CoorH),
	NumRoomsRem #= NumRooms - 1 ,
	AptTypeRem = apt_type(NumRoomsRem, TypeT, MinSizeT, _, _),
	createAptRooms(FloorWidth, FloorHeight, AptTypeRem, RoomT, CoorT),
	append(CoorH, CoorT, Coords).

/****************************createRoom*********************************
creates a single room
**********************************************************************/
createRoom(FloorWidth, FloorHeight, MinRoomSize, Room, Coord):-
	create_rect_min_area(FloorWidth, FloorHeight, MinRoomSize, Room, Coord).

/**************************createHallways*******************************
creates a variable number of hallways using the helper createHallwaysHelper
**********************************************************************/
createHallways(FloorWidth, FloorHeight, TotalNumApts, NumHallways, Hallways, CoordList):-
	length(Hallways, NumHallways),
	NumHallways in 1..200,
	createHallwaysHelper(FloorWidth, FloorHeight, TotalNumApts, Hallways, CoordList).
	
createHallwaysHelper(_, _, _, [], []).
createHallwaysHelper(FloorWidth, FloorHeight, TotalNumApts, [HallH | HallT], Coord):-
	create_rect(FloorWidth, FloorHeight, HallH, CoordH),
	createHallwaysHelper(FloorWidth, FloorHeight, TotalNumApts, HallT, CoordT),
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
	



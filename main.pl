:-use_module(library(clpfd)).
:-include('rectangle_helpers.pl').
:-include('apartments.pl').
:-include('soft.pl').
:-include('global.pl').

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
	
input(FloorWidth, FloorHeight, Landscapes, Open, AptTypes, NumApts, Apartments, Types, OuterHallways, Elevator,Ducts,
	[GlobalLandscapeViewConstraint, GlobalElevatorDistanceConstraint, GlobalGoldenRatio]):-

	print("Starting To Constrain!"), nl,
	statistics(walltime, [_ | [_]]),

	/****************** Hard Constraints ******************/
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
		ApartmentsList, TypesList,
		AptCoordList,
		InnerHallwaysList, NumInnerHallways,
		OuterHallwaysList
		),

	append(InnerHallwaysList, InnerHallways),
	append(TypesList, Types),
	append(OuterHallwaysList, OuterHallways),

	append(ApartmentsList, Apartments),
	append(AptCoordList, Coords),

	checkAdjacency(OuterHallways),

	% elevator
	create_elevator(FloorWidth, FloorHeight, OuterHallways, Elevator, ElevatorCoord),

	%ducts 
	create_ducts(FloorWidth, FloorHeight, Apartments,Types, Ducts, DuctsCoord),
	append(DuctsCoord,DuctsCoords),	

	% no overlap constraint
	append(Apartments, Rooms),
	% append(Rooms,Ducts,Inside),
	append(OuterHallways, [Elevator], Outside),
	append(Rooms, Outside, Floor),
	% append(Inside,Outside,Floor),
	disjoint2(Floor),
	
	% Utility of Apartments and Hallways
	apts_util(Apartments, ApartmentsArea),
	calc_util(OuterHallways, HallsArea),
	calc_util([Elevator], ElevatorArea),
	calc_util(Ducts,DuctsArea),
	TotalArea #= ApartmentsArea + HallsArea + ElevatorArea + DuctsArea,

	/****************** Soft Constraints ******************/
	sun_exposed(FloorWidth, FloorHeight, Apartments, CostSunExposed),
	bedrooms(Apartments, Types, CostBedrooms),
	main_bathroom(Apartments, Types, CostBathrooms),

	CostFunction #= CostSunExposed + CostBedrooms + CostBathrooms,
	
	/***************** Global Constraints *****************/
	% Landscape View
	globalLandscapeView(Apartments, Landscapes, FloorWidth, FloorHeight, GlobalLandscape),
	GlobalLandscape #= TotalNumApts #<==> GlobalLandscapeViewConstraint,

	% Elevator Distance
	globalElevatorDistance(Apartments, Elevator, DistancesToElevator),
	allDistancesEqual(DistancesToElevator, NumEqualDistance),
	NumEqualDistance #= TotalNumApts #<==> GlobalElevatorDistanceConstraint,

	% Golden Ratio
	globalgoldenRatio(Apartments, NumApartmentGoldenRatio),
	NumApartmentGoldenRatio #= TotalNumApts #<==> ApartmentGoldenRatio,
	goldenRatio(OuterHallways, NumHallwaysGoldenRatio),
	NumHallwaysGoldenRatio #= NumHallways #<==> HallwaysGoldenRatio,
	goldenRatio([Elevator], ElevatorGoldenRatio),
	goldenRatio(Ducts,DuctGoldenRatio),
	DuctGoldenRatio #= TotalNumApts #<==> GlobalDuctGoldenRatio,
	
	ApartmentGoldenRatio+HallwaysGoldenRatio+ElevatorGoldenRatio+GlobalDuctGoldenRatio #= 4 #<==> GlobalGoldenRatio,

	% Labeling
	append(Coords, ElevatorCoord, Label1),
	append(DuctsCoords,Label1,Label),

	print("Starting Labeling!"), nl,
	% labeling([min(CostSunExposed)], Label),
	labeling([], Label),
	print("sun: "), print(CostSunExposed), nl,
	print("bedrooms: "), print(CostBedrooms), nl,
	print("bathrooms: "), print(CostBathrooms), nl,
	print("global landscapes:"), print(GlobalLandscape), nl,

	statistics(walltime, [_ | [ExecutionTime]]),
	T is ExecutionTime / 60000,
	print("Execution took:"), print(T), print("seconds"), nl.
	
/**********************************************************************
Appartment Creation 
***********************************************************************/
% creates all apartments of some type "AptType"
% this apartment type exists "NumApts" times on the floor
createApts(_, _, _, 0, [], [], [], [], [], []).	
createApts(FloorWidth, FloorHeight, AptType, NumApts, 
			[AptH | AptT], [TypesAptH | TypesAptT],
			Coords, 
			[InHallwaysH | InHallwaysT], [NumHallwaysH | NumHallwaysT],
			[OutHallH | OutHallT]
			):-

	NumApts #> 0,

	createAptRooms(FloorWidth, FloorHeight, AptType, AptRoomsH, CoorH),
	
	% Dressing room adj to bedroom + Minor bathroom adjacent to room + dining adjacent to kitchen
	AptType = apt_type(NumRooms, Types, _, _, _),
	adjacentRooms(AptRoomsH, Types),

	% add hallways
	addInnerHalls(FloorWidth, FloorHeight, AptRoomsH, NumRooms, InHallwaysH, TypesHallH, NumHallwaysH, HallCoordH),

	append(AptRoomsH, InHallwaysH, AptH),
	append(Types, TypesHallH, TypesAptH),

	% add outer hallway
	addOuterHalls(FloorWidth, FloorHeight, InHallwaysH, OutHallH, OutHallCoordH),

	append(CoorH, HallCoordH, InCoords),
	append(InCoords, OutHallCoordH, AptCoords),
	% add ducts
	% add_ducts(AptRoomsH, Types, Ducts);

	Counter #= NumApts - 1,
	createApts(FloorWidth, FloorHeight, AptType, Counter, AptT, TypesAptT, CoorT, InHallwaysT, NumHallwaysT, OutHallT),
	append(AptCoords, CoorT, Coords).


% creates the rooms in an apartment
createAptRooms(_, _, apt_type(0, _, _, _, _), [], []).
createAptRooms(FloorWidth, FloorHeight, AptType, [RoomH | RoomT], Coords):-

	%AptType = apt_type(NumRooms, RoomTypes, MinRoomSize, Widths, Heights),
	AptType = apt_type(NumRooms, [TypeH | TypeT], [MinSizeH | MinSizeT], [MinWidthH | MinWidthT], [MinHeightH | MinHeightT]),
	NumRooms #> 0,
	
	createRoom(FloorWidth, FloorHeight, TypeH, MinSizeH,MinWidthH,MinHeightH, RoomH, CoorH),
	NumRoomsRem #= NumRooms - 1,
	AptTypeRem = apt_type(NumRoomsRem, TypeT, MinSizeT, MinWidthT, MinHeightT),
	createAptRooms(FloorWidth, FloorHeight, AptTypeRem, RoomT, CoorT),
	append(CoorH, CoorT, Coords).


% creates a single room
createRoom(FloorWidth, FloorHeight, Type, MinRoomSize,MinWidthH,MinHeightH, Room, Coord):-
	create_rect_min_area(FloorWidth, FloorHeight, MinRoomSize, Room, Coord),
	Room = r(_,W,_,H),
	W #>= MinWidthH, H#>=MinHeightH,
	% sun room exposed to day light
	(Type #= 7) #<==> ShouldBeSunRoom,
	sun_room(FloorWidth, FloorHeight, Coord, IsSunRoom),
	ShouldBeSunRoom #==> IsSunRoom.

/**********************************************************************
 * apts_util
 **********************************************************************/
% calculates the area of all appartments to check the utility
% uses the helper calc_util which calculates the area of a list of rectangles
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

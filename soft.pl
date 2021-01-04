:-use_module(library(clpfd)).

% all rooms exposed to sunlight
sun_exposed(_, _, [], 0).
sun_exposed(FloorWidth, FloorHeight, [AptH | AptT], Cost):-
    sun_exposed_rooms(FloorWidth, FloorHeight, AptH, Cost1),
    sun_exposed(FloorWidth, FloorHeight, AptT, Cost2),
    Cost #= Cost1 + Cost2.

sun_exposed_rooms(_, _, [], 0).
sun_exposed_rooms(FloorWidth, FloorHeight, [RoomH | RoomT], Cost):-
    not_exposed_to_light(FloorWidth, FloorHeight, RoomH, Cost1),
    sun_exposed_rooms(FloorWidth, FloorHeight, RoomT, Cost2),
    Cost #= Cost1 + Cost2.

not_exposed_to_light(FloorWidth, FloorHeight, Room, NotSun):-
	Room = r(X, W, Y, H),
	X #= 0 #<==> IsAtLeft,
	Y #= 0 #<==> IsAtTop,
	X + W #= FloorWidth #<==> IsAtRight,
	Y + H #= FloorHeight #<==> IsAtBottom,
    (IsAtLeft #\/ IsAtTop #\/ IsAtRight #\/ IsAtBottom) #<==> IsSunRoom,
    NotSun #= 1 - IsSunRoom.

% bedrooms should be near each other
bedrooms([], [], 0).
bedrooms([AptH | AptT], [TypesH | TypesT], Cost):-
    calculateApartmentBedroomCost(AptH,TypesH,Cost1),
    bedrooms(AptT, TypesT, Cost2),
    Cost #= Cost1 + Cost2.

calculateApartmentBedroomCost([],[],0).
calculateApartmentBedroomCost([_],[_],0).
calculateApartmentBedroomCost([RoomH1,RoomH2|RoomT],[TypeH1,TypeH2|TypeT],Cost):-
    dist(RoomH1, RoomH2, Distance),
    TypeH1#=0 #/\ TypeH2#=0 #<==> CostH#=Distance,
    TypeH1#\=0 #\/ TypeH2#\=0 #<==> CostH#=0,
    calculateApartmentBedroomCost([RoomH2|RoomT],[TypeH2|TypeT],RestCostH2),
    calculateApartmentBedroomCost([RoomH1|RoomT],[TypeH1|TypeT],RestCostH1),
    Cost #= CostH+RestCostH1+RestCostH2.



% bathrooms should be accessible from any room *especially* the living room
main_bathroom([], [], 0).
main_bathroom([AptH | AptT], [TypesH | TypesT], Cost):-
    find_room_of_type(AptH, TypesH, 3, Bathrooms),
    find_rooms_except_type(AptH, TypesH, 3, Rooms),
    calc_bathrooms_cost(Bathrooms, Rooms, Cost1),
    main_bathroom(AptT, TypesT, Cost2),
    Cost #= Cost1 + Cost2.

calc_bathrooms_cost([], _, 0).
calc_bathrooms_cost([BathH | BathT], Rooms, Cost):-
    calc_single_bath_cost(BathH, Rooms, Cost1),
    calc_bathrooms_cost(BathT, Rooms, Cost2),
    Cost #= Cost1 + Cost2.

calc_single_bath_cost(_, [], 0).
calc_single_bath_cost(Bath, [RoomH | RoomT], Cost):-
    dist(Bath, RoomH, Cost1),
    calc_single_bath_cost(Bath, RoomT, Cost2),
    Cost #= Cost1 + Cost2.

% helpers
% gets all rooms of type Type
find_room_of_type(Rooms, Types, Type, Bedrooms):-
    findall(Room, (nth1(N, Rooms, Room), nth1(N, Types, Type)), Bedrooms).
% gets all rooms except those of type Type
find_rooms_except_type(Rooms, Types, NotType, Bedrooms):-
    findall(Room, (nth1(N, Rooms, Room), nth1(N, Types, Type), Type #\= NotType), Bedrooms).

dist(Room1, Room2, Cost):-
    Room1 = r(X1, _, Y1, _),
    Room2 = r(X2, _, Y2, _),

    DistX #= abs(X1 - X2),
    DistY #= abs(Y1 - Y2),

    Cost #= DistX + DistY.



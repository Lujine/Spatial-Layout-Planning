:-use_module(library(clpfd)).
	
create_rect(FloorWidth, FloorHeight, Rect, Coord):-
	
	Width in 1..FloorWidth,
	Height in 1..FloorHeight,
	
	X #>= 0,
	Y #>= 0,
	X + Width #=< FloorWidth,
	Y + Height #=< FloorHeight,
	
	Rect = r(X, Width, Y, Height),
	Coord = [X, Y, Width, Height].
	
create_rect_min_area(FloorWidth, FloorHeight, MinRoomSize, Rect, Coord):-

	Rect = r(_, Width, _, Height),
	Width * Height #>= MinRoomSize,
	create_rect(FloorWidth, FloorHeight, Rect, Coord).
	
adjacent(r(X1, W1, Y1, H1), r(X2, W2, Y2, H2), Adj):- % <==== added "Adj" to have a refiable expression
	
	R1TopY #= Y1,
	R1LefX #= X1,
	R1BotY #= Y1 + H1,
	R1RigX #= X1 + W1,
	
	R2TopY #= Y2,
	R2LefX #= X2,
	R2BotY #= Y2 + H2,
	R2RigX #= X2 + W2,
	
	% r2 on top or at the bottom of r1
	R1TopY #= R2BotY #<==> OnTop,
	R1BotY #= R2TopY #<==> OnBot,
	((OnTop #\/ OnBot) #/\ ((R2RigX #>= R1LefX #/\ R2RigX #=< R1RigX) #\/ (R2LefX #>= R1LefX #/\ R2LefX #=< R1RigX))) #<==> VertMidX, 
	
	TopBot #= OnTop + OnBot + VertMidX,
	TopBot in 0\/2,

	%r2 is to the left or right of 
	R1LefX #= R2RigX #<==> OnLef,
	R1RigX #= R2LefX #<==> OnRig,
	((OnLef #\/ OnRig) #/\ ((R2TopY #>= R1TopY #/\ R2TopY #=< R1BotY) #\/ (R2BotY #>= R1TopY #/\ R2BotY #=< R1BotY))) #<==> VertMidY,
	
	LefRig #= OnLef + OnRig + VertMidY,
	LefRig in 0\/2,
	
	Side #= OnTop + OnBot + OnLef + OnRig, 
	Side #= 1,
	
	(TopBot#=2 #\/ LefRig#=2) #<==> Adj. 

	
/****************************checkAdjacency*********************************
makes sure rect i is adjacent to rect i+1
***********************************************************************/
checkAdjacency([]).
checkAdjacency([_]).
checkAdjacency([H1,H2|T]):-
	adjacent(H1,H2,Adj),
	Adj#=1,
    checkAdjacency([H2|T]).


% Test cases for adjacent
%R1 = r(0,  5, 0,  5), R2 = r(5,  5, 0,  5), R3 = r(10, 5, 0,  5), R4 = r(0,  5, 5,  5), R5 = r(5,  5, 5,  5), R6 = r(10, 5, 5,  5), R7 = r(0,  5, 10, 5), R8 = r(5,  5, 10, 5), R9 = r(10, 5, 10, 5), adjacent(R8,R9,Adj).
%R1 = r(0,  10, 0,  5), R2 = r(0,  6, 5,  17), R3 = r(6, 4, 5, 2), R4 = r(6, 4, 7, 15), adjacent(R1,R2,Adj).
%R1 = r(0, 5, 0, 15), R2 = r(5, 5, 0, 5), R3 = r(5, 5, 5, 5), R4 = r(5, 5, 10, 5), adjacent(R1,R2,Adj).
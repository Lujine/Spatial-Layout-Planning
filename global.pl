:-use_module(library(clpfd)).

/****************************globalLandscapeView*********************************
All apartments should have a look on landscape view
***********************************************************************/
globalLandscapeView([],_,_,_,0).
globalLandscapeView([AH|AT],Landscapes,FloorWidth,FloorHeight,GlobalLandscape):-
    apartmentLandscapeView(AH,Landscapes,FloorWidth,FloorHeight,AptLandscape),
    AptLandscape#>0 #<==>ApartmentLandscape,
    globalLandscapeView(AT,Landscapes,FloorWidth,FloorHeight,RestLandscape),
    GlobalLandscape #=ApartmentLandscape + RestLandscape.

apartmentLandscapeView([],_,_,_,0).
apartmentLandscapeView([RH|RT],[Up,Down,Left,Right],FloorWidth,FloorHeight,HasLandscape):-
    RH = r(X, _,Y, _), 
    ((Up#=1 #/\ Y#=0) #\/ (Down#=1 #/\ Y#=FloorHeight) #\/ (Left#=1 #/\ X#=0) #\/(Right#=1 #/\ X#=FloorWidth) )#<==> Landscape,
    apartmentLandscapeView(RT,[Up,Down,Left,Right],FloorWidth,FloorHeight,RestLandscape),
    HasLandscape#=Landscape+RestLandscape.


/****************************globalElevatorDistance*********************************
All apartments should be of an equal distance to the elevators unit.
***********************************************************************/
globalElevatorDistance([],_,[]).
globalElevatorDistance([Ah|AT],Elevator,[DistanceH|DistanceT]):-
    Elevator = r(X,W,Y,H),
    MidPointElevatorX #= (2*X+W) div 2,
    MidPointElevatorY #= (2*Y+H) div 2,
    sumAptPoints(Ah,(SumX,SumY)),
    length(Ah,N),
    AvgX #= SumX div N,
    AvgY #= SumY div N,

    DistanceH #= (abs(AvgX-MidPointElevatorX)) + (abs(AvgY-MidPointElevatorY)), %manhattan distance
    globalElevatorDistance(AT,Elevator,DistanceT).

    
/****************************sumAptPoints*********************************
Sums all X values and all y values to get an average midpoint to be used for distance calculations
***********************************************************************/
sumAptPoints([],(0,0)).
sumAptPoints([Rh|Rt],(SumX,SumY)):-
    Rh = r(X,_,Y,_),
    sumAptPoints(Rt,(RestX,RestY)),
    SumX #=X+RestX,
    SumY #=Y+RestY.

/****************************sumAptPoints*********************************
Counts the number of Apartments with equal distances to the elevators
***********************************************************************/
allDistancesEqual([],0).
allDistancesEqual([_],1).
allDistancesEqual([Dh1,Dh2|Dt],GlobalElevatorDistanceConstraint):-
    abs(Dh1-Dh2) #=<6 #<==> HeadFlag,
    allDistancesEqual([Dh2|Dt],RestFlag),
    GlobalElevatorDistanceConstraint#= HeadFlag+RestFlag.



/****************************Symmetry*********************************
Symmetry Constraints over floor or over same type apartments.
***********************************************************************/
symmetry([]).


/****************************globalgoldenRatio*********************************
Aim to allocate spaces with ratios following the divine proportion
***********************************************************************/
globalgoldenRatio([],0).
globalgoldenRatio([AptH|AptT],GlobalRatio):-
    goldenRatio(AptH,AptRatios),
    length(AptH,N),
    AptRatios #=N #<==> AptGolden,
    globalgoldenRatio(AptT,GoldenRest),
    GlobalRatio#=AptGolden+GoldenRest.

/****************************goldenRatio*********************************
counts the number of rooms within an apartment that have the golden ratio
***********************************************************************/
goldenRatio([],0).
goldenRatio([RectH|RectT],GlobalGolden):-
    RectH = r(_,W,_,H),

    W#>=H #<==> Bigger #=W,
    W#>=H #<==> Smaller #=H,
    
    W#<H #<==> Bigger #=H,
    W#<H #<==> Smaller #=W,
    
    Ratio1 #= (Bigger+Smaller) div Bigger,
    Ratio2 #= Bigger div Smaller,
    
    abs( Ratio1 - Ratio2 )#=<5 #<==> GoldenRect,
    
    goldenRatio(RectT,GoldenRest),
    GlobalGolden #= GoldenRect + GoldenRest.


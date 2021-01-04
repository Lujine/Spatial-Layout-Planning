import pyswip
from pyswip import Prolog
import matplotlib.pyplot as plt
import cv2
import numpy as np

prolog = Prolog()

prolog.consult("main.pl")
print('consulted!')

# 0 Bedroom
# 1 Kitchen
# 2 Dining Room
# 3 Master bathroom
# 4 Minor bathroom
# 5 Living Room
# 6 Dressing room
# 7 Sun room
# 8 Hallway
# 9 duct
colorEach = [
    (255,0,0),
    (0,255,0),
    (255,0,255),
    (0,0,255),
    (255,255,0),
    (0,255,255),
    (255,0,255),
    (0,0,0),
    (40,40,40),
]

FloorWidth = 76
FloorHeight = 76
Landscapes = [1,0,0,1]
Open = [1,0,0,1]
NumApts = [2]


solve = pyswip.Functor('input', 12)
apt_type = pyswip.Functor('apt_type', 5)


NumRooms = 8
RoomTypes = [0, 4, 0, 2, 1, 3, 5, 7]
RoomSizes =  [9, 9, 9, 9, 9, 9, 9, 9]
RoomWidths = [3, 3, 3, 3, 3, 3, 3, 3]
RoomHeights = [3, 3, 3, 3, 3, 3, 3, 3]

AptTypes = [apt_type(NumRooms, RoomTypes, RoomSizes, RoomWidths, RoomHeights)]

Apartments = pyswip.Variable()
Types = pyswip.Variable()
OuterHallways = pyswip.Variable()
Elevator = pyswip.Variable()
Ducts = pyswip.Variable()
GlobalLandscapeViewConstraint = pyswip.Variable()
GlobalElevatorDistanceConstraint = pyswip.Variable()
GlobalGoldenRatio = pyswip.Variable()

print(f'input({FloorWidth}, {FloorHeight}, {Landscapes}, {Open}, {AptTypes}, {NumApts}, Apartments, Types, OuterHallways, Elevator,Ducts,[GlobalLandscapeViewConstraint, GlobalElevatorDistanceConstraint, GlobalGoldenRatio])')


q = pyswip.Query(solve(FloorWidth, FloorHeight, Landscapes, Open, AptTypes, NumApts, Apartments, Types, OuterHallways, Elevator,Ducts,[GlobalLandscapeViewConstraint, GlobalElevatorDistanceConstraint, GlobalGoldenRatio]))
print('query made!')
num_solutions = 1
q.nextSolution()
for i in range(num_solutions):
    image = np.ones((FloorHeight,FloorWidth,3))
    image = (image*255).astype(np.uint8)
    q.nextSolution()
    print('----------')
    aptValues = Apartments.value
    typeValues = Types.value
    for aptIdx,apt in enumerate(aptValues):
        aptTypes = typeValues[aptIdx]
        for roomIdx,room in enumerate(apt):
            print(str(room))
            vals = str(room)[2:-1].split(',')
            # print(vals)
            # X,Width,Y,Height
            x = int(vals[0])
            w = int(vals[1])
            y = int(vals[2])
            h = int(vals[3])
            t = int(aptTypes[roomIdx])
            cv2.rectangle(image, (x,y), (x+w,y+h), colorEach[t], -1) 
            print()
        print('----------')
ductVals = Ducts.value
for duct in ductVals:
    vals = str(duct)[2:-1].split(',')
    # print(vals)
    # X,Width,Y,Height
    x = int(vals[0])
    w = int(vals[1])
    y = int(vals[2])
    h = int(vals[3])
    cv2.rectangle(image, (x,y), (x+w,y+h), colorEach[8], -1) 

hallsVals = OuterHallways.value
for hall in hallsVals:
    vals = str(hall)[2:-1].split(',')
    
    x = int(vals[0])
    w = int(vals[1])
    y = int(vals[2])
    h = int(vals[3])
    cv2.rectangle(image, (x,y), (x+w,y+h), colorEach[7], -1) 
elevatorVal = Elevator.value

vals = str(elevatorVal)[2:-1].split(',')
x = int(vals[0])
w = int(vals[1])
y = int(vals[2])
h = int(vals[3])
cv2.rectangle(image, (x,y), (x+w,y+h), (20,100,50), -1) 
    

plt.figure()
plt.imshow(image)
plt.show()
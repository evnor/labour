module labour::Syntax

/*
 * Define a concrete syntax for LaBouR. The language's specification is available in the PDF (Section 2)
 */

/*
 * Note, the Server expects the language base to be called BoulderingWall.
 * You are free to change this name, but if you do so, make sure to change everywhere else to make sure the
 * plugin works accordingly.
 */

 /*
   Start
 */
 start syntax BoulderingWall
 = wall: "bouldering_wall" "\"" Name "\"" "{"
   Routes ","
   Volumes
   "}"
 ;

layout Whitespace = [\ \t\n\r]*;

/*
   lexical
*/
lexical Name = [a-zA-Z0-9\ _\-]+;

lexical String = [0-9a-zA-Z]*;

lexical Integer = "-"? [0-9]+;

lexical HoldID = [0-9][0-9][0-9][0-9];


/*
   Routes
*/
syntax Routes
  = routes: "routes" "["
    {BoulderingRoute ","}+
    "]"
;

syntax BoulderingRoute
  = boulderingRoute: "bouldering_route" "\"" Name "\"" "{"
    Grade ","
    GridBasePoint ","
    Holds
    "}"
;

/*
   Volumes
*/

syntax Volume 
  = Circle: Circle
  | Triangle: Triangle
;

syntax HoldPosition
  = hold_Position: "pos" ":" Point
  | hold_Position: "pos" ":" AnglePoint
;

syntax VolumePosition
  = volume_position: "pos" ":" Point;

syntax Depth
  = depth: "depth" ":" Integer ;

syntax Radius
  = radius: "radius" ":" Integer ;

syntax Shape
  = shape: "shape" ":" "\"" String "\"" ;

syntax Rotation
  = rotation: "rotation" ":" Integer ;

syntax Colour
  = "white"
  | "yellow"
  | "green"
  | "blue"
  | "red"
  | "purple"
  | "pink"
  | "black"
  | "orange"
;

syntax Colours
  = colours: "colours" "["
    {Colour ","}+
  "]"
;

syntax StartHold
  = start_hold: "start_hold" ":" Integer ; 

syntax EndHold
  = end_hold: "end_hold"; 

// We use this HoldProperties construction so that optional properties need not be specified,
// and to allow reordering. We could eliminate this (and the later TriangeHolds) by enumerating
// all options, but this way we could provide feedback on why a file is invalid in the cst2ast
// function.
syntax Hold
  = hold: "hold" "\"" HoldID "\"" "{"
  {HoldProperties ","}+
  "}"
;

syntax HoldProperties
  = pos: HoldPosition
  | shape: Shape 
  | rotation: Rotation 
  | colours: Colours 
  | start_hold: StartHold 
  | end_hold: EndHold
;

syntax FrontHolds
  = front_holds: "front_holds" "[" 
  {Hold ","}*
  "]"
;

syntax SideHolds
  = side_holds: "side_holds" "[" 
  {Hold ","}*
  "]"
;

syntax Circle
  = circle: "circle" "{" 
  VolumePosition ","
  Depth ","
  Radius ","
  FrontHolds ","
  SideHolds
  "}"
;

syntax Extrusion
  = extrusion: "extrusion" ":" Point ;

syntax Corners
  = corners: "corners" "["
  {Point ","}+
  "]"
;

syntax LeftHolds
  = left_holds: "left_holds" "["
  {Hold ","}*
  "]"
;

syntax RightHolds
  = right_holds: "right_holds" "["
  {Hold ","}*
  "]"
;

syntax BottomHolds
  = bottom_holds: "bottom_holds" "["
  {Hold ","}*
  "]"
;

syntax TriangleHolds
  = left: LeftHolds
  | right: RightHolds
  | bottom: BottomHolds
;

// We use the 'TriangleHolds' construction so that not every *_holds needs to be specified
syntax Triangle
  = triangle: "triangle" "{" 
  VolumePosition ","
  Extrusion ","
  Depth ","
  Corners ","
  {TriangleHolds ","}*
  "}"
;

syntax Volumes 
  = volumes: "volumes" "[" 
    {Volume "," }+
  "]"
;

syntax Grade
  = grade: "grade" ":" "\"" String "\"" ;

syntax Point
  = point: "{" "x" ":" Integer "," "y" ":" Integer "}";

syntax AnglePoint
  = angle_point: "{" "angle" ":" Integer "}" ;

syntax GridBasePoint
  = grid_base_point: "grid_base_point" Point;

syntax RouteHoldID
  = single_holdID: "\"" HoldID "\""
  | split_holdID: "{" "\"" HoldID "\"" "," "\"" HoldID "\"""}";

syntax Holds
  = holds: "holds" "[" 
  {RouteHoldID ","}+
  "]" 
;

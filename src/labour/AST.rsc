module labour::AST

/*
 * Define the Abstract Syntax for LaBouR
 * - Hint: make sure there is an almost one-to-one correspondence with the grammar in Syntax.rsc
 */

data BoulderingWall(loc src=|unknown:///|)
  = boulderingWall(str name, list[BoulderingRoute] routes, list[Volume] volumes);

data BoulderingRoute
  = boulderingRoute(str name, str grade, Point GridBasePoint, list[RouteHoldID] holds);

data RouteHoldID
  = single_holdID(str id)
  | split_holdID(str leftId, str rightId);

data Volume
 = circle(Point pos, int depth, int radius, list[Hold] frontHolds, list[Hold] sideHolds)
 | triangle(Point pos, Point extrusion, int depth, list[Point] corners, list[Hold] leftHolds, list[Hold] rightHolds, list[Hold] bottomHolds);

data Hold
 = hold(str name, Position pos, str shape, int rotation, list[Colour] colours, HoldType holdType);

data Position
 = frontPos(Point pos)
 | sidePos(int angle);

data Point
 = point(int x, int y);

data HoldType
 = normal()
 | endHold()
 | startHold(int hand)
;

data Colour
  = white()
  | yellow()
  | green()
  | blue()
  | red()
  | purple()
  | pink()
  | black()
  | orange();
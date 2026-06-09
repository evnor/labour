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

// Even if writing *_holds may be optional, leaving it unspecified is equivalent to an empty list
// No need to make them all Option[list[Hold]]
data Volume
  = circle(Point pos, int depth, int radius, list[Hold] frontHolds, list[Hold] sideHolds)
  | triangle(Point pos, Point extrusion, int depth, list[Point] corners, list[Hold] leftHolds, list[Hold] rightHolds, list[Hold] bottomHolds);

data Option[&T] 
  = none()
  | some(&T v);

// rotation is optional, so it is specified as an Option[int]
data Hold
  = hold(str name, Position pos, str shape, Option[int] rotation, list[Colour] colours, HoldType holdType);

data Position
  = frontPos(Point pos)
  | sidePos(int angle);

data Point
  = point(int x, int y);

// Instead of adding a normal() variant, we could have used Option[HoldType] where HoldType is endHold or startHold.
// This way seemed simpler.
data HoldType
  = normal()
  | endHold()
  | startHold(int hand);

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
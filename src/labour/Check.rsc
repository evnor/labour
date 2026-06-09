module labour::Check

import labour::AST;
import labour::Parser;
import labour::CST2AST;

import IO;
import List;
import Set;
import Prelude;
import String;


/*
 * Implement a well-formedness checker for the LaBouR language. For this you must use the AST.
 * - Hint: Map regular CST arguments (e.g., *, +, ?) to lists
 * - Hint: Map lexical nodes to Rascal primitive types (bool, int, str)
 * - Hint: Use switch to do case distinction with concrete patterns
 */

/*
 * Define a function per each verification defined in the PDF (Section 2.2.)
 * Some examples are provided below.
 */

bool checkBoulderWallConfiguration(BoulderingWall wall){
  bool numberOfHolds = checkNumberOfHolds(wall);
  bool startingLabelLimit = checkStartingHoldsTotalLimit(wall);
  bool unique_end_hold = checkUniqueEndHold(wall);
  bool requiredProperties = checkRequiredHoldProperties(wall);
  bool angles = checkHoldAngles(wall);
  bool rotations = checkHoldRotations(wall);
  bool triangleCorners = checkTriangleCorners(wall);
  bool merge = checkNoSplitAfterMerge(wall);
  bool colours = checkRouteHoldColours(wall);
  bool num_route_volume = checkWallHasRouteAndVolumes(wall);
  bool split = checkAtMostOneSplit(wall);
  bool sideHoldsAngle = checkCircleSideHoldsUseAngle(wall);

  return (numberOfHolds && startingLabelLimit && unique_end_hold && requiredProperties && angles && rotations && triangleCorners && merge && colours && num_route_volume && sideHoldsAngle && split);
}


// Check that there are at least two holds in the wall
bool checkNumberOfHolds(BoulderingWall wall) {
  switch (wall) {
    case boulderingWall(str name, list[BoulderingRoute] routes, list[Volume] volumes): {
      for (route <- routes) {
        switch (route) {
          case boulderingRoute(str name, str grade, Point GridBasePoint, list[RouteHoldID] holds): {
            if (size(holds) < 2) {
              return false;
            }
          }
        }
      }
      return true;
    }
  }
  return false;
}

// Check that routes have between zero and two hand start holds
bool checkStartingHoldsTotalLimit(BoulderingWall wall) {
  switch (wall) {
    case boulderingWall(_, list[BoulderingRoute] routes, list[Volume] volumes): {
      list[Hold] allHolds = getAllHoldsFromVolumes(volumes);

      for (route <- routes) {
        list[Hold] routeHolds = getHoldsOfRoute(route, allHolds);

        int start1Count = size([
          h | h <- routeHolds, isStartHoldNumber(h, 1)
        ]);

        int start2Count = size([
          h | h <- routeHolds, isStartHoldNumber(h, 2)
        ]);

        int invalidStartCount = size([
          h | h <- routeHolds, hasInvalidStartHoldNumber(h)
        ]);

        if (invalidStartCount > 0) {
          return false;
        }

        if (start1Count > 1 || start2Count > 1) {
          return false;
        }

        if (start1Count + start2Count > 2) {
          return false;
        }
      }

      return true;
    }
  }

  return false;
}

bool isStartHoldNumber(Hold h, int expected) {
  switch (h) {
    case hold(_, _, _, _, _, startHold(hand)): {
      return hand == expected;
    }

    default: {
      return false;
    }
  }
}

bool hasInvalidStartHoldNumber(Hold h) {
  switch (h) {
    case hold(_, _, _, _, _, startHold(hand)): {
      return hand != 1 && hand != 2;
    }

    default: {
      return false;
    }
  }
}

// This function will insure that there is only one hold assign to end hold
bool checkUniqueEndHold(BoulderingWall wall){
  switch (wall) {
    case boulderingWall(str name, list[BoulderingRoute] routes, list[Volume] volumes): {
      list[Hold] allHolds = getAllHoldsFromVolumes(volumes);

      for(route <- routes) {
        list[Hold] routeHolds = getHoldsOfRoute(route, allHolds);
        int endCount = size([ h | h <- routeHolds, isEndHold(h)]); 
        int splitCount = countSplits(route);

        if (splitCount == 0 && endCount > 1) {
          return false;
        }

        if (splitCount > 0 && endCount > 2) {
          return false;
        }
      }

      return true;
    }
  }

  return false;
}

bool isEndHold(Hold h) {
  switch (h) {
    case hold(_, _, _, _, _, endHold()): {
      return true;
    }

    default: {
      return false;
    }
  }
}

// In a route, after a split, there should be no new split if there was a merge before
bool checkNoSplitAfterMerge(BoulderingWall wall) {
  switch (wall) {
    case boulderingWall(str name, list[BoulderingRoute] routes, list[Volume] volumes): {
      for (route <- routes) {
        if (!checkRouteNoSplitAfterMerge(route)) {
          return false;
        }
      }

      return true;
    }
  }

  return false;
}

bool checkRouteNoSplitAfterMerge(BoulderingRoute route) {
  switch (route) {
    case boulderingRoute(str name, str grade, Point gridBasePoint, list[RouteHoldID] holds): {
      bool hasSplit = false;
      bool hasMergedAfterSplit = false;

      for (h <- holds) {
        switch (h) {
          case split_holdID(str leftId, str rightId): {
            if (hasMergedAfterSplit) {
              return false;
            }

            hasSplit = true;
          }

          case single_holdID(str id): {
            if (hasSplit) {
              hasMergedAfterSplit = true;
            }
          }
        }
      }

      return true;
    }
  }

  return false;
}

//rule 11 colour
bool checkRouteHoldColours(BoulderingWall wall) {
  switch (wall) {
    case boulderingWall(str name, list[BoulderingRoute] routes, list[Volume] volumes): {
      list[Hold] allHolds = getAllHoldsFromVolumes(volumes);

      for (route <- routes) {
        list[Hold] routeHolds = getHoldsOfRoute(route, allHolds);

        if (size(routeHolds) == 0) {
          return false;
        }

        set[Colour] commonColours = toSet(getHoldColours(routeHolds[0]));

        for (h <- routeHolds) {
          commonColours = commonColours & toSet(getHoldColours(h));
        }

        if (size(commonColours) == 0) {
          return false;
        }
      }

      return true;
    }
  }

  return false;
}

// Every hold must have a shape and color
bool checkRequiredHoldProperties(BoulderingWall wall) {
  switch (wall) {
    case boulderingWall(_, _, list[Volume] volumes): {
      list[Hold] allHolds = getAllHoldsFromVolumes(volumes);

      for (h <- allHolds) {
        switch (h) {
          case hold(_, _, str shape, _, list[Colour] colours, _): {
            if (shape == "" || size(colours) == 0) {
              return false;
            }
          }
        }
      }

      return true;
    }
  }

  return false;
}

// the angle must be between 0 adn 359
bool checkHoldAngles(BoulderingWall wall) {
  switch (wall) {
    case boulderingWall(_, _, list[Volume] volumes): {
      list[Hold] allHolds = getAllHoldsFromVolumes(volumes);

      for (h <- allHolds) {
        switch (h) {
          case hold(_, sidePos(int angle), _, _, _, _): {
            if (angle < 0 || angle > 359) {
              return false;
            }
          }
        }
      }

      return true;
    }
  }

  return false;
}

// rotation value must be between 0 and 359
bool checkHoldRotations(BoulderingWall wall) {
  switch (wall) {
    case boulderingWall(_, _, list[Volume] volumes): {
      list[Hold] allHolds = getAllHoldsFromVolumes(volumes);

      for (h <- allHolds) {
        switch (h) {
          case hold(_, _, _, some(int rot), _, _): {
            if (rot < 0 || rot > 359) {
              return false;
            }
          }
        }
      }

      return true;
    }
  }

  return false;
}

// a corner array with three items
bool checkTriangleCorners(BoulderingWall wall) {
  switch (wall) {
    case boulderingWall(str name, list[BoulderingRoute] routes, list[Volume] volumes): {
      for (v <- volumes) {
        switch (v) {
          case triangle(
            Point pos,
            Point extrusion,
            int depth,
            list[Point] corners,
            list[Hold] leftHolds,
            list[Hold] rightHolds,
            list[Hold] bottomHolds
          ): {
            if (size(corners) != 3) {
              return false;
            }
          }
        }
      }

      return true;
    }
  }

  return false;
}

// Every wall mush have a least one volume and one route
bool checkWallHasRouteAndVolumes(BoulderingWall wall){
  switch (wall) {
    case boulderingWall(str name, list[BoulderingRoute] routes, list[Volume] volumes): {
      return size(routes) >= 1 && size(volumes) >= 1;
    }
  }

  return false;
}

// Every route must have at most one splitting hold where sub-routes start i.e. no more than two sub-routes
bool checkAtMostOneSplit(BoulderingWall wall) {
  switch (wall) {
    case boulderingWall(_, list[BoulderingRoute] routes, _): {
      for (route <- routes) {
        if (!checkRouteNoSplitAfterMerge(route)) {
          return false;
        }
      }

      return true;
    }
  }

  return false;
}

// Position of holds in side faces shold be represented as angles
bool isSidePosition(Hold h) {
  switch (h) {
    case hold(_, sidePos(_), _, _, _, _): {
      return true;
    }
    default: {
      return false;
    }
  }
}
bool checkCircleSideHoldsUseAngle(BoulderingWall wall) {
  switch (wall) {
    case boulderingWall(_, _, list[Volume] volumes): {
      for (v <- volumes) {
        switch (v) {
          case circle(_, _, _, _, list[Hold] sideHolds): {
            for (h <- sideHolds) {
              if (!isSidePosition(h)) {
                return false;
              }
            }
          }
        }
      }

      return true;
    }
  }

  return false;
}


int countSplits(BoulderingRoute route) {
  switch (route) {
    case boulderingRoute(str name, str grade, Point GridBasePoint, list[RouteHoldID] holds): {
      return size([h | h <- holds, isSplitHoldID(h)]);
    }
  }
  return 0;
}

bool isSplitHoldID(RouteHoldID holdID) {
  switch (holdID) {
    case split_holdID(str leftId, str rightId): {
      return true;
    }
    default: {
      return false;
    }
  }
}

list[Hold] getAllHoldsFromVolumes(list[Volume] volumes){
  list[Hold] result = [];

  for (v <- volumes) {
    result += getHoldsFromVolume(v);
  }

  return result;
}

list[Hold] getHoldsFromVolume(Volume v){
  switch (v){
    case circle(Point pos, int depth, int radius, list[Hold] frontHolds, list[Hold] sideHolds): {
      return frontHolds + sideHolds;
    }

    case triangle(Point pos, Point extrusion, int depth, list[Point] corners, list[Hold] leftHolds, list[Hold] rightHolds, list[Hold] bottomHolds): {
        return leftHolds + rightHolds + bottomHolds;
      }
  }

  return [];
}

list[Hold] getHoldsOfRoute(BoulderingRoute route, list[Hold] allHolds) {
  switch (route) {
    case boulderingRoute(str name, str grade, Point GridBasePoint, list[RouteHoldID] holdIDs): {
      list[str] names = [];

      for(holdID <- holdIDs) {
        names += getNamesFromRouteHoldID(holdID);
      }

      return [h | h <- allHolds, getHoldName(h) in names];
    }
  }
  return [];
}

list[str] getNamesFromRouteHoldID(RouteHoldID holdID) {
  switch (holdID) {
    case single_holdID(str id): {
      return [id];
    }

    case split_holdID(str leftId, str rightId): {
      return [leftId, rightId];
    }
  }

  return [];
}

str getHoldName(Hold h){
  switch (h){
    case hold(str name, _, _, _, _, _): {
      return name;
    }
  }

  return "";
}

list[Colour] getHoldColours(Hold h) {
  switch (h) {
    case hold(_, _, _, _, list[Colour] colours, _): {
      return colours;
    }
  }

  return [];
}
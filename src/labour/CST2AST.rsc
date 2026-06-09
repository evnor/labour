module labour::CST2AST

// This provides println which can be handy during debugging.
import IO;

// These provide useful functions such as toInt, keep those in mind.
import Prelude;
import String;

import labour::AST;
import labour::Syntax;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 * Hint: Use switch to do case distinction with concrete patterns
 * Map regular CST arguments (e.g., *, +, ?) to lists
 * Map lexical nodes to Rascal primitive types (bool, int, str)
 */
// Because some valid ParseTrees cannot be represented by an AST,
// we sometimes raise an AssertionFailed error. Therefore we 
// modify checkWellformedness.
labour::AST::BoulderingWall cst2ast(start[BoulderingWall] wall) {
  return build(wall.top);
}

labour::AST::BoulderingWall build((BoulderingWall) `bouldering_wall "<Name name>" { <Routes rs>, <Volumes vs> }`) {
  return boulderingWall("<name>", build(rs), build(vs));
}

list[Volume] build((Volumes) `volumes [ <{Volume ","}+ vs> ]`) {
  return [build(v) | v <- vs];
}

list[BoulderingRoute] build((Routes) `routes [ <{BoulderingRoute ","}+ rs> ]`) {
  return [build(r) | r <- rs ];
}

BoulderingRoute build((BoulderingRoute) `bouldering_route "<Name name>" { <Grade grade>, grid_base_point <Point p>, holds [<{RouteHoldID ","}+ holds>] }`) {
  return boulderingRoute("<name>", "<grade>", build(p), [build(h) | h <- holds]);
}

RouteHoldID build((RouteHoldID) `"<HoldID id>"`) {
  return single_holdID("<id>");
}

RouteHoldID build((RouteHoldID) `{ "<HoldID a>", "<HoldID b>" }`) {
  return split_holdID("<a>", "<b>");
}

Volume build((Volume) `circle { <VolumePosition vp>, <Depth depth>, radius: <Integer r>, front_holds [<{Hold ","}* fhs>], side_holds [<{Hold ","}* shs>] }`) {
  return circle(build(vp), build(depth), build(r), [build(h) | h <- fhs], [build(h) | h <- shs]);
}

Volume build((Volume) `triangle { <VolumePosition vp>, extrusion: <Point ext>, <Depth depth>, corners [<{Point ","}+ corners>], <{TriangleHolds ","}* holds> }`) {
  // Handle the TriangeHolds section
  tuple[list[Hold], list[Hold], list[Hold]] hs = build(holds);
  return triangle(build(vp), build(ext), build(depth), [build(p) | p <- corners ], hs<0>, hs<1>, hs<2>);
}

// returns <left_holds, right_holds, bottom_holds>
tuple[list[Hold], list[Hold], list[Hold]] build({TriangleHolds ","}* t_holds) {
  map[str, list[Hold]] holds = ();
  visit (t_holds) {
    case (TriangleHolds) `left_holds [ <{Hold ","}* hs>]`: {
      assert "left" notin holds : "Overlapping assignments for left_holds";
      holds["left"] = [build(h) | h <- hs];
    }
    case (TriangleHolds) `right_holds [ <{Hold ","}* hs>]`: {
      assert "right" notin holds : "Overlapping assignments for right_holds";
      holds["right"] = [build(h) | h <- hs];
    }
    case (TriangleHolds) `bottom_holds [ <{Hold ","}* hs>]`: {
      assert "bottom" notin holds : "Overlapping assignments for bottom_holds";
      holds["bottom"] = [build(h) | h <- hs];
    }
  }
  return <holds["left"] ? [], holds["right"] ? [], holds["bottom"] ? []>;
}

Point build((VolumePosition) `pos: <Point p>`) {
  return build(p);
}

int build((Depth) `depth: <Integer d>`) {
  return build(d);
}

bool is_none(Option[&T] val) {
  switch (val) {
    case none(): return true;
  }
  return false;
}
bool is_some(Option[&T] val) {
  switch (val) {
    case none(): return false;
  }
  return true;
}
&T unwrap_or(Option[&T] val, &T default_) {
  switch (val) { // Can you tell I like rust?
    case some(v): return v;
  }
  return default_;
}

// Handle HoldProperties. Each property may be specified only once, and some 
// may be specified zero times.
Hold build((Hold) `hold "<HoldID id>" { <{HoldProperties ","}+ all_props> }`) {
  Option[Position] pos = none();
  Option[str] shape = none();
  Option[int] rotation = none();
  Option[list[Colour]] colours = none();
  Option[HoldType] ht = none();

  visit (all_props) {
    case (HoldProperties) `<HoldPosition hp>`: {
      assert is_none(pos) : "Overlapping assignments for pos";
      pos = some(build(hp));
    }
    case (HoldProperties) `shape: "<String s>"`: {
      assert is_none(shape) : "Overlapping assignments for shape";
      shape = some("<s>");
    }
    case (HoldProperties) `rotation: <Integer r>`: {
      assert is_none(rotation) : "Overlapping assignments for rotation";
      rotation = some(build(r));
    }
    case (HoldProperties) `colours [<{Colour ","}+ cs>]`: {
      assert is_none(colours) : "Overlapping assignments for colours";
      colours = some([build(c) | c <- cs]);
    }
    case (HoldProperties) `start_hold: <Integer i>`: {
      assert is_none(ht) : "Overlapping assignments for star_hold/end_hold";
      ht = some(startHold(build(i)));
    }
    case (HoldProperties) `end_hold`: {
      assert is_none(ht) : "Overlapping assignments for star_hold/end_hold";;
      ht = some(endHold());
    }
  }
  // Required properties
  assert is_some(pos) : "Each hold must define a position";
  assert is_some(shape) : "Each hold must define a shape";
  assert is_some(colours) : "Each hold must define (a) colour(s)";
  return hold("<id>", unwrap_or(pos, point(9999,9999)), unwrap_or(shape, "ERR"), rotation, unwrap_or(colours, []), unwrap_or(ht, normal()));
}

Colour build(labour::Syntax::Colour c) {
  switch (c) {
    case (Colour) `white`: return white();
    case (Colour) `yellow`: return yellow();
    case (Colour) `green`: return green();
    case (Colour) `blue`: return blue();
    case (Colour) `red`: return red();
    case (Colour) `purple`: return purple();
    case (Colour) `pink`: return pink();
    case (Colour) `black`: return black();
    case (Colour) `orange`: return orange();
  }
  assert false : "Unreachable";
  return white();
}

Position build(HoldPosition hp) {
  switch (hp) {
    case (HoldPosition) `pos: <Point p>`: return frontPos(build(p));
    case (HoldPosition) `pos: { angle: <Integer ang> }`: return sidePos(build(ang));
  }
  assert false : "Unreachable";
  return sidePos(404);
}

Point build((Point) `{ x: <Integer x>, y: <Integer y> }`) {
  return point(build(x), build(y));
}

int build(Integer i) {
  return toInt("<i>");
}
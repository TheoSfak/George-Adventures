# Camera and enemy pathfinding — design

Date: 2026-10-14. Step 2 of the 1.5.0 batch (backlog item G of `HANDOVER.md`). Spec only, no plan (Theodore's rule for this batch).

## Problem

1. **Enemies have no navigation.** A skeleton walks in a straight line to its goal and, when it pushes against a house, a
   tree or a fence without getting anywhere, the anti-snag code (`Enemy._check_blocked`/`_detour`) sidesteps at random for a
   moment. The result is skeletons that jitter against walls, lose George behind a stall, and invaders (they march 150 m
   from the gates to the well) that get stuck on the way. The guards have their own, similar sidestep (`Guard._steer`).
2. **The camera can clip.** George's camera sits inside an enemy that stands right behind him (the spring arm only collides
   with layer 1, the world) and can end up inside the visual of a building because the box colliders of the houses are
   only 90% of the model's size (`Village._add_box_collider(shrink = 0.9)`).

## Decisions

- **Own grid pathfinder, not `NavigationServer3D`.** The world is flat (a ground box with its top at y = 0) and made of
  boxes and cylinders (936 static bodies in the village: 388 box, 527 cylinder, 7 capsule, 14 trimesh shapes), roughly 440 m
  across. Baking a navigation mesh of that size at run time is heavy and slow in tests, a grid built from the colliders
  themselves takes milliseconds to query and is deterministic. Godot's `AStarGrid2D` (C++) does the searching.
- **Direct first.** An enemy walks straight at its goal while the straight line is free on the grid; only a blocked line
  makes it follow a path. The old sidestep stays as the last fallback (moving obstacles, totems that appear later).
- **Visual feedback over precision for the camera:** characters that come near the camera fade out instead of being
  clipped; the arm keeps colliding with the world but with a larger margin.

## NavGrid (`scripts/nav_grid.gd`, `class_name NavGrid`, no autoload references)

- Built from a list of root nodes and a world rectangle (xz): every `StaticBody3D` with layer 1 under the roots (not
  `meta("nav_ignore")`) contributes the footprints of its enabled shapes: box (oriented rectangle), cylinder and sphere
  (circle), capsule (circle), convex and concave shapes (their triangles). A shape only blocks when its vertical extent
  meets the walking band `y = 0.3 .. 1.9` (so the ground box, roofs and bridge decks do not), and triangles that are
  nearly horizontal are skipped.
- **Clearance classes.** The raster is 0.5 m; for an enemy of collision radius `r` the obstacles are inflated by
  `ceil((r + 0.2) / 0.6) * 0.6` metres (0.6, 1.2, 1.8, ...). Each class has its own raster and `AStarGrid2D` (1 m cells,
  a coarse cell is solid when any of its four fine cells is), built the first time an enemy of that class asks (lazily,
  the common 0.6 class costs about 15 MB for the village).
- API: `NavGrid.build(roots, rect) -> NavGrid`, `blocked(pos, clearance)`, `line_clear(a, b, clearance)` (walks the fine
  raster every 0.25 m), `find_path(a, b, clearance) -> PackedVector3Array` (smoothed by line-of-sight shortcuts, ends at the
  nearest free point when the goal itself is blocked, empty when unreachable), `debug_image(clearance) -> Image`.
- Registry: `NavGrid.set_region(id, grid)` and `NavGrid.at(pos) -> NavGrid` (the grid whose rectangle contains `pos`,
  `null` elsewhere). Regions: `village` (built when the village is done, its hex extent), `catacombs` (at the end of
  `Catacombs.build`) and `frontier` (end of `Frontier.build`), each from its own root, so `Interiors` rooms (no enemies) and
  anything outside a region simply has no grid and enemies there behave as before.

## NavFollower (`scripts/nav_follower.gd`, `class_name NavFollower`, RefCounted)

One per walker. `direction(from, to, clearance, delta) -> Vector3` returns the flat unit direction to move: straight to `to`
when the line is clear (or there is no grid), otherwise the direction to the next waypoint of a stored path. The path is
recomputed when it is older than 0.6 s with the goal moved more than 1.5 m, when the walker has strayed from it, or when it
runs out; waypoints are reached at 0.7 m. A walker that finds no path keeps going straight (the old behaviour).
`active` tells the caller that it is currently walking a path (the enemy then faces its movement direction instead of
George). A global budget of 6 path searches per physics frame spreads out a crowd (a walker over budget keeps its old path).

## Enemy, guards

- `Enemy`: patrol target, march target, besiege return and the chase (melee and the closing-in of ranged ones) go through
  `_path_dir(target)` (a `NavFollower` plus the radius of the capsule, `0.4 * model_scale`), then through the old `_detour`.
- `Guard`: the chase of an invader and the walk back to the post use a `NavFollower` too; its sidestep stays.

## Camera

- `Player._update_camera` fades every character (groups `enemies`, `npcs`, `villagers`, `guards`) whose centre is closer
  than 2.0 m to the camera: `GeometryInstance3D.transparency` rises from 0 (at 2.0 m) to 1 (at 0.8 m) on all of its meshes,
  and returns to 0 when the camera leaves; the health bar and name tag fade with it. It only touches nodes that changed.
- The spring arm margin goes from 0.2 to 0.35. The house colliders keep their 0.9 size (George must still fit between
  houses). A camera sweep test (below) measures how often the camera ends up inside a house; only if it shows real clipping
  do the houses get a second, full-size body on an extra layer (bit 32) that only the spring arm looks at.

## Tests

- `nav_grid_test` (headless, synthetic world made of `StaticBody3D`s): a free line, a line blocked by a wall, a path around
  the end of a wall that is longer than the straight line and does not touch the wall, a rotated box, a cylinder, a goal
  inside an obstacle ends next to it, an unreachable goal inside a closed ring gives an empty path, clearance classes (a 1.5 m
  gap passes class 0.6 and not class 1.2), regions (`at`), a horizontal slab above the band does not block.
- `nav_follower_test` (headless, `CharacterBody3D` walkers with capsules): a walker behind a wall reaches a goal on the
  other side; a walker with a free line walks straight (`active` false); a crowd of 40 respects the search budget.
- `nav_world_test` (headless, the real village): the grid exists after the world is built, took under 1.5 s, every
  enemy spawn can reach the well, a path from the north-west bandit hideout to the well exists, and
  `debug_image` is saved to the output folder for a look.
- `enemy_nav_test` (headless): a skeleton behind the real tent/house of the village chases George around it and arrives
  (and an invader marches from a gate to the well); `guard_snag_test` still passes (it has a flaky history).
- `camera_test` (headless): the enemy right behind George is transparent and back to opaque when it leaves; the camera sweep
  around every house (yaw steps of 15 degrees, three pitches, three zooms) reports how many positions lie inside a collider or
  closer than 0.3 m to one.
- `navshot` (windowed): screenshots of skeletons walking around the stall ring and a house, and of the grid overlay.
- `perftest` stays at 60 fps with 40 enemies chasing.

## Not included

Avoidance between enemies, jumping, a grid for the interior rooms, moving obstacles in the grid, navigation for villagers
and NPCs, true camera collision against the visual meshes.

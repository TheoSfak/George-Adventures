# The Great Tree and its lake Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A new walkable showcase place east of the village: a turquoise lake with a central rock island carrying a giant tree and two houses, four smaller islands, wooden rope bridges, a stone causeway ramp, umbrella trees, flowers, a chest and hot-air balloons drifting overhead, all in the game's low-poly style at 60 fps.

**Architecture:** `scripts/tree_meshes.gd` (`TreeMeshes`) is a pure geometry library: flat-shaded `ArrayMesh`es with vertex colours (islands, tree, umbrella trees, bridges, ramp, balloon, props) built from a small triangle-soup builder; no scene access, so it is unit-testable headless. `scripts/great_tree.gd` (`GreatTree`, a `Node3D` added by `Village`) holds the layout data, builds the lake, islands, bridges, ramp, props and colliders from those meshes, and `scripts/balloon.gd` (`Balloon`) drifts the balloons. Everything the player walks on is a trimesh collider on layer 1, so the existing `CharacterBody3D` controls need no change.

**Tech Stack:** Godot 4.7.2 / GDScript (tabs). Spec: `docs/superpowers/specs/2026-10-13-big-tree-lake-design.md`.

## Global Constraints

- **ALL IN-GAME TEXT IS GREEK.** Code, comments and file names are English. Edit Greek files only with the Edit/Write tools (UTF-8), never with shell heredocs or Python on Windows.
- GDScript files use **tabs**. Write `var x: bool = ...` / `var s: String = dict["k"]` when a type would otherwise be inferred from a `Variant`.
- **No gameplay change:** no new systems, no NPCs or quests, the player controller is untouched. Everything walkable is on collision layer 1.
- The look is flat-shaded low poly with one colour per vertex (`TreeMeshes.material()`), KayKit-like. Do not add textures.
- Light budget: at most **3** real lights in the area (group `night_lights`); lanterns glow through emissive materials only.
- In `--script` test drivers: start with `await process_frame`, set `root.get_node("/root/Quests").intro_seen = true`; `TreeMeshes` can be type-referenced, but load `GreatTree` with `load("res://scripts/great_tree.gd")` (untyped) because its script pulls in classes that mention autoloads (`Chest`, `Terrain`); do not type-reference `Chest`, `Npc`, `SaveGame`.
- After adding a `class_name` script or assets run `godot --headless --import`.
- Windowed tests need the GPU and this PC's GPU memory is shared with other programs: if a run crashes (`Couldn't create Vulkan image`, `LLVM ERROR: out of memory`, segmentation fault) retry, use 1280x720, or split the run into parts; do not kill Theodore's Godot processes.
- Git: Theodore is the sole author. **No `Co-Authored-By`, no "Generated with Claude Code", no attribution trailer** in any commit message. Work on branch `feature/great-tree` (cut from `main`), commit per task. Do NOT push, tag, bump `config/version` or create a release: Theodore asks for that separately.
- Run headless tests with a timeout (a script error inside a coroutine otherwise hangs): `timeout 150 godot --path . --headless --script tools/<name>.gd > /tmp/t.txt 2>&1; echo exit=$?; grep -c "^PASS" /tmp/t.txt; grep "^FAIL\|SCRIPT ERROR" /tmp/t.txt`
- The coordinates below are **local to the area centre** `CENTER = (172, -40)` (world x, z) unless a step says world.

## Layout (refined from the spec; these numbers are what the code and tests use)

| Piece | Local (x, z) | Size |
|---|---|---|
| Lake | (0, 0) | oval radii 36 (x) and 30 (z), water surface y 0.10, sandy ring to radius 40 |
| Central island | (4, 0) | radius 11, plateau top y 7.0 |
| Entry island | (-24, 3) | radius 5, top y 2.4 |
| South island | (-10, 21) | radius 5, top y 5.0 (umbrella trees, chest) |
| East island | (22, 16) | radius 5.5, top y 5.2 (bench) |
| Far island | (28, -4) | radius 5, top y 3.4 (umbrella trees) |
| Great tree | (4, -1) on the plateau | trunk about 22 m, canopy radius about 16 m at y 21 to 33 |
| Houses | (-3.5, -4.5) and (4.5, -9) on the plateau | KayKit homes, scale about 5 |
| Shore bridge | from (-41, 2.5) on dry ground to the entry island | the way in from the village |
| Stone causeway ramp | circle radius 16.5 around (4, 0), from angle 180 to 330 degrees, y 2.4 up to 7.0 | width 2.6, slope about 6 degrees, on stone pillars; ends in a flat stub onto the plateau |
| Other bridges | entry to ramp foot, entry to south, south to plateau, east to plateau, east to far | width 2.2, sag 1.5% of the length |
| Balloons | 4 drifting at y 28 to 42 on ellipses of radius 30 to 50, 1 moored on the entry island | striped, with a basket |

This refines the spec table (islands spaced further apart so every bridge has a usable length, the moored balloon moved to the entry island, the ramp is a causeway around the central island so every slope stays under 15 degrees).

## File Structure

| File | Responsibility |
|---|---|
| `scripts/tree_meshes.gd` (new) | `TreeMeshes`: palette, `Soup` builder, `lathe`, island, great tree, umbrella tree, bridge, ramp, pillar, balloon, bench, lanterns, flowers, lily pads, deck ring, collision meshes, slope helper. |
| `scripts/great_tree.gd` (new) | `GreatTree`: layout constants and static helpers, builds the lake, islands, bridges, ramp, tree, houses, props, chest, lights, dressing, balloons. |
| `scripts/balloon.gd` (new) | `Balloon`: drifting or moored hot-air balloon. |
| `scripts/village.gd` | `_build_great_tree()` hook, the keg quest item and the signpost. |
| `scripts/enemies.gd` | Two skeleton spawns moved out of the area. |
| `scripts/minimap.gd`, `scripts/strings_el.gd` | Place name on the big map. |
| `scripts/sound_manager.gd` | Two positional loops at the lake. |
| `tools/tree_meshes_test.gd`, `great_tree_walk_test.gd`, `great_tree_props_test.gd`, `balloon_test.gd`, `great_tree_integration_test.gd` (headless), `tools/greattreeshot.gd` (windowed) (new) | Tests and screenshots. |
| `CLAUDE.md`, `HANDOVER.md`, `CHANGELOG.md` | Documentation (unreleased `0.16-beta`). |

### Interfaces used across tasks (names must not change)

- `TreeMeshes.material() -> StandardMaterial3D`; `TreeMeshes.Soup` with `tri`, `quad`, `box`, `strut`, `build() -> ArrayMesh`.
- `TreeMeshes.lathe(profile, segments, seed_value, wobble, outline, stripes, drip_ring, drip_color) -> ArrayMesh`, `lathe_into(soup, xform, ...)`.
- `TreeMeshes.island(radius, top_y, seed_value)`, `great_tree(seed_value)`, `umbrella_tree(height, canopy_radius, seed_value)`, `bridge(a, b)`, `bridge_collision(a, b)`, `bridge_line(a, b, steps)`, `bridge_steps(a, b)`, `ramp_line(center, radius, a0_deg, a1_deg, y0, y1, steps)`, `ramp(line, width)`, `ramp_collision(line, width)`, `pillar(top_y, seed_value)`, `balloon(stripes, seed_value)`, `bench()`, `lanterns_posts(points)`, `lanterns_heads(points)`, `flowers(points, seed_value)`, `lily_pads(points, seed_value)`, `deck_ring(inner, outer, count)`, `max_slope(line)`.
- `GreatTree.CENTER`, `LAKE`, `AREA_RADIUS`, `WATER_Y`, `SHORE_Y`, `ISLANDS`, `RAMP`, `SHORE_START`, `TREE_POS`, `TREE_FOOT`, `CHEST_POS`, `static to_world(local)`, `static island_point(name, toward, inset)`, `static plateau_point(toward, radius)`, `static ramp_points()`, `static bridge_list()`, `static walk_main()`, `static walk_south()`, `static walk_far()`.

---

### Task 1: The geometry library `TreeMeshes`

**Files:**
- Create: `scripts/tree_meshes.gd`, `tools/tree_meshes_test.gd`

**Interfaces:**
- Produces: everything in "Interfaces used across tasks" under `TreeMeshes`.

- [ ] **Step 0: Create the working branch**

```bash
cd "C:/Users/user/Desktop/George Adventures" && git switch main && git switch -c feature/great-tree && git status --short
```
Expected: `Switched to a new branch 'feature/great-tree'`, clean tree.

- [ ] **Step 1: Write the failing test**

Create `tools/tree_meshes_test.gd`:

```gdscript
extends SceneTree
## The procedural geometry of the Great Tree area (no scene needed):
##   godot --path . --headless --script tools/tree_meshes_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


## Number of triangles whose winding is wrong (Godot's front faces are clockwise seen from outside,
## so the right-hand cross product must point AGAINST the stored outward normal) or whose normal is not unit.
func bad_triangles(mesh: ArrayMesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var bad := 0
	for i in range(0, v.size(), 3):
		var cr := (v[i + 1] - v[i]).cross(v[i + 2] - v[i])
		if cr.dot(n[i]) >= 0.0 or absf(n[i].length() - 1.0) > 0.001:
			bad += 1
	return bad


func tri_count(mesh: ArrayMesh) -> int:
	if mesh.get_surface_count() == 0:
		return 0
	return (mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	# --- the triangle builder
	var s := TreeMeshes.Soup.new()
	s.tri(Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, 1), Color.WHITE, Color.WHITE, Color.WHITE, Vector3(0, -1, 0))
	var m := s.build()
	check("a triangle above its inside point gets an upward normal", m.surface_get_arrays(0)[Mesh.ARRAY_NORMAL][0].y > 0.99)
	check("and clockwise winding seen from above", bad_triangles(m) == 0)
	var s2 := TreeMeshes.Soup.new()
	s2.tri(Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, 1), Color.WHITE, Color.WHITE, Color.WHITE, Vector3(0, 5, 0))
	check("the same triangle below its inside point faces down", s2.build().surface_get_arrays(0)[Mesh.ARRAY_NORMAL][0].y < -0.99)
	var s3 := TreeMeshes.Soup.new()
	s3.tri(Vector3.ZERO, Vector3.ZERO, Vector3.RIGHT, Color.WHITE, Color.WHITE, Color.WHITE, Vector3.DOWN)
	check("a degenerate triangle is skipped", s3.build().get_surface_count() == 0)
	var s4 := TreeMeshes.Soup.new()
	s4.box(Vector3.ZERO, Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(2, 1, 3), Color.RED)
	var bm := s4.build()
	check("a box has 12 triangles, all outward and clockwise", tri_count(bm) == 12 and bad_triangles(bm) == 0)
	check("the box measures 2 x 1 x 3", bm.get_aabb().size.is_equal_approx(Vector3(2, 1, 3)))
	var s5 := TreeMeshes.Soup.new()
	s5.strut(Vector3.ZERO, Vector3(0, 4, 0), 0.2, Color.GREEN)
	check("a vertical strut is 4 m long and 0.2 m thick", s5.build().get_aabb().size.is_equal_approx(Vector3(0.2, 4, 0.2)))

	# --- an island
	var isl := TreeMeshes.island(5.0, 7.0, 11)
	var ia := isl.get_aabb()
	check("island: one surface, many triangles (%d)" % tri_count(isl), isl.get_surface_count() == 1 and tri_count(isl) > 200)
	check("island: the plateau is flat at its top height (max y %.3f)" % ia.end.y, absf(ia.end.y - 7.0) < 0.001)
	check("island: the cliff goes down below the water (min y %.2f)" % ia.position.y, absf(ia.position.y + 1.6) < 0.001)
	var reach := maxf(maxf(absf(ia.position.x), ia.end.x), maxf(absf(ia.position.z), ia.end.z))
	check("island: radius fits (%.2f for radius 5)" % reach, reach > 4.0 and reach < 6.6)
	check("island: every triangle is clockwise and outward", bad_triangles(isl) == 0)
	var arrays := isl.surface_get_arrays(0)
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var tops := 0
	var top_wrong := 0
	for i in range(0, verts.size(), 3):
		if norms[i].y > 0.9:
			tops += 1
			if (verts[i].y + verts[i + 1].y + verts[i + 2].y) / 3.0 < 6.5:
				top_wrong += 1
	check("island: the top faces up (%d triangles) and nothing faces up lower down" % tops, tops >= 60 and top_wrong == 0)
	check("island: the same seed gives the same shape, another seed another one",
			TreeMeshes.island(5.0, 7.0, 11).surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == arrays[Mesh.ARRAY_VERTEX] and TreeMeshes.island(5.0, 7.0, 12).surface_get_arrays(0)[Mesh.ARRAY_VERTEX] != arrays[Mesh.ARRAY_VERTEX])
	check("island: the trimesh collider can be made", isl.create_trimesh_shape() != null)

	# --- the great tree
	var tree := TreeMeshes.great_tree(21)
	var ta := tree.get_aabb()
	check("tree: about 30 m tall and 30 m wide (%s)" % str(ta.size), ta.end.y > 29.0 and ta.end.y < 36.0 and ta.size.x > 24.0 and ta.size.z > 24.0)
	check("tree: a sensible number of triangles (%d)" % tri_count(tree), tri_count(tree) > 1000 and tri_count(tree) < 16000)
	check("tree: clockwise and outward", bad_triangles(tree) == 0)

	# --- umbrella tree
	var um := TreeMeshes.umbrella_tree(5.0, 3.5, 5)
	check("umbrella tree: height and canopy (%s)" % str(um.get_aabb().size), um.get_aabb().size.y > 5.0 and um.get_aabb().size.x > 6.0 and bad_triangles(um) == 0)

	# --- bridges
	var a := Vector3(0, 0.03, 0)
	var b := Vector3(12, 2.4, 0)
	var line := TreeMeshes.bridge_line(a, b, 20)
	check("bridge line: starts and ends exactly on its endpoints", line[0] == a and line[20].is_equal_approx(b))
	check("bridge line: sags in the middle (%.3f below the straight line)" % (a.lerp(b, 0.5).y - line[10].y), line[10].y < a.lerp(b, 0.5).y - 0.05)
	check("bridge line: slope %.3f stays under 0.27" % TreeMeshes.max_slope(line), TreeMeshes.max_slope(line) < 0.27)
	var br := TreeMeshes.bridge(a, b)
	check("bridge: spans from a to b and is wider than 2 m (%s)" % str(br.get_aabb().size), br.get_aabb().size.x > 11.9 and br.get_aabb().size.z >= 2.2 and bad_triangles(br) == 0)
	var bc := TreeMeshes.bridge_collision(a, b)
	check("bridge collision: a deck and rails 1.1 m high", bc.get_aabb().size.y > 1.1 + 2.0 and bc.create_trimesh_shape() != null)

	# --- ramp and pillar
	var rl := TreeMeshes.ramp_line(Vector2(4, 0), 16.5, 180.0, 330.0, 2.4, 7.0, 44)
	check("ramp line: 45 points from y 2.4 up to y 7.0", rl.size() == 45 and is_equal_approx(rl[0].y, 2.4) and is_equal_approx(rl[44].y, 7.0))
	check("ramp line: slope %.3f stays under 0.15" % TreeMeshes.max_slope(rl), TreeMeshes.max_slope(rl) < 0.15)
	check("ramp line starts west of the island and ends north-east", rl[0].x < -8.0 and rl[44].x > 15.0 and rl[44].z < -6.0)
	var rm := TreeMeshes.ramp(rl, 2.6)
	check("ramp: a mesh with stone and parapets, clockwise (%d triangles)" % tri_count(rm), tri_count(rm) > 800 and bad_triangles(rm) == 0)
	check("ramp collision", TreeMeshes.ramp_collision(rl, 2.6).create_trimesh_shape() != null)
	var pil := TreeMeshes.pillar(5.0, 3)
	check("pillar: from below the water up to the deck", pil.get_aabb().position.y < -1.5 and pil.get_aabb().end.y > 4.4 and bad_triangles(pil) == 0)

	# --- balloon
	var bal := TreeMeshes.balloon([Color(1.0, 0.5, 0.2), Color(0.98, 0.9, 0.7)], 4)
	var seen := {}
	for c in bal.surface_get_arrays(0)[Mesh.ARRAY_COLOR]:
		seen[(c as Color).to_html(false)] = true
	check("balloon: about 17 m tall with a basket at the bottom (%s)" % str(bal.get_aabb()), bal.get_aabb().position.y >= -0.01 and bal.get_aabb().end.y > 15.0 and bal.get_aabb().size.x > 8.0 and bad_triangles(bal) == 0)
	check("balloon: striped (%d colours)" % seen.size(), seen.size() > 6)

	# --- props
	check("bench", tri_count(TreeMeshes.bench()) > 40)
	var pts: Array[Vector3] = [Vector3(1, 0, 1), Vector3(-2, 0, 3), Vector3(4, 0, -1)]
	check("lanterns: posts and heads", tri_count(TreeMeshes.lanterns_posts(pts)) >= 3 * 10 and tri_count(TreeMeshes.lanterns_heads(pts)) >= 3 * 10)
	check("flowers: stems and heads", tri_count(TreeMeshes.flowers(pts, 2)) >= 3 * 12)
	check("lily pads", tri_count(TreeMeshes.lily_pads(pts, 2)) >= 3 * 8)
	var ring := TreeMeshes.deck_ring(5.0, 7.0, 24)
	check("deck ring: 24 planks around the trunk", tri_count(ring) == 24 * 12 and ring.get_aabb().size.x > 13.9 and bad_triangles(ring) == 0)
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it and watch it fail**

Run: `timeout 100 godot --path . --headless --script tools/tree_meshes_test.gd > /tmp/t.txt 2>&1; echo exit=$?; grep "^PASS\|^FAIL\|SCRIPT ERROR" /tmp/t.txt | head -3`
Expected: script errors ("TreeMeshes" not declared), exit 1.

- [ ] **Step 3: Create the library**

Create `scripts/tree_meshes.gd`:

```gdscript
class_name TreeMeshes
extends RefCounted
## Procedural low-poly geometry for the Great Tree area (scripts/great_tree.gd): islands, the tree, umbrella
## trees, bridges, the stone causeway, balloons and small props. Everything is flat-shaded with one colour
## per vertex (draw it with material()) and is built around the local origin; nothing here touches the
## scene tree, so it can be tested without a world.

# --- palette (sRGB, KayKit-like)
const MOSS_A := Color(0.38, 0.58, 0.22)
const MOSS_B := Color(0.46, 0.66, 0.26)
const MOSS_DRIP := Color(0.34, 0.54, 0.20)
const GRASS_DARK := Color(0.28, 0.46, 0.18)
const ROCK_A := Color(0.52, 0.45, 0.35)
const ROCK_B := Color(0.45, 0.39, 0.31)
const ROCK_C := Color(0.34, 0.30, 0.26)
const STONE_A := Color(0.68, 0.64, 0.57)
const STONE_B := Color(0.58, 0.54, 0.48)
const STONE_C := Color(0.50, 0.47, 0.42)
const WOOD_A := Color(0.58, 0.42, 0.27)
const WOOD_B := Color(0.50, 0.36, 0.23)
const WOOD_DARK := Color(0.36, 0.26, 0.17)
const ROPE := Color(0.66, 0.56, 0.36)
const BARK_A := Color(0.43, 0.31, 0.21)
const BARK_B := Color(0.37, 0.27, 0.18)
const BARK_C := Color(0.30, 0.22, 0.16)
const LEAF_LIGHT := Color(0.52, 0.76, 0.26)
const LEAF_MID := Color(0.34, 0.62, 0.21)
const LEAF_DARK := Color(0.22, 0.45, 0.17)
const LANTERN := Color(1.0, 0.86, 0.5)
const PAD := Color(0.24, 0.58, 0.26)
const FLOWER_COLORS: Array[Color] = [
	Color(1.0, 0.62, 0.74), Color(1.0, 0.85, 0.30), Color(0.97, 0.97, 0.92), Color(1.0, 0.58, 0.24), Color(0.52, 0.64, 1.0),
]
const BRIDGE_WIDTH := 2.2

static var _material: StandardMaterial3D


## The one material every mesh of this file uses (vertex colours are the albedo).
static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.roughness = 0.95
	return _material


## A growing list of flat-shaded triangles with one colour per vertex.
class Soup:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()

	## One triangle. `inside` is any point inside the solid: the triangle is turned so that it faces away
	## from it (Godot's front faces are clockwise seen from outside) and gets that outward flat normal.
	func tri(a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color, inside: Vector3) -> void:
		var cr := (b - a).cross(c - a)
		if cr.length_squared() < 0.0000001:
			return
		var outward := (a + b + c) / 3.0 - inside
		var n := cr.normalized()
		if cr.dot(outward) > 0.0:
			# counter-clockwise seen from outside: swap two vertices to make it clockwise
			var tv := b
			b = c
			c = tv
			var tc := cb
			cb = cc
			cc = tc
		else:
			n = -n
		verts.push_back(a)
		verts.push_back(b)
		verts.push_back(c)
		norms.push_back(n)
		norms.push_back(n)
		norms.push_back(n)
		cols.push_back(ca)
		cols.push_back(cb)
		cols.push_back(cc)

	## A quad as two triangles; a, b, c, d go around its border.
	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, ca: Color, cb: Color, cc: Color, cd: Color, inside: Vector3) -> void:
		tri(a, b, c, ca, cb, cc, inside)
		tri(a, c, d, ca, cc, cd, inside)

	## An oriented box: `ax` (length), `ay` (up) and `az` (width) are unit axes, `size` = (length, height, width).
	func box(center: Vector3, ax: Vector3, ay: Vector3, az: Vector3, size: Vector3, color: Color, top_color: Color = Color(0, 0, 0, 0)) -> void:
		var tc := color if top_color.a == 0.0 else top_color
		var hx := ax * size.x * 0.5
		var hy := ay * size.y * 0.5
		var hz := az * size.z * 0.5
		var c000 := center - hx - hy - hz
		var c100 := center + hx - hy - hz
		var c010 := center - hx + hy - hz
		var c110 := center + hx + hy - hz
		var c001 := center - hx - hy + hz
		var c101 := center + hx - hy + hz
		var c011 := center - hx + hy + hz
		var c111 := center + hx + hy + hz
		quad(c010, c110, c111, c011, tc, tc, tc, tc, center)
		quad(c000, c100, c101, c001, color, color, color, color, center)
		quad(c100, c110, c111, c101, color, color, color, color, center)
		quad(c000, c010, c011, c001, color, color, color, color, center)
		quad(c001, c101, c111, c011, color, color, color, color, center)
		quad(c000, c100, c110, c010, color, color, color, color, center)

	## A thin square beam from `a` to `b` (ropes, posts, vines, rails).
	func strut(a: Vector3, b: Vector3, thickness: float, color: Color) -> void:
		var d := b - a
		var length := d.length()
		if length < 0.001:
			return
		var ax := d / length
		var ref := Vector3.UP if absf(ax.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		var az := ax.cross(ref).normalized()
		var ay := az.cross(ax).normalized()
		box((a + b) * 0.5, ax, ay, az, Vector3(length, thickness, thickness), color)

	func build() -> ArrayMesh:
		var mesh := ArrayMesh.new()
		if verts.is_empty():
			return mesh
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = norms
		arrays[Mesh.ARRAY_COLOR] = cols
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh


# ----------------------------------------------------------------------- lathe ----

## Revolves `profile` around the Y axis into `soup`, moved and turned by `xform`.
## profile: Array of [radius, y, Color]; a first or last radius of 0 closes that end to a point.
## `outline` (Callable angle -> factor) wobbles every ring the same way (an island rim), `wobble` adds a
## little random radius jitter per vertex, `stripes` (colours by segment) paints vertical stripes (the
## ring colour then only gives the brightness), `drip_ring` / `drip_color` streak one ring with moss.
static func lathe_into(soup: Soup, xform: Transform3D, profile: Array, segments: int, seed_value: int, wobble := 0.0,
		outline := Callable(), stripes: Array = [], drip_ring := -1, drip_color := Color.WHITE) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rings := profile.size()
	var y_mid := 0.0
	for p in profile:
		y_mid += float(p[1])
	y_mid /= float(maxi(rings, 1))
	var inside := xform * Vector3(0.0, y_mid, 0.0)
	var pts: Array = []
	var cols: Array = []
	for i in rings:
		var r0: float = float(profile[i][0])
		var y: float = float(profile[i][1])
		var base: Color = profile[i][2]
		var row := PackedVector3Array()
		var crow := PackedColorArray()
		for s in segments:
			var ang := TAU * float(s) / float(segments)
			var r := r0
			if r0 > 0.0:
				if outline.is_valid():
					r *= float(outline.call(ang))
				if wobble > 0.0:
					r *= 1.0 + rng.randf_range(-wobble, wobble)
			row.append(xform * Vector3(cos(ang) * r, y, sin(ang) * r))
			var c := base
			if not stripes.is_empty():
				var st: Color = stripes[s % stripes.size()]
				c = Color(st.r * base.r, st.g * base.r, st.b * base.r, 1.0)
			var jitter := 1.0 + rng.randf_range(-0.05, 0.05)
			c = Color(c.r * jitter, c.g * jitter, c.b * jitter, 1.0)
			if i == drip_ring and rng.randf() < 0.3:
				c = drip_color
			crow.append(c)
		pts.append(row)
		cols.append(crow)
	for i in rings - 1:
		for s in segments:
			var s1 := (s + 1) % segments
			soup.quad(pts[i][s], pts[i][s1], pts[i + 1][s1], pts[i + 1][s],
					cols[i][s], cols[i][s1], cols[i + 1][s1], cols[i + 1][s], inside)


static func lathe(profile: Array, segments: int, seed_value: int, wobble := 0.0, outline := Callable(), stripes: Array = [],
		drip_ring := -1, drip_color := Color.WHITE) -> ArrayMesh:
	var s := Soup.new()
	lathe_into(s, Transform3D.IDENTITY, profile, segments, seed_value, wobble, outline, stripes, drip_ring, drip_color)
	return s.build()


## A basis whose Y axis points along `dir` (to lay a cone on its side).
static func _basis_with_y(dir: Vector3) -> Basis:
	var y := dir.normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x := y.cross(ref).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


# --------------------------------------------------------------------- islands ----

## A rock island: a flat mossy top at `top_y` (walkable), a rim of grass and a cliff of rock bands that
## goes down to y -1.6 (below the lake surface). Local origin = the centre of the island.
static func island(radius: float, top_y: float, seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var p1 := rng.randf() * TAU
	var p2 := rng.randf() * TAU
	var p3 := rng.randf() * TAU
	var outline := func(a: float) -> float:
		return 1.0 + 0.06 * sin(a * 3.0 + p1) + 0.04 * sin(a * 5.0 + p2) + 0.02 * sin(a * 9.0 + p3)
	var low := -1.6
	var y_lip := top_y - 0.35
	var profile := [
		[0.0, top_y, MOSS_A],
		[0.55 * radius, top_y, MOSS_B],
		[0.92 * radius, top_y - 0.05, MOSS_A],
		[1.03 * radius, y_lip, GRASS_DARK],
		[1.07 * radius, lerpf(y_lip, low, 0.33), ROCK_A],
		[0.97 * radius, lerpf(y_lip, low, 0.66), ROCK_B],
		[0.80 * radius, low, ROCK_C],
	]
	return lathe(profile, 32, seed_value + 1, 0.035, outline, [], 4, MOSS_DRIP)


# ------------------------------------------------------------------------ trees ----

static func _root_profile(length: float, radius: float) -> Array:
	return [[radius, 0.0, BARK_B], [radius * 0.62, length * 0.5, BARK_A], [radius * 0.18, length, BARK_B], [0.0, length * 1.03, BARK_B]]


static func _blob_profile(radius: float, light: Color, mid: Color, dark: Color) -> Array:
	return [
		[0.0, -radius * 0.85, dark],
		[radius * 0.62, -radius * 0.68, dark],
		[radius * 0.98, -radius * 0.15, mid],
		[radius * 0.92, radius * 0.4, mid],
		[radius * 0.55, radius * 0.82, light],
		[0.0, radius * 0.95, light],
	]


## The great tree: trunk with root flares, three limbs, a canopy of overlapping leaf blobs and hanging
## vines, about 22 m of trunk and a canopy up to y 33. Local origin = the foot of the trunk.
static func great_tree(seed_value: int) -> ArrayMesh:
	var s := Soup.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var height := 22.0
	var br := 3.0
	var trunk := [
		[br * 1.55, 0.0, BARK_C], [br * 1.15, height * 0.07, BARK_B], [br * 0.95, height * 0.2, BARK_A], [br * 1.0, height * 0.35, BARK_B],
		[br * 0.9, height * 0.55, BARK_A], [br * 0.8, height * 0.78, BARK_B], [br * 0.7, height, BARK_A],
	]
	lathe_into(s, Transform3D.IDENTITY, trunk, 14, seed_value, 0.07)
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.3 + rng.randf_range(-0.2, 0.2)
		var dir := Vector3(cos(a) * 0.85, -0.52, sin(a) * 0.85)
		var start := Vector3(cos(a) * 2.4, 2.6, sin(a) * 2.4)
		lathe_into(s, Transform3D(_basis_with_y(dir), start), _root_profile(6.5, 1.0), 8, seed_value + i, 0.05)
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.8
		var dir := Vector3(cos(a) * 0.7, 0.7, sin(a) * 0.7)
		var start := Vector3(cos(a) * 1.8, 17.0, sin(a) * 1.8)
		lathe_into(s, Transform3D(_basis_with_y(dir), start), _root_profile(9.0, 0.8), 8, seed_value + 10 + i, 0.05)
	var blobs := [
		[Vector3(0, 27.5, 0), 9.5], [Vector3(7.5, 25.5, 3.0), 7.0], [Vector3(-6.5, 26.0, 5.5), 7.2], [Vector3(-3.0, 25.2, -8.0), 7.5],
		[Vector3(6.0, 26.5, -6.5), 7.0], [Vector3(11.5, 22.5, 2.0), 5.2], [Vector3(-11.0, 23.0, -1.0), 5.5], [Vector3(2.5, 22.0, 11.5), 5.0],
		[Vector3(-1.5, 23.0, -12.0), 5.3], [Vector3(0, 31.0, 0), 6.0],
	]
	for i in blobs.size():
		var light := LEAF_LIGHT.lerp(LEAF_MID, float(i % 3) * 0.35)
		var mid := LEAF_MID.lerp(LEAF_LIGHT, float(i % 2) * 0.25)
		var xf := Transform3D(Basis.from_scale(Vector3(1.0, 0.78, 1.0)), blobs[i][0])
		lathe_into(s, xf, _blob_profile(float(blobs[i][1]), light, mid, LEAF_DARK), 10, seed_value + 20 + i, 0.12)
	for i in 14:
		var a := TAU * float(i) / 14.0 + rng.randf_range(-0.2, 0.2)
		var r := rng.randf_range(6.0, 13.0)
		var top := Vector3(cos(a) * r, 21.5, sin(a) * r)
		var drop := rng.randf_range(3.0, 5.0)
		s.strut(top, top + Vector3(rng.randf_range(-0.3, 0.3), -drop, rng.randf_range(-0.3, 0.3)), 0.09, LEAF_MID)
	return s.build()


## A slim tree with a flat umbrella canopy (the mushroom-like trees of the picture).
static func umbrella_tree(height: float, canopy_radius: float, seed_value: int) -> ArrayMesh:
	var s := Soup.new()
	var trunk := [[0.5, 0.0, BARK_C], [0.34, height * 0.5, BARK_A], [0.26, height, BARK_B]]
	lathe_into(s, Transform3D.IDENTITY, trunk, 8, seed_value, 0.05)
	var r := canopy_radius
	var canopy := [
		[0.0, -0.10 * r, LEAF_DARK], [0.55 * r, -0.22 * r, LEAF_DARK], [r, -0.05 * r, LEAF_MID],
		[0.8 * r, 0.18 * r, LEAF_LIGHT], [0.35 * r, 0.30 * r, LEAF_LIGHT], [0.0, 0.32 * r, LEAF_LIGHT],
	]
	lathe_into(s, Transform3D(Basis.IDENTITY, Vector3(0.0, height, 0.0)), canopy, 12, seed_value + 1, 0.08)
	return s.build()


# ------------------------------------------------------------------- bridges ----

## Number of planks segments of a bridge (about 0.55 m each).
static func bridge_steps(a: Vector3, b: Vector3) -> int:
	return maxi(int(Vector2(b.x - a.x, b.z - a.z).length() / 0.55), 4)


## The centre line of a bridge deck from `a` to `b` with a shallow sag (1.5% of the length, at most 0.5 m).
static func bridge_line(a: Vector3, b: Vector3, steps: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var length := Vector2(b.x - a.x, b.z - a.z).length()
	var sag := minf(0.015 * length, 0.5)
	for i in steps + 1:
		var t := float(i) / float(steps)
		var p := a.lerp(b, t)
		p.y -= sag * 4.0 * t * (1.0 - t)
		out.append(p)
	return out


## Steepest slope (rise over run) along a polyline.
static func max_slope(line: Array[Vector3]) -> float:
	var worst := 0.0
	for i in line.size() - 1:
		var d: Vector3 = line[i + 1] - line[i]
		var h := Vector2(d.x, d.z).length()
		if h > 0.0001:
			worst = maxf(worst, absf(d.y) / h)
	return worst


## The frame of a deck segment: forward, up, sideways.
static func _frame(p0: Vector3, p1: Vector3) -> Array:
	var ax := (p1 - p0).normalized()
	var az := ax.cross(Vector3.UP).normalized()
	var ay := az.cross(ax).normalized()
	return [ax, ay, az]


## A plank bridge with stringers, two rope rails and posts, all in one mesh. Its deck top follows bridge_line.
static func bridge(a: Vector3, b: Vector3) -> ArrayMesh:
	var s := Soup.new()
	var steps := bridge_steps(a, b)
	var line := bridge_line(a, b, steps)
	var half := BRIDGE_WIDTH * 0.5
	for i in steps:
		var p0: Vector3 = line[i]
		var p1: Vector3 = line[i + 1]
		var f := _frame(p0, p1)
		var ax: Vector3 = f[0]
		var ay: Vector3 = f[1]
		var az: Vector3 = f[2]
		var mid := (p0 + p1) * 0.5
		var seg := p0.distance_to(p1)
		s.box(mid - ay * 0.1, ax, ay, az, Vector3(seg * 0.92, 0.2, BRIDGE_WIDTH), WOOD_A if i % 2 == 0 else WOOD_B)
		for side in [-1.0, 1.0]:
			var lat: Vector3 = az * (half - 0.05) * float(side)
			s.box(mid - ay * 0.28 + lat * 0.92, ax, ay, az, Vector3(seg * 1.02, 0.16, 0.2), WOOD_DARK)
			s.strut(p0 + lat + ay * 0.55, p1 + lat + ay * 0.55, 0.07, ROPE)
			s.strut(p0 + lat + ay * 1.05, p1 + lat + ay * 1.05, 0.07, ROPE)
			if i % 4 == 0:
				s.strut(p0 + lat - ay * 0.15, p0 + lat + ay * 1.2, 0.14, WOOD_DARK)
	var last: Vector3 = line[steps]
	var lf := _frame(line[steps - 1], last)
	for side in [-1.0, 1.0]:
		var lat: Vector3 = (lf[2] as Vector3) * (half - 0.05) * float(side)
		s.strut(last + lat - (lf[1] as Vector3) * 0.15, last + lat + (lf[1] as Vector3) * 1.2, 0.14, WOOD_DARK)
	return s.build()


## What the bridge collides with: a continuous deck slab and two invisible rail walls 1.1 m high.
static func bridge_collision(a: Vector3, b: Vector3) -> ArrayMesh:
	var s := Soup.new()
	var steps := bridge_steps(a, b)
	var line := bridge_line(a, b, steps)
	var half := BRIDGE_WIDTH * 0.5
	for i in steps:
		var p0: Vector3 = line[i]
		var p1: Vector3 = line[i + 1]
		var f := _frame(p0, p1)
		var ax: Vector3 = f[0]
		var ay: Vector3 = f[1]
		var az: Vector3 = f[2]
		var mid := (p0 + p1) * 0.5
		var seg := p0.distance_to(p1)
		s.box(mid - ay * 0.15, ax, ay, az, Vector3(seg * 1.05, 0.3, BRIDGE_WIDTH), WOOD_A)
		for side in [-1.0, 1.0]:
			s.box(mid + az * half * float(side) + ay * 0.55, ax, ay, az, Vector3(seg * 1.05, 1.1, 0.12), WOOD_A)
	return s.build()


# ----------------------------------------------------------------------- ramp ----

## The centre line of the stone causeway: an arc around `center` that climbs from y0 to y1.
static func ramp_line(center: Vector2, radius: float, a0_deg: float, a1_deg: float, y0: float, y1: float, steps: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in steps + 1:
		var t := float(i) / float(steps)
		var ang := deg_to_rad(lerpf(a0_deg, a1_deg, t))
		out.append(Vector3(center.x + cos(ang) * radius, lerpf(y0, y1, t), center.y + sin(ang) * radius))
	return out


## The stone causeway: a banded deck, a rock skirt below it and low parapets on both sides.
static func ramp(line: Array[Vector3], width: float) -> ArrayMesh:
	var s := Soup.new()
	for i in line.size() - 1:
		var f := _frame(line[i], line[i + 1])
		var ax: Vector3 = f[0]
		var ay: Vector3 = f[1]
		var az: Vector3 = f[2]
		var mid := (line[i] + line[i + 1]) * 0.5
		var seg := line[i].distance_to(line[i + 1])
		s.box(mid - ay * 0.2, ax, ay, az, Vector3(seg * 1.03, 0.4, width), STONE_A if i % 2 == 0 else STONE_B)
		s.box(mid - ay * 1.1, ax, ay, az, Vector3(seg * 1.03, 1.4, width * 0.86), ROCK_B)
		for side in [-1.0, 1.0]:
			s.box(mid + az * (width * 0.5 - 0.15) * float(side) + ay * 0.3, ax, ay, az, Vector3(seg * 1.03, 0.6, 0.3), STONE_C)
	return s.build()


static func ramp_collision(line: Array[Vector3], width: float) -> ArrayMesh:
	var s := Soup.new()
	for i in line.size() - 1:
		var f := _frame(line[i], line[i + 1])
		var ax: Vector3 = f[0]
		var ay: Vector3 = f[1]
		var az: Vector3 = f[2]
		var mid := (line[i] + line[i + 1]) * 0.5
		var seg := line[i].distance_to(line[i + 1])
		s.box(mid - ay * 0.2, ax, ay, az, Vector3(seg * 1.05, 0.4, width), STONE_A)
		for side in [-1.0, 1.0]:
			s.box(mid + az * (width * 0.5 - 0.05) * float(side) + ay * 0.55, ax, ay, az, Vector3(seg * 1.05, 1.1, 0.12), STONE_A)
	return s.build()


## A stone pillar under the causeway: from y -1.6 (below the lake bed) up to `top_y`.
static func pillar(top_y: float, seed_value: int) -> ArrayMesh:
	var mid := (top_y - 1.6) * 0.5
	var profile := [[1.0, -1.6, ROCK_C], [0.8, mid, ROCK_B], [0.85, top_y, ROCK_A]]
	return lathe(profile, 8, seed_value, 0.06)


# -------------------------------------------------------------------- balloon ----

## A hot-air balloon with stripes, rope lines and a wicker basket. Local origin = the bottom of the basket;
## the envelope is above it (y about 4 to 17).
static func balloon(stripes: Array, seed_value: int) -> ArrayMesh:
	var s := Soup.new()
	var g := func(v: float) -> Color:
		return Color(v, v, v)
	var envelope := [
		[0.0, -5.6, g.call(0.55)], [1.5, -4.9, g.call(0.70)], [3.4, -3.0, g.call(0.90)], [4.6, 0.0, g.call(1.0)],
		[4.3, 2.8, g.call(1.0)], [3.0, 5.0, g.call(0.95)], [1.2, 6.4, g.call(0.90)], [0.0, 6.9, g.call(0.85)],
	]
	lathe_into(s, Transform3D(Basis.IDENTITY, Vector3(0.0, 9.8, 0.0)), envelope, 12, seed_value, 0.0, Callable(), stripes)
	s.box(Vector3(0.0, 0.55, 0.0), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(1.5, 1.1, 1.5), WOOD_B, WOOD_A)
	s.box(Vector3(0.0, 1.12, 0.0), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(1.7, 0.12, 1.7), WOOD_DARK)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			s.strut(Vector3(0.65 * float(sx), 1.1, 0.65 * float(sz)), Vector3(1.4 * float(sx), 4.5, 1.4 * float(sz)), 0.06, ROPE)
	return s.build()


# ---------------------------------------------------------------------- props ----

## A wooden bench, 1.8 m long, facing +Z.
static func bench() -> ArrayMesh:
	var s := Soup.new()
	s.box(Vector3(0.0, 0.45, 0.0), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(1.8, 0.1, 0.5), WOOD_A)
	s.box(Vector3(0.0, 0.85, -0.22), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(1.8, 0.4, 0.08), WOOD_B)
	for sx in [-0.75, 0.75]:
		s.box(Vector3(float(sx), 0.22, 0.0), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(0.1, 0.44, 0.44), WOOD_DARK)
	return s.build()


## Posts of the lanterns at `points` (each point is the foot of a post).
static func lanterns_posts(points: Array[Vector3]) -> ArrayMesh:
	var s := Soup.new()
	for p in points:
		s.strut(p, p + Vector3(0.0, 2.0, 0.0), 0.14, WOOD_DARK)
		s.box(p + Vector3(0.0, 2.0, 0.0), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(0.5, 0.08, 0.5), WOOD_DARK)
	return s.build()


## The glowing heads of those lanterns (drawn with an emissive material).
static func lanterns_heads(points: Array[Vector3]) -> ArrayMesh:
	var s := Soup.new()
	for p in points:
		s.box(p + Vector3(0.0, 2.3, 0.0), Vector3.RIGHT, Vector3.UP, Vector3.BACK, Vector3(0.34, 0.46, 0.34), LANTERN)
	return s.build()


## Little flowers (a stem and a five-sided head) at `points`.
static func flowers(points: Array[Vector3], seed_value: int) -> ArrayMesh:
	var s := Soup.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for p in points:
		var color: Color = FLOWER_COLORS[rng.randi() % FLOWER_COLORS.size()]
		s.strut(p, p + Vector3(0.0, 0.45, 0.0), 0.05, LEAF_MID)
		var head := [[0.0, 0.0, color], [0.2, 0.05, color], [0.16, 0.17, color.lightened(0.15)], [0.0, 0.2, color.lightened(0.15)]]
		lathe_into(s, Transform3D(Basis.IDENTITY, p + Vector3(0.0, 0.45, 0.0)), head, 5, rng.randi())
	return s.build()


## Flat lily pads (a few with a pink flower) lying on the water at `points`.
static func lily_pads(points: Array[Vector3], seed_value: int) -> ArrayMesh:
	var s := Soup.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for p in points:
		var r := rng.randf_range(0.5, 0.8)
		var pad := [[0.0, 0.0, PAD], [r, 0.0, PAD], [r, -0.03, PAD.darkened(0.3)]]
		lathe_into(s, Transform3D(Basis.IDENTITY, p), pad, 8, rng.randi(), 0.05)
		if rng.randf() < 0.4:
			var f := [[0.0, 0.0, Color(1.0, 0.7, 0.8)], [0.18, 0.05, Color(1.0, 0.7, 0.8)], [0.0, 0.2, Color(1.0, 0.85, 0.9)]]
			lathe_into(s, Transform3D(Basis.IDENTITY, p + Vector3(0.0, 0.02, 0.0)), f, 5, rng.randi())
	return s.build()


## A ring of radial deck planks around the trunk (its top is 0.03 m above the origin plane).
static func deck_ring(inner: float, outer: float, count: int) -> ArrayMesh:
	var s := Soup.new()
	var length := outer - inner
	for i in count:
		var a := TAU * float(i) / float(count)
		var radial := Vector3(cos(a), 0.0, sin(a))
		var side := Vector3(-sin(a), 0.0, cos(a))
		var width := TAU * (inner + outer) * 0.5 / float(count) * 0.9
		s.box(radial * (inner + length * 0.5) + Vector3(0.0, -0.01, 0.0), radial, Vector3.UP, side, Vector3(length, 0.08, width), WOOD_A if i % 2 == 0 else WOOD_B)
	return s.build()
```

- [ ] **Step 4: Import and run the test**

Run: `godot --path . --headless --import 2>&1 | grep -i "error\|parse" | head -5` (creates `scripts/tree_meshes.gd.uid`; expect no output), then
`timeout 100 godot --path . --headless --script tools/tree_meshes_test.gd > /tmp/t.txt 2>&1; echo exit=$?; grep -c "^PASS" /tmp/t.txt; grep "^FAIL\|SCRIPT ERROR" /tmp/t.txt`
Expected: exit 0, every line `PASS`.

Likely adjustments if something fails: `great_tree` height outside 29 to 36 (change blob y values or radii), `ramp` triangle count (change the segment count only in the test via a larger `ramp_line` step count), a winding failure (means a `Soup.tri` inside point is wrong: the lathe uses the axis point at the mean profile height, which is inside for every profile used here; for a new shape pick a profile whose mean height lies inside the solid).

- [ ] **Step 5: Commit**

```bash
git add scripts/tree_meshes.gd scripts/tree_meshes.gd.uid tools/tree_meshes_test.gd tools/tree_meshes_test.gd.uid
git commit -m "Add the procedural geometry library for the Great Tree area"
```

---

### Task 2: The lake, the islands, the bridges and the causeway, wired into the village

**Files:**
- Create: `scripts/great_tree.gd`, `tools/great_tree_walk_test.gd`
- Modify: `scripts/village.gd`

**Interfaces:**
- Consumes: `TreeMeshes` (Task 1).
- Produces: the `GreatTree` node (`Village/GreatTree`, at world `(172, 0, -40)`), child nodes `Lake`, `Island_<key>` (+ `Island_<key>Body`), `Bridge_<n>` (+ `Bridge_<n>Body`), `Ramp` (+ `RampBody`), `Pillar_<i>`; the static helpers `to_world`, `island_point`, `plateau_point`, `ramp_points`, `bridge_list` (7 pairs `[a, b]` in this order: 0 shore to entry island, 1 entry island to ramp foot, 2 ramp top to plateau, 3 south island to plateau, 4 east island to plateau, 5 entry to south island, 6 east to far island), `walk_main`, `walk_south`, `walk_far` (waypoint lists in local coordinates); two comment markers (`# >>> the later tasks add their builders here` in `_ready` and `# >>> more builders are added below this line` at the end of the file) that later tasks replace.

- [ ] **Step 1: Write the failing walk test**

Create `tools/great_tree_walk_test.gd`:

```gdscript
extends SceneTree
## Everything walkable in the Great Tree area can be walked: islands, bridges, the causeway, rails and cliffs:
##   godot --path . --headless --script tools/great_tree_walk_test.gd
var failed := false
var gt            # the GreatTree script, loaded at run time


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func world(p: Vector3) -> Vector3:
	return gt.to_world(p)


func ray_down(wx: float, wz: float) -> Dictionary:
	var space := root.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(wx, 60.0, wz), Vector3(wx, -5.0, wz), 1)
	return space.intersect_ray(q)


func make_walker() -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.collision_layer = 0
	body.collision_mask = 1
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	shape.shape = cap
	shape.position.y = 0.9
	body.add_child(shape)
	root.add_child(body)
	return body


## Walks a capsule like George (6 m/s, gravity) through `points` (local coordinates). Returns
## {"arrived", "min_y", "pos"}.
func walk(points: Array) -> Dictionary:
	var body := make_walker()
	body.global_position = world(points[0]) + Vector3(0.0, 0.2, 0.0)
	var idx := 1
	var frames := 0
	var min_y := 999.0
	var dt := 1.0 / 60.0
	while idx < points.size() and frames < 3600:
		await physics_frame
		frames += 1
		var to: Vector3 = world(points[idx]) - body.global_position
		to.y = 0.0
		if to.length() < 0.8:
			idx += 1
			continue
		var v := to.normalized() * 6.0
		v.y = body.velocity.y - 22.0 * dt
		body.velocity = v
		body.move_and_slide()
		min_y = minf(min_y, body.global_position.y)
	var result := {"arrived": idx >= points.size(), "min_y": min_y, "pos": body.global_position}
	body.queue_free()
	return result


## Pushes a capsule from `start` (local) in `direction` (horizontal, unit) for `frames` frames.
func push(start: Vector3, direction: Vector3, frames: int) -> Vector3:
	var body := make_walker()
	body.global_position = world(start) + Vector3(0.0, 0.2, 0.0)
	var dt := 1.0 / 60.0
	for i in frames:
		await physics_frame
		var v := direction * 5.0
		v.y = body.velocity.y - 22.0 * dt
		body.velocity = v
		body.move_and_slide()
	var end := body.global_position
	body.queue_free()
	return end


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	gt = load("res://scripts/great_tree.gd")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var area := main.get_node_or_null("Village/GreatTree")
	check("the GreatTree node is in the village at (172, -40)", area != null and area.global_position.is_equal_approx(Vector3(172.0, 0.0, -40.0)))
	if area == null:
		quit(1)
		return
	var lake := area.get_node_or_null("Lake") as MeshInstance3D
	check("a lake with its surface at y 0.10", lake != null and absf(lake.global_position.y - 0.10) < 0.001)

	# --- islands: a collider at the top height in the middle of each
	for key in gt.ISLANDS:
		var d: Dictionary = gt.ISLANDS[key]
		var ip: Vector2 = d["pos"] + Vector2(0.0, 0.45 * float(d["r"]))      # off the centre: the trunk and the umbrella trees stand there
		var hit := ray_down(172.0 + ip.x, -40.0 + ip.y)
		var ok := not hit.is_empty() and absf((hit["position"] as Vector3).y - float(d["top"])) < 0.05 and str((hit["collider"] as Node).name).begins_with("Island_")
		check("island %s has its collider at y %.1f (probe point south of the centre)" % [key, float(d["top"])], ok)
	var shore_hit := ray_down(172.0 + gt.SHORE_START.x - 6.0, -40.0 + gt.SHORE_START.z)
	check("dry ground west of the lake is at y 0", not shore_hit.is_empty() and absf((shore_hit["position"] as Vector3).y) < 0.01)

	# --- slopes and bridge ends
	var bl: Array = gt.bridge_list()
	check("seven bridges", bl.size() == 7)
	var worst := 0.0
	var ends_ok := true
	for pair in bl:
		var line := TreeMeshes.bridge_line(pair[0], pair[1], TreeMeshes.bridge_steps(pair[0], pair[1]))
		worst = maxf(worst, TreeMeshes.max_slope(line))
		for e in [pair[0], pair[1]]:
			var h := ray_down(172.0 + (e as Vector3).x, -40.0 + (e as Vector3).z)
			if h.is_empty() or absf((h["position"] as Vector3).y - (e as Vector3).y) > 0.15:
				ends_ok = false
	check("every bridge is gentle enough (steepest %.3f)" % worst, worst < 0.27)
	check("both ends of every bridge rest on solid ground at their height", ends_ok)
	var rline: Array[Vector3] = gt.ramp_points()
	check("the causeway is gentle (%.3f) and climbs from 2.4 to 7.0" % TreeMeshes.max_slope(rline), TreeMeshes.max_slope(rline) < 0.15 and is_equal_approx(rline[0].y, 2.4) and is_equal_approx(rline[rline.size() - 1].y, 7.0))

	# --- walking the routes
	var r1 = await walk(gt.walk_main())
	check("route 1: shore bridge, entry island, causeway, plateau (end %s, lowest y %.2f)" % [str(r1["pos"]), r1["min_y"]], r1["arrived"] and r1["min_y"] > -0.3)
	var r2 = await walk(gt.walk_south())
	check("route 2: shore, entry island, south island, bridge to the plateau (lowest y %.2f)" % r2["min_y"], r2["arrived"] and r2["min_y"] > -0.3)
	var r3 = await walk(gt.walk_far())
	check("route 3: ... plateau, east island, far island (lowest y %.2f)" % r3["min_y"], r3["arrived"] and r3["min_y"] > -0.3)

	# --- rails keep George on a bridge
	var a: Vector3 = bl[1][0]
	var b: Vector3 = bl[1][1]
	var mid := (a + b) * 0.5
	var side := (b - a).normalized().cross(Vector3.UP).normalized()
	var end_pos: Vector3 = await push(mid + Vector3(0.0, 0.0, 0.0), side, 120)
	var drift := Vector2(end_pos.x - world(mid).x, end_pos.z - world(mid).z).length()
	check("pushing sideways on a bridge stops at the rail (moved %.2f m, y %.2f)" % [drift, end_pos.y], drift < 1.7 and end_pos.y > mid.y - 0.5)

	# --- cliffs: from the lake bed the central island cannot be climbed
	var cliff_end: Vector3 = await push(Vector3(4.0, 0.0, -24.0), Vector3(0.0, 0.0, 1.0), 240)
	var to_centre := Vector2(cliff_end.x - world(Vector3(4.0, 0.0, 0.0)).x, cliff_end.z - world(Vector3(4.0, 0.0, 0.0)).z).length()
	check("the cliff of the central island stops a walker from the lake (%.1f m from the centre, y %.2f)" % [to_centre, cliff_end.y], to_centre > 10.0 and cliff_end.y < 1.5)
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it and watch it fail**

Run: `timeout 150 godot --path . --headless --script tools/great_tree_walk_test.gd > /tmp/t.txt 2>&1; echo exit=$?; grep "^PASS\|^FAIL\|SCRIPT ERROR" /tmp/t.txt | head -3`
Expected: a script error (`great_tree.gd` cannot be loaded), exit 1 or 124.

- [ ] **Step 3: Create the GreatTree node**

Create `scripts/great_tree.gd`:

```gdscript
class_name GreatTree
extends Node3D
## The Great Tree area in the east of the map: a turquoise lake with a central rock island carrying a giant
## tree, four smaller islands, rope bridges and a stone causeway (all walkable, collision layer 1), umbrella
## trees, a chest, balloons. Added by Village._build_great_tree(). The geometry comes from tree_meshes.gd;
## this node holds the layout and places everything. All coordinates below are LOCAL to CENTER.

const CENTER := Vector2(172.0, -40.0)         # world x, z
const LAKE := Vector2(36.0, 30.0)             # radii of the oval lake (x, z)
const AREA_RADIUS := 44.0                     # nothing is scattered inside this circle (Village._occupy)
const WATER_Y := 0.10
const SHORE_Y := 0.03                         # height of the shore end of the first bridge
const WORLD := "res://assets/world/"

# name -> {pos (x, z), r (radius), top (walkable height), seed}
const ISLANDS := {
	"central": {"pos": Vector2(4.0, 0.0), "r": 11.0, "top": 7.0, "seed": 11},
	"entry": {"pos": Vector2(-24.0, 3.0), "r": 5.0, "top": 2.4, "seed": 12},
	"south": {"pos": Vector2(-10.0, 21.0), "r": 5.0, "top": 5.0, "seed": 13},
	"east": {"pos": Vector2(22.0, 16.0), "r": 5.5, "top": 5.2, "seed": 14},
	"far": {"pos": Vector2(28.0, -4.0), "r": 5.0, "top": 3.4, "seed": 15},
}
## The stone causeway around the central island: an arc from `a0` to `a1` degrees (0 = +x, 90 = +z).
const RAMP := {"center": Vector2(4.0, 0.0), "radius": 16.5, "a0": 180.0, "a1": 330.0, "y0": 2.4, "y1": 7.0, "width": 2.6, "steps": 44}
const SHORE_START := Vector3(-41.0, SHORE_Y, 2.5)

var terrain: Terrain                          # set by Village before add_child (sand ring, flowers)
var _bridge_count := 0


func _ready() -> void:
	name = "GreatTree"
	position = Vector3(CENTER.x, 0.0, CENTER.y)
	_build_lake()
	for key in ISLANDS:
		_build_island(key)
	for pair in bridge_list():
		_build_bridge(pair[0], pair[1])
	_build_ramp()
	# >>> the later tasks add their builders here


# ------------------------------------------------------------------- layout ----

## Local (x, y, z) to world.
static func to_world(local: Vector3) -> Vector3:
	return Vector3(CENTER.x + local.x, local.y, CENTER.y + local.z)


## A point on the walkable top of `island`, `inset` of the way from its centre toward `toward` (local x, z).
static func island_point(island: String, toward: Vector2, inset := 0.78) -> Vector3:
	var d: Dictionary = ISLANDS[island]
	var c: Vector2 = d["pos"]
	var p := c + (toward - c).normalized() * float(d["r"]) * inset
	return Vector3(p.x, float(d["top"]), p.y)


## A point on the central plateau at `radius` from its centre, toward `toward` (local x, z).
static func plateau_point(toward: Vector2, radius: float) -> Vector3:
	var d: Dictionary = ISLANDS["central"]
	var c: Vector2 = d["pos"]
	var p := c + (toward - c).normalized() * radius
	return Vector3(p.x, float(d["top"]), p.y)


static func ramp_points() -> Array[Vector3]:
	return TreeMeshes.ramp_line(RAMP["center"], float(RAMP["radius"]), float(RAMP["a0"]), float(RAMP["a1"]),
			float(RAMP["y0"]), float(RAMP["y1"]), int(RAMP["steps"]))


## The seven bridges as [from, to] in local coordinates: 0 shore to entry island, 1 entry island to the foot of
## the causeway, 2 top of the causeway to the plateau, 3 south island to the plateau, 4 east island to the
## plateau, 5 entry to south island, 6 east to far island.
static func bridge_list() -> Array:
	var ramp := ramp_points()
	var foot: Vector3 = ramp[0]
	var top: Vector3 = ramp[ramp.size() - 1]
	var entry_pos: Vector2 = ISLANDS["entry"]["pos"]
	var south_pos: Vector2 = ISLANDS["south"]["pos"]
	var east_pos: Vector2 = ISLANDS["east"]["pos"]
	var far_pos: Vector2 = ISLANDS["far"]["pos"]
	var stub_end := plateau_point(Vector2(top.x, top.z), 8.4)
	var south_landing := plateau_point(south_pos, 8.4)
	var east_landing := plateau_point(east_pos, 8.4)
	return [
		[SHORE_START, island_point("entry", Vector2(SHORE_START.x, SHORE_START.z))],
		[island_point("entry", Vector2(foot.x, foot.z)), foot],
		[top, stub_end],
		[island_point("south", Vector2(south_landing.x, south_landing.z)), south_landing],
		[island_point("east", Vector2(east_landing.x, east_landing.z)), east_landing],
		[island_point("entry", south_pos), island_point("south", entry_pos)],
		[island_point("east", far_pos), island_point("far", east_pos)],
	]


## Waypoints (local) of a walk from dry ground west of the lake to the plateau by the causeway.
static func walk_main() -> Array[Vector3]:
	var bl := bridge_list()
	var ramp := ramp_points()
	var out: Array[Vector3] = [Vector3(SHORE_START.x - 5.0, 0.0, SHORE_START.z)]
	out.append(bl[0][0])
	out.append(bl[0][1])
	out.append(bl[1][0])
	out.append(bl[1][1])
	for i in range(4, ramp.size(), 4):
		out.append(ramp[i])
	out.append(ramp[ramp.size() - 1])
	out.append(bl[2][0])
	out.append(bl[2][1])
	out.append(Vector3(8.0, 7.0, 4.0))
	return out


## ... to the plateau by the south island.
static func walk_south() -> Array[Vector3]:
	var bl := bridge_list()
	var out: Array[Vector3] = [Vector3(SHORE_START.x - 5.0, 0.0, SHORE_START.z)]
	out.append(bl[0][0])
	out.append(bl[0][1])
	out.append(bl[5][0])
	out.append(bl[5][1])
	out.append(bl[3][0])
	out.append(bl[3][1])
	out.append(Vector3(8.0, 7.0, 4.0))
	return out


## ... and on over the east island to the far island.
static func walk_far() -> Array[Vector3]:
	var bl := bridge_list()
	var out := walk_south()
	out.append(bl[4][1])
	out.append(bl[4][0])
	out.append(bl[6][0])
	out.append(bl[6][1])
	out.append(Vector3(ISLANDS["far"]["pos"].x, float(ISLANDS["far"]["top"]), ISLANDS["far"]["pos"].y))
	return out


# ----------------------------------------------------------------- builders ----

func _add_visual(mesh: Mesh, label: String, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	mi.mesh = mesh
	mi.material_override = TreeMeshes.material()
	mi.position = pos
	add_child(mi)
	return mi


## A static trimesh collider (layer 1) made from `mesh`.
func _add_collider(mesh: Mesh, label: String, pos := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label + "Body"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var shape := CollisionShape3D.new()
	var concave := mesh.create_trimesh_shape()
	concave.backface_collision = true
	shape.shape = concave
	body.add_child(shape)
	add_child(body)
	return body


func _build_lake() -> void:
	var water := MeshInstance3D.new()
	water.name = "Lake"
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 0.05
	cm.radial_segments = 64
	water.mesh = cm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/water.gdshader") as Shader
	mat.set_shader_parameter("deep_color", Color(0.05, 0.45, 0.55))
	mat.set_shader_parameter("shallow_color", Color(0.20, 0.80, 0.75))
	water.material_override = mat
	water.position = Vector3(0.0, WATER_Y, 0.0)
	water.scale = Vector3(LAKE.x, 1.0, LAKE.y)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)
	if terrain != null:
		terrain.add_patch(CENTER, 40.0, Color(0.74, 0.66, 0.45), false, Color(0.55, 0.48, 0.32))


func _build_island(key: String) -> void:
	var d: Dictionary = ISLANDS[key]
	var pos: Vector2 = d["pos"]
	var mesh := TreeMeshes.island(float(d["r"]), float(d["top"]), int(d["seed"]))
	var at := Vector3(pos.x, 0.0, pos.y)
	_add_visual(mesh, "Island_" + key, at)
	_add_collider(mesh, "Island_" + key, at)


func _build_bridge(a: Vector3, b: Vector3) -> void:
	var label := "Bridge_%d" % _bridge_count
	_bridge_count += 1
	_add_visual(TreeMeshes.bridge(a, b), label)
	_add_collider(TreeMeshes.bridge_collision(a, b), label)


## The stone causeway with its pillars.
func _build_ramp() -> void:
	var line := ramp_points()
	var width := float(RAMP["width"])
	_add_visual(TreeMeshes.ramp(line, width), "Ramp")
	_add_collider(TreeMeshes.ramp_collision(line, width), "Ramp")
	for i in range(6, line.size() - 2, 8):
		var p: Vector3 = line[i]
		var top_y := p.y - 0.4
		_add_visual(TreeMeshes.pillar(top_y, 100 + i), "Pillar_%d" % i, Vector3(p.x, 0.0, p.z))
		var body := StaticBody3D.new()
		body.name = "Pillar_%dBody" % i
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.9
		cyl.height = top_y + 1.6
		shape.shape = cyl
		body.position = Vector3(p.x, (top_y - 1.6) * 0.5, p.z)
		body.add_child(shape)
		add_child(body)


# >>> more builders are added below this line
```

- [ ] **Step 4: Hook it into the village**

In `scripts/village.gd` Edit (`_ready`; the new call goes before the terrain details so its scatter blocking is registered first):

old_string:
```
	_build_totems()
	_build_terrain_details()
```
new_string:
```
	_build_totems()
	_build_great_tree()
	_build_terrain_details()
```
and the function, old_string (single line):
```
func _signpost(text: String, pos: Vector3, rot_deg: float, parent: Node) -> void:
```
new_string:
```
## The Great Tree area in the east: a lake with rock islands, bridges and a giant tree (great_tree.gd).
func _build_great_tree() -> void:
	var area := GreatTree.new()
	area.terrain = _terrain
	add_child(area)
	_occupy(GreatTree.CENTER.x, GreatTree.CENTER.y, GreatTree.AREA_RADIUS)


func _signpost(text: String, pos: Vector3, rot_deg: float, parent: Node) -> void:
```

- [ ] **Step 5: Import and run the test**

Run: `godot --path . --headless --import 2>&1 | grep -i "error\|parse" | head -5` (creates `scripts/great_tree.gd.uid`; expect no output), then
`timeout 300 godot --path . --headless --script tools/great_tree_walk_test.gd > /tmp/t.txt 2>&1; echo exit=$?; grep -c "^PASS" /tmp/t.txt; grep "^FAIL\|SCRIPT ERROR" /tmp/t.txt`
Expected: exit 0, all `PASS` (the walks take about 40 s of real time).

If a route does not arrive, the result line prints where the walker stopped (`end`): that is the snag. Typical fixes: a bridge end that is not flush with its island (check `island_point` inset and the island flat radius: the flat top reaches 0.81 of the radius at the narrowest rim), a ramp or bridge slope that is too steep for the capsule (lower the rise by changing an island `top`), a pillar collider in the way (move it by changing the `range(6, ...)` offset), the ramp parapet blocking the stub (the stub starts at the last ramp point). If "cliff" fails, print `cliff_end`.

Regression: `timeout 150 godot --path . --headless --script tools/fish_data_test.gd 2>&1 | grep -c "^FAIL"` prints 0, and `timeout 150 godot --path . --headless --script tools/frontier_enter_test.gd 2>&1 | grep -c "^FAIL"` prints 0.

- [ ] **Step 6: Commit**

```bash
godot --path . --headless --import > /dev/null 2>&1
git add scripts/great_tree.gd scripts/great_tree.gd.uid scripts/village.gd tools/great_tree_walk_test.gd tools/great_tree_walk_test.gd.uid
git commit -m "Add the lake, islands, bridges and stone causeway of the Great Tree area"
```

---

### Task 3: The great tree, the houses, the deck, lanterns, umbrella trees, chest, bench and dressing

**Files:**
- Create: `tools/great_tree_props_test.gd`
- Modify: `scripts/great_tree.gd`

**Interfaces:**
- Consumes: Tasks 1 and 2; the classes `Chest` (`golden`, `gold_min`, `gold_max`, `potions`) and `Terrain` (`add_flower_ring`).
- Produces: nodes `Tree`, `TreeTrunk`, `House_0`, `House_1`, `DeckRing`, `LanternPosts`, `LanternHeads`, `Umbrella_<i>` (6), `Bench`, `Flowers_<island>`, `LilyPads`, `Dressing` (rocks and trees), three `OmniLight3D` in group `night_lights`, a `Chest` at `CHEST_POS`; constants `TREE_POS`, `TREE_FOOT`, `CHEST_POS`.

- [ ] **Step 1: Write the failing props test**

Create `tools/great_tree_props_test.gd`:

```gdscript
extends SceneTree
## The tree, houses, props, lights and the chest of the Great Tree area:
##   godot --path . --headless --script tools/great_tree_props_test.gd
var failed := false
var gt


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	gt = load("res://scripts/great_tree.gd")
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var area := main.get_node_or_null("Village/GreatTree")
	if area == null:
		check("the GreatTree node exists", false)
		quit(1)
		return

	# --- the tree
	var tree := area.get_node_or_null("Tree") as MeshInstance3D
	check("the great tree stands on the plateau (%s)" % (str(tree.position) if tree != null else "missing"), tree != null and tree.position.is_equal_approx(gt.TREE_POS))
	check("its trunk has a collider", area.get_node_or_null("TreeTrunk") != null)
	# a capsule walking at the trunk stops before it
	var body := CharacterBody3D.new()
	body.collision_layer = 0
	body.collision_mask = 1
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	shape.shape = cap
	shape.position.y = 0.9
	body.add_child(shape)
	root.add_child(body)
	var trunk_world: Vector3 = gt.to_world(gt.TREE_POS)
	body.global_position = trunk_world + Vector3(7.0, 0.3, 0.0)
	for i in 150:
		await physics_frame
		var dir := Vector3(trunk_world.x - body.global_position.x, 0.0, trunk_world.z - body.global_position.z).normalized()
		body.velocity = Vector3(dir.x * 5.0, body.velocity.y - 22.0 / 60.0, dir.z * 5.0)
		body.move_and_slide()
	var dist := Vector2(body.global_position.x - trunk_world.x, body.global_position.z - trunk_world.z).length()
	check("a walker is stopped by the trunk (%.1f m from its axis, y %.1f)" % [dist, body.global_position.y], dist > 3.0 and dist < 5.0 and body.global_position.y > 6.5)
	body.queue_free()

	# --- houses, deck, lanterns
	for i in 2:
		var house := area.get_node_or_null("House_%d" % i) as Node3D
		check("house %d stands on the plateau and has a collider" % i, house != null and absf(house.position.y - 7.0) < 0.05 and house.find_children("*", "StaticBody3D", true, false).size() > 0)
	check("the deck ring around the trunk", area.get_node_or_null("DeckRing") != null)
	check("lantern posts and glowing heads", area.get_node_or_null("LanternPosts") != null and area.get_node_or_null("LanternHeads") != null)
	var heads := area.get_node("LanternHeads") as MeshInstance3D
	var mat := heads.material_override as StandardMaterial3D
	check("the lantern heads glow (emissive material)", mat != null and mat.emission_enabled)

	# --- lights: at most three real lights in the whole area
	var lights := 0
	for l in get_nodes_in_group("night_lights"):
		var p := (l as Node3D).global_position
		if Vector2(p.x - 172.0, p.z + 40.0).length() < 44.0:
			lights += 1
	check("exactly three night lights in the area (found %d)" % lights, lights == 3)

	# --- umbrella trees, bench, flowers, pads, dressing
	var umbrellas := 0
	for c in area.get_children():
		if str(c.name).begins_with("Umbrella_") and c is MeshInstance3D:
			umbrellas += 1
	check("six umbrella trees (%d)" % umbrellas, umbrellas == 6)
	check("a bench", area.get_node_or_null("Bench") != null)
	var flowers := 0
	for c in area.get_children():
		if str(c.name).begins_with("Flowers_"):
			flowers += 1
	check("flowers on every island (%d)" % flowers, flowers == 5)
	check("lily pads on the lake", area.get_node_or_null("LilyPads") != null)
	var dressing := area.get_node_or_null("Dressing")
	check("rocks and trees around the shore (%d)" % (dressing.get_child_count() if dressing != null else 0), dressing != null and dressing.get_child_count() >= 14)

	# --- the chest on the south island
	var found: Node3D = null
	for c in get_nodes_in_group("chests"):
		var p := (c as Node3D).global_position
		if p.y > 4.5 and Vector2(p.x - 172.0, p.z + 40.0).length() < 44.0:
			found = c
	check("a chest on the south island at its height", found != null and absf(found.global_position.y - 5.0) < 0.05)
	if found != null:
		check("it is golden, closed and can be opened with R", found.golden and not found.opened and found.interact_prompt() != "")

	# --- the budget: draw calls and triangles stay small
	var meshes := area.find_children("*", "MeshInstance3D", true, false)
	var tris := 0
	for m in meshes:
		tris += ((m as MeshInstance3D).mesh.get_faces().size() / 3)
	check("%d meshes (under 90) and %d triangles (under 90000)" % [meshes.size(), tris], meshes.size() < 90 and tris < 90000)
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it and watch it fail**

Run: `timeout 150 godot --path . --headless --script tools/great_tree_props_test.gd > /tmp/t.txt 2>&1; echo exit=$?; grep "^PASS\|^FAIL\|SCRIPT ERROR" /tmp/t.txt | head -4`
Expected: `FAIL  the great tree stands on the plateau` and script errors on the missing nodes (exit 1 or 124).

- [ ] **Step 3: Call the new builders**

In `scripts/great_tree.gd` Edit:

old_string:
```
	# >>> the later tasks add their builders here
```
new_string:
```
	_build_props()
	# >>> the later tasks add their builders here
```

- [ ] **Step 4: The builders**

In `scripts/great_tree.gd` Edit (the marker at the end of the file):

old_string:
```
# >>> more builders are added below this line
```
new_string:
```
# ------------------------------------------------------------ tree and props ----

const TREE_POS := Vector3(4.0, 7.0, -1.0)         # the foot of the great tree on the plateau
const TREE_FOOT := Vector3(9.5, 7.0, 3.0)         # a spot on the plateau a few metres from the trunk
const CHEST_POS := Vector3(-8.2, 5.0, 22.5)       # on the south island
const BENCH_POS := Vector3(23.5, 5.2, 17.6)       # on the east island
const HOUSE_SCALE := 5.0
const HOUSES := [
	["buildings/blue/building_home_A_blue.gltf", Vector3(-3.5, 7.0, -4.5)],
	["buildings/yellow/building_home_B_yellow.gltf", Vector3(4.5, 7.0, -9.0)],
]
# [island, offset on the island (x, z), trunk height, canopy radius]
const UMBRELLAS := [
	["south", Vector2(-1.5, 0.8), 5.5, 3.6], ["south", Vector2(1.8, -1.6), 4.2, 2.8],
	["east", Vector2(-1.4, -0.6), 5.0, 3.3],
	["far", Vector2(0.8, 1.2), 5.8, 3.9], ["far", Vector2(-1.8, -0.8), 4.0, 2.6],
	["entry", Vector2(-1.2, -1.4), 3.6, 2.4],
]
const ROCK_SCALE := 3.2
const TREE_SCALE := 9.5
const ROCKS := [
	"decoration/nature/rock_single_A.gltf", "decoration/nature/rock_single_B.gltf", "decoration/nature/rock_single_C.gltf",
	"decoration/nature/rock_single_D.gltf", "decoration/nature/rock_single_E.gltf",
]
const SHORE_TREES := ["decoration/nature/tree_single_A.gltf", "decoration/nature/tree_single_B.gltf"]


func _build_props() -> void:
	_build_tree()
	_build_houses()
	_build_deck_and_lanterns()
	_build_umbrella_trees()
	_build_chest_and_bench()
	_build_flowers_and_pads()
	_build_shore()


func _build_tree() -> void:
	_add_visual(TreeMeshes.great_tree(21), "Tree", TREE_POS)
	var body := StaticBody3D.new()
	body.name = "TreeTrunk"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = TREE_POS
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 3.4
	cyl.height = 14.0
	shape.shape = cyl
	shape.position = Vector3(0.0, 7.0, 0.0)
	body.add_child(shape)
	add_child(body)


## One box collider around a model (its meshes, in the local space of `node`).
func _box_collider_for(node: Node3D, shrink := 0.9) -> void:
	var inv := node.global_transform.affine_inverse()
	var have := false
	var box := AABB()
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = (inv * (mi as MeshInstance3D).global_transform) * (mi as MeshInstance3D).get_aabb()
		box = a if not have else box.merge(a)
		have = true
	if not have:
		return
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(box.size.x * shrink, maxf(box.size.y, 0.5), box.size.z * shrink)
	shape.shape = bs
	shape.position = box.get_center()
	body.add_child(shape)
	node.add_child(body)


## A KayKit model placed at `pos` (local) with a box collider.
func _place_model(path: String, pos: Vector3, rot_deg: float, model_scale: float, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = path.get_file().get_basename()
	root.position = pos
	root.rotation_degrees.y = rot_deg
	var model := (load(WORLD + path) as PackedScene).instantiate() as Node3D
	model.scale = Vector3.ONE * model_scale
	root.add_child(model)
	parent.add_child(root)
	_box_collider_for(root, 0.8)
	return root


func _build_houses() -> void:
	for i in HOUSES.size():
		var h: Array = HOUSES[i]
		var pos: Vector3 = h[1]
		var d: Vector3 = TREE_POS - pos
		var house := _place_model(h[0], pos, rad_to_deg(atan2(d.x, d.z)), HOUSE_SCALE, self)
		house.name = "House_%d" % i
		var light := OmniLight3D.new()
		light.name = "HouseLight_%d" % i
		light.light_color = Color(1.0, 0.72, 0.4)
		light.light_energy = 1.4
		light.omni_range = 12.0
		light.position = pos + Vector3(0.0, 3.5, 0.0) + d.normalized() * 3.5
		light.add_to_group("night_lights")
		add_child(light)


func _build_deck_and_lanterns() -> void:
	_add_visual(TreeMeshes.deck_ring(5.4, 7.6, 28), "DeckRing", TREE_POS + Vector3(0.0, 0.03, 0.0))
	var pts: Array[Vector3] = []
	for a in [20.0, 90.0, 160.0, 240.0, 305.0]:
		var ang := deg_to_rad(a)
		pts.append(Vector3(TREE_POS.x + cos(ang) * 8.4, TREE_POS.y, TREE_POS.z + sin(ang) * 8.4))
	for key in ["entry", "south", "east", "far"]:
		var d: Dictionary = ISLANDS[key]
		var ip: Vector2 = d["pos"]
		pts.append(Vector3(ip.x + 1.6, float(d["top"]), ip.y - 1.6))
	_add_visual(TreeMeshes.lanterns_posts(pts), "LanternPosts")
	var heads := _add_visual(TreeMeshes.lanterns_heads(pts), "LanternHeads")
	var glow := StandardMaterial3D.new()
	glow.vertex_color_use_as_albedo = true
	glow.vertex_color_is_srgb = true
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.75, 0.35)
	glow.emission_energy_multiplier = 1.2
	heads.material_override = glow
	var deck_light := OmniLight3D.new()                    # the third light: over the deck, lighting the trunk
	deck_light.name = "DeckLight"
	deck_light.light_color = Color(1.0, 0.76, 0.45)
	deck_light.light_energy = 1.4
	deck_light.omni_range = 13.0
	deck_light.position = TREE_POS + Vector3(0.0, 4.5, 0.0)
	deck_light.add_to_group("night_lights")
	add_child(deck_light)


func _build_umbrella_trees() -> void:
	for i in UMBRELLAS.size():
		var u: Array = UMBRELLAS[i]
		var d: Dictionary = ISLANDS[u[0]]
		var ip: Vector2 = d["pos"]
		var off: Vector2 = u[1]
		var pos := Vector3(ip.x + off.x, float(d["top"]), ip.y + off.y)
		_add_visual(TreeMeshes.umbrella_tree(float(u[2]), float(u[3]), 40 + i), "Umbrella_%d" % i, pos)
		var body := StaticBody3D.new()
		body.name = "Umbrella_%dBody" % i
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = pos + Vector3(0.0, float(u[2]) * 0.5, 0.0)
		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.4
		cyl.height = float(u[2])
		shape.shape = cyl
		body.add_child(shape)
		add_child(body)


func _build_chest_and_bench() -> void:
	var chest := Chest.new()
	chest.position = CHEST_POS
	chest.rotation_degrees.y = 200.0
	chest.golden = true
	chest.gold_min = 40
	chest.gold_max = 80
	chest.potions = 2
	add_child(chest)
	_add_visual(TreeMeshes.bench(), "Bench", BENCH_POS)
	var body := StaticBody3D.new()
	body.name = "BenchBody"
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = BENCH_POS + Vector3(0.0, 0.45, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 0.9, 0.6)
	shape.shape = box
	body.add_child(shape)
	add_child(body)


func _build_flowers_and_pads() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for key in ISLANDS:
		var d: Dictionary = ISLANDS[key]
		var ip: Vector2 = d["pos"]
		var r := float(d["r"])
		var pts: Array[Vector3] = []
		for i in (26 if key == "central" else 14):
			var a := rng.randf() * TAU
			var rr := sqrt(rng.randf()) * r * 0.7
			pts.append(Vector3(ip.x + cos(a) * rr, float(d["top"]), ip.y + sin(a) * rr))
		_add_visual(TreeMeshes.flowers(pts, int(d["seed"]) + 100), "Flowers_" + key)
	var pads: Array[Vector3] = []
	for i in 40:
		if pads.size() >= 16:
			break
		var a := rng.randf() * TAU
		var rr := sqrt(rng.randf()) * 0.88
		var p := Vector3(cos(a) * LAKE.x * rr, WATER_Y + 0.03, sin(a) * LAKE.y * rr)
		var on_island := false
		for key in ISLANDS:
			var d: Dictionary = ISLANDS[key]
			var ip: Vector2 = d["pos"]
			if Vector2(p.x - ip.x, p.z - ip.y).length() < float(d["r"]) * 1.2 + 1.5:
				on_island = true
		if not on_island:
			pads.append(p)
	_add_visual(TreeMeshes.lily_pads(pads, 5), "LilyPads")


## Rocks and a few trees around the shore (the side toward the village stays open) and flowers on the ground.
func _build_shore() -> void:
	var holder := Node3D.new()
	holder.name = "Dressing"
	add_child(holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in 12:
		var a := TAU * float(i) / 12.0 + rng.randf_range(-0.15, 0.15)
		if absf(angle_difference(a, PI)) < 0.45:
			continue
		var f := rng.randf_range(1.08, 1.2)
		_place_model(ROCKS[rng.randi() % ROCKS.size()], Vector3(cos(a) * LAKE.x * f, 0.0, sin(a) * LAKE.y * f),
				rng.randf() * 360.0, ROCK_SCALE * rng.randf_range(0.7, 1.2), holder)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0 + rng.randf_range(-0.1, 0.1)
		if absf(angle_difference(a, PI)) < 0.5:
			continue
		var f := rng.randf_range(1.22, 1.32)
		_place_model(SHORE_TREES[rng.randi() % SHORE_TREES.size()], Vector3(cos(a) * LAKE.x * f, 0.0, sin(a) * LAKE.y * f),
				rng.randf() * 360.0, TREE_SCALE * rng.randf_range(0.8, 1.1), holder)
	if terrain != null:
		terrain.add_flower_ring(CENTER, 38.0, 43.0, 70)


# >>> more builders are added below this line
```

- [ ] **Step 5: Import and run the tests**

Run: `godot --path . --headless --import 2>&1 | grep -i "error\|parse" | head -5`, then
`timeout 200 godot --path . --headless --script tools/great_tree_props_test.gd > /tmp/t.txt 2>&1; echo exit=$?; grep -c "^PASS" /tmp/t.txt; grep "^FAIL\|SCRIPT ERROR" /tmp/t.txt`
Expected: exit 0, all `PASS`.

Possible fixes: the walker at the trunk may stop at a different distance (the collider radius 3.4 plus the capsule 0.45 gives about 3.9; the assertion allows 3.0 to 5.0); a house collider blocking a landing (move the house in `HOUSES`); the house orientation and size are judged in Task 6 from screenshots (`HOUSE_SCALE`, the `rad_to_deg(atan2(...))` yaw: add 180 degrees there if the doors face away from the tree).

Regression: `timeout 300 godot --path . --headless --script tools/great_tree_walk_test.gd 2>&1 | grep -c "^FAIL"` prints 0 (the new props must not block a route), and `timeout 150 godot --path . --headless --script tools/tree_meshes_test.gd 2>&1 | grep -c "^FAIL"` prints 0.

- [ ] **Step 6: Commit**

```bash
godot --path . --headless --import > /dev/null 2>&1
git add scripts/great_tree.gd tools/great_tree_props_test.gd tools/great_tree_props_test.gd.uid
git commit -m "Add the great tree, the houses, the props and the chest to the lake area"
```

---

### Task 4: The balloons

**Files:**
- Create: `scripts/balloon.gd`, `tools/balloon_test.gd`
- Modify: `scripts/great_tree.gd`

**Interfaces:**
- Consumes: `TreeMeshes.balloon` and `TreeMeshes.material()`.
- Produces: `Balloon` (`class_name`, `extends Node3D`, group `balloons`; fields `center`, `radii`, `angle`, `angular_speed`, `moored`; `setup(stripes, seed_value)`), five balloon nodes under `GreatTree` (`Balloon_0` to `Balloon_3` drifting, `Balloon_moored`).

- [ ] **Step 1: Write the failing test**

Create `tools/balloon_test.gd`:

```gdscript
extends SceneTree
## Four balloons drift over the lake, one is moored on the entry island:
##   godot --path . --headless --script tools/balloon_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var balloons := get_nodes_in_group("balloons")
	check("five balloons (%d)" % balloons.size(), balloons.size() == 5)
	var drifting: Array = []
	var moored: Node3D = null
	for b in balloons:
		if b.moored:
			moored = b
		else:
			drifting.append(b)
	check("four drifting and one moored", drifting.size() == 4 and moored != null)
	if moored == null or drifting.size() != 4:
		quit(1)
		return
	var before := {}
	for b in drifting:
		before[b] = (b as Node3D).global_position
	var moored_before := moored.global_position
	await create_timer(3.0).timeout
	var moved := true
	var high := true
	var clear_of_tree := true
	for b in drifting:
		var p := (b as Node3D).global_position
		if p.distance_to(before[b]) < 0.5:
			moved = false
		if p.y < 25.0 or p.y > 45.0:
			high = false
		if Vector2(p.x - 176.0, p.z - (-41.0)).length() < 26.0:
			clear_of_tree = false
	check("they drift (every one moved at least 0.5 m in 3 s)", moved)
	check("they float between 25 and 45 m above the lake", high)
	check("and keep clear of the canopy (26 m or more from the tree axis)", clear_of_tree)
	check("the moored balloon stays put on the entry island (y %.1f)" % moored.global_position.y, moored.global_position.distance_to(moored_before) < 0.01 and absf(moored.global_position.y - 2.4) < 0.05)
	var mi := (drifting[0] as Node3D).get_child(0) as MeshInstance3D
	check("a balloon is one mesh with the shared vertex-colour material", mi != null and mi.material_override == TreeMeshes.material())
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it and watch it fail**

Run: `timeout 150 godot --path . --headless --script tools/balloon_test.gd > /tmp/t.txt 2>&1; echo exit=$?; grep "^PASS\|^FAIL\|SCRIPT ERROR" /tmp/t.txt | head -3`
Expected: `FAIL  five balloons (0)`.

- [ ] **Step 3: The Balloon script**

Create `scripts/balloon.gd`:

```gdscript
class_name Balloon
extends Node3D
## A hot-air balloon. Drifting ones glide slowly on an ellipse around `center` (local to the Great Tree
## area) with a gentle bob and turn; a moored one just stands where it is placed. The mesh comes from
## TreeMeshes.balloon (its origin is the bottom of the basket).

var center := Vector3.ZERO              # centre of the ellipse; y = height of the basket bottom
var radii := Vector2(40.0, 34.0)        # ellipse radii (x, z)
var angle := 0.0                        # where on the ellipse (radians)
var angular_speed := 0.024              # radians per second
var moored := false

var _t := 0.0


## Builds the mesh: `stripes` are the colours of the envelope stripes.
func setup(stripes: Array, seed_value: int) -> void:
	add_to_group("balloons")
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = TreeMeshes.balloon(stripes, seed_value)
	mi.material_override = TreeMeshes.material()
	add_child(mi)


func _ready() -> void:
	if not moored:
		_place()


func _process(delta: float) -> void:
	if moored:
		return
	_t += delta
	angle += angular_speed * delta
	_place()


func _place() -> void:
	position = center + Vector3(cos(angle) * radii.x, sin(_t * 0.35 + angle) * 1.4, sin(angle) * radii.y)
	rotation.y = -angle * 0.5 + sin(_t * 0.2) * 0.2
```

- [ ] **Step 4: Place the balloons**

In `scripts/great_tree.gd` Edit:

old_string:
```
	# >>> the later tasks add their builders here
```
new_string:
```
	_build_balloons()
	# >>> the later tasks add their builders here
```
and at the end of the file, old_string:
```
# >>> more builders are added below this line
```
new_string:
```
# ------------------------------------------------------------------ balloons ----

# [stripe colours, ellipse radii (x, z), height, angular speed, start angle, seed]
const BALLOONS := [
	[[Color(1.0, 0.55, 0.18), Color(0.98, 0.90, 0.72)], Vector2(40.0, 34.0), 30.0, 0.024, 0.0, 1],
	[[Color(0.82, 0.24, 0.34), Color(0.98, 0.92, 0.75)], Vector2(46.0, 38.0), 38.0, -0.018, 1.7, 2],
	[[Color(0.26, 0.60, 0.80), Color(0.98, 0.92, 0.75)], Vector2(36.0, 31.0), 42.0, 0.030, 3.3, 3],
	[[Color(0.96, 0.80, 0.22), Color(0.88, 0.34, 0.20)], Vector2(50.0, 40.0), 33.0, -0.022, 4.9, 4],
]


func _build_balloons() -> void:
	for i in BALLOONS.size():
		var b: Array = BALLOONS[i]
		var balloon := Balloon.new()
		balloon.name = "Balloon_%d" % i
		balloon.setup(b[0], int(b[5]))
		balloon.center = Vector3(0.0, float(b[2]), 0.0)
		balloon.radii = b[1]
		balloon.angle = float(b[4])
		balloon.angular_speed = float(b[3])
		add_child(balloon)
	var moored := Balloon.new()
	moored.name = "Balloon_moored"
	moored.moored = true
	moored.setup([Color(0.30, 0.62, 0.85), Color(0.98, 0.92, 0.75)], 9)
	moored.position = Vector3(-24.0, float(ISLANDS["entry"]["top"]), -1.2)
	moored.rotation.y = 0.6
	add_child(moored)


# >>> more builders are added below this line
```

- [ ] **Step 5: Import and run the tests**

Run: `godot --path . --headless --import 2>&1 | grep -i "error\|parse" | head -5` (creates `scripts/balloon.gd.uid`), then
`timeout 150 godot --path . --headless --script tools/balloon_test.gd > /tmp/t.txt 2>&1; echo exit=$?; grep -c "^PASS" /tmp/t.txt; grep "^FAIL\|SCRIPT ERROR" /tmp/t.txt`
Expected: all `PASS`.

Regression: `great_tree_props_test` and `great_tree_walk_test` still print 0 for `grep -c "^FAIL"`; if the props test now counts too many meshes (the budget check), the five balloons add 5 meshes: raise the limit only if the total is still under 100.

- [ ] **Step 6: Commit**

```bash
godot --path . --headless --import > /dev/null 2>&1
git add scripts/balloon.gd scripts/balloon.gd.uid scripts/great_tree.gd tools/balloon_test.gd tools/balloon_test.gd.uid
git commit -m "Add the hot-air balloons of the Great Tree area"
```

---

### Task 5: Integration: the keg and spawns move, the signpost, the map name and the lake sounds

**Files:**
- Create: `tools/great_tree_integration_test.gd`
- Modify: `scripts/village.gd`, `scripts/enemies.gd`, `scripts/minimap.gd`, `scripts/strings_el.gd`, `scripts/sound_manager.gd`

**Interfaces:**
- Consumes: the area from Tasks 2 to 4.
- Produces: the quest barrel at (124, -26), its two spawns at (120, -18) and (130, -34), a signpost "Το Μεγάλο Δέντρο  →" at (112, -44), the place `bigtree` on the big map, two positional loops (`water_loop`, `wind_loop`) at the lake.

- [ ] **Step 1: Write the failing integration test**

Create `tools/great_tree_integration_test.gd`:

```gdscript
extends SceneTree
## The Great Tree area fits the rest of the map: nothing in its way, signpost, map label, sounds, scatter:
##   godot --path . --headless --script tools/great_tree_integration_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	# --- the data moved out of the lake (read from the source: the scripts mention autoloads)
	var village_src := FileAccess.get_file_as_string("res://scripts/village.gd")
	check("the quest barrel moved to (124, -26)", village_src.contains('["keg", 124.0, -26.0]') and not village_src.contains('["keg", 143.0, -29.0]'))
	var enemies_src := FileAccess.get_file_as_string("res://scripts/enemies.gd")
	check("its two skeleton spawns moved with it", enemies_src.contains('["minion", 120.0, -18.0]') and enemies_src.contains('["warrior", 130.0, -34.0]') and not enemies_src.contains('["minion", 138.0, -22.0]'))
	check("the signpost is in the village data", village_src.contains("Το Μεγάλο Δέντρο  →"))
	var mini_src := FileAccess.get_file_as_string("res://scripts/minimap.gd")
	check("the big map names the place", mini_src.contains('["bigtree", 172.0, -40.0]') and Strings.MAP_PLACES.has("bigtree") and Strings.MAP_PLACES["bigtree"] == "Η Λίμνη του Αιωνόβιου")
	var sound_src := FileAccess.get_file_as_string("res://scripts/sound_manager.gd")
	check("two positional loops at the lake", sound_src.contains('"water_loop", Vector3(GreatTree.CENTER.x') and sound_src.contains('"wind_loop", Vector3(GreatTree.CENTER.x'))

	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var village := main.get_node("Village")
	# --- no skeletons in or next to the area
	var close := 0
	for e in get_nodes_in_group("enemies"):
		var p := (e as Node3D).global_position
		if Vector2(p.x - 172.0, p.z + 40.0).length() < 44.0:
			close += 1
	check("no skeleton starts within 44 m of the lake centre (%d)" % close, close == 0)
	# --- nothing scattered inside the area
	var inside := true
	for a in 16:
		var ang := TAU * float(a) / 16.0
		for r in [5.0, 20.0, 38.0, 43.0]:
			if not village._is_occupied(172.0 + cos(ang) * r, -40.0 + sin(ang) * r, 0.5):
				inside = false
	check("the whole area is registered as occupied (no grass, forests or rocks scattered in it)", inside)
	check("but the village side is free again further out", not village._is_occupied(172.0 - 70.0, -40.0, 0.5))
	# --- the signpost exists as a 3D label near (112, -44)
	var sign_found := false
	for l in village.find_children("*", "Label3D", true, false):
		var lab := l as Label3D
		if lab.text.contains("Μεγάλο Δέντρο") and Vector2(lab.global_position.x - 112.0, lab.global_position.z + 44.0).length() < 6.0:
			sign_found = true
	check("the signpost 'Το Μεγάλο Δέντρο' stands near (112, -44)", sign_found)
	# --- the sound manager made the loops
	var sm = get_first_node_in_group("sound_manager")
	var loops := 0
	for n in sm.get_children():
		if n is AudioStreamPlayer3D and Vector2(n.global_position.x - 172.0, n.global_position.z + 40.0).length() < 1.0:
			loops += 1
	check("the sound manager has two loops at the lake (%d)" % loops, loops == 2)
	quit(1 if failed else 0)
```

- [ ] **Step 2: Run it and watch it fail**

Run: `timeout 150 godot --path . --headless --script tools/great_tree_integration_test.gd > /tmp/t.txt 2>&1; echo exit=$?; grep "^PASS\|^FAIL\|SCRIPT ERROR" /tmp/t.txt | head -8`
Expected: the first checks `FAIL` (barrel not moved, no signpost, no place name), maybe a script error on `Strings.MAP_PLACES["bigtree"]`.

- [ ] **Step 3: Move the barrel, the spawns and add the signpost**

In `scripts/village.gd` Edit (single-line anchors):

old_string:
```
["keg", 143.0, -29.0]
```
new_string:
```
["keg", 124.0, -26.0]
```
old_string:
```
	["Λατομείο  ↘", 104.0, 84.0, 20],
```
new_string:
```
	["Λατομείο  ↘", 104.0, 84.0, 20],
	["Το Μεγάλο Δέντρο  →", 112.0, -44.0, 270],
```
In `scripts/enemies.gd` Edit:

old_string:
```
	["minion", 138.0, -22.0], ["warrior", 148.0, -36.0],
```
new_string:
```
	["minion", 120.0, -18.0], ["warrior", 130.0, -34.0],
```

- [ ] **Step 4: The map name and the sounds**

In `scripts/minimap.gd` Edit:

old_string:
```
	["camp", -175.0, 20.0, -24.0], ["quarry", 140.0, 125.0], ["crypt", 0.0, -178.0],
```
new_string:
```
	["camp", -175.0, 20.0, -24.0], ["quarry", 140.0, 125.0], ["crypt", 0.0, -178.0], ["bigtree", 172.0, -40.0],
```
In `scripts/strings_el.gd` Edit:

old_string:
```
	"camp": "Δυτικό Στρατόπεδο", "quarry": "Λατομείο", "crypt": "Παλιά Κρύπτη",
```
new_string:
```
	"camp": "Δυτικό Στρατόπεδο", "quarry": "Λατομείο", "crypt": "Παλιά Κρύπτη", "bigtree": "Η Λίμνη του Αιωνόβιου",
```
In `scripts/sound_manager.gd` Edit:

old_string:
```
	_add_positional_loop("wind_loop", Vector3(CRYPT.x, 6.0, CRYPT.y), 14.0, 60.0, -10.0)
```
new_string:
```
	_add_positional_loop("wind_loop", Vector3(CRYPT.x, 6.0, CRYPT.y), 14.0, 60.0, -10.0)
	_add_positional_loop("water_loop", Vector3(GreatTree.CENTER.x, 0.5, GreatTree.CENTER.y), 10.0, 50.0, -6.0)
	_add_positional_loop("wind_loop", Vector3(GreatTree.CENTER.x, 22.0, GreatTree.CENTER.y), 12.0, 55.0, -12.0)
```

- [ ] **Step 5: Import and run the tests**

Run: `godot --path . --headless --import 2>&1 | grep -i "error\|parse" | head -5`, then
`timeout 150 godot --path . --headless --script tools/great_tree_integration_test.gd > /tmp/t.txt 2>&1; echo exit=$?; grep -c "^PASS" /tmp/t.txt; grep "^FAIL\|SCRIPT ERROR" /tmp/t.txt`
Expected: all `PASS`.

If the signpost test fails on the position, find the label with `village.find_children("*", "Label3D", true, false)` and print its `global_position` (the sign's label sits a few metres above the post, offset by the rotation); widen the tolerance to 8 m rather than moving the sign. If the loop count is not 2, `_add_positional_loop` may create its player under another node: print `sm.find_children("*", "AudioStreamPlayer3D", true, false)` and count there.

Regression (the barrels are a quest): `mkdir -p tools/_shots/questtest && timeout 290 godot --path . --resolution 1280x720 --script tools/questtest.gd -- tools/_shots/questtest 2>&1 | grep -c "SCRIPT ERROR\|^FAIL"` prints 0 and the same for `sidequesttest`; if the GPU is busy, retry or note it. Also `timeout 150 godot --path . --headless --script tools/great_tree_walk_test.gd 2>&1 | grep -c "^FAIL"` prints 0.

- [ ] **Step 6: Commit**

```bash
godot --path . --headless --import > /dev/null 2>&1
git add scripts/village.gd scripts/enemies.gd scripts/minimap.gd scripts/strings_el.gd scripts/sound_manager.gd tools/great_tree_integration_test.gd tools/great_tree_integration_test.gd.uid
git commit -m "Fit the Great Tree area into the map: barrel, spawns, signpost, map name and lake sounds"
```

---

### Task 6: Screenshots, look and frame rate

**Files:**
- Create: `tools/greattreeshot.gd`
- Modify (only if the look needs tuning): `scripts/tree_meshes.gd` (palette, proportions), `scripts/great_tree.gd` (`HOUSE_SCALE`, house yaw, positions, lights), `scripts/balloon.gd`

- [ ] **Step 1: The screenshot driver**

Create `tools/greattreeshot.gd`:

```gdscript
extends SceneTree
## Screenshots of the Great Tree area and the frame rate in it:
##   godot --path . --resolution 1920x1080 --script tools/greattreeshot.gd -- tools/_shots/greattreeshot [day|night]
## Without the last word both parts run in one process; on a GPU shared with other programs run them one
## after the other (a long run can run out of memory).
var out := "."
var part := "both"

# [name, position (local to the area centre), look-at target (local), measure fps]
const VIEWS := [
	["01_approach", Vector3(-62.0, 0.05, 0.0), Vector3(0.0, 12.0, 0.0), true],
	["02_shore", Vector3(-46.0, 0.05, 2.5), Vector3(-24.0, 3.0, 3.0), false],
	["03_entry_island", Vector3(-24.0, 2.4, 3.0), Vector3(4.0, 22.0, -1.0), false],
	["04_causeway", Vector3(4.0, 5.2, -16.5), Vector3(18.0, 7.0, -8.0), false],
	["05_plateau", Vector3(11.0, 7.0, 4.0), Vector3(4.0, 8.0, -1.0), true],
	["06_south_island", Vector3(-10.0, 5.0, 21.0), Vector3(4.0, 14.0, 0.0), false],
	["07_far_island", Vector3(28.0, 3.4, -4.0), Vector3(4.0, 8.0, 0.0), false],
	["08_in_the_water", Vector3(-12.0, 0.05, -16.0), Vector3(4.0, 14.0, -1.0), false],
]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		part = args[1]
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func sample(label: String, secs: float) -> void:
	var t0 := Time.get_ticks_msec()
	var frames := 0
	while Time.get_ticks_msec() - t0 < secs * 1000.0:
		await process_frame
		frames += 1
	print("PERF ", label, ": ", snappedf(frames / secs, 0.1), " fps, draw calls ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


## George stands at `local` (relative to the area centre) and looks at `target` (also local).
func visit(p: Player, local: Vector3, target: Vector3) -> void:
	var c := Vector3(172.0, 0.0, -40.0)
	var pos := c + local
	var look := c + target
	p.teleport(pos, atan2(look.x - pos.x, look.z - pos.z))
	await create_timer(1.6).timeout


func run_views(p: Player, prefix: String, measure: bool) -> void:
	for v in VIEWS:
		await visit(p, v[1], v[2])
		await shot("%s_%s" % [prefix, v[0]])
		if measure and v[3]:
			await sample("%s %s" % [prefix, v[0]], 3.0)


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var dn := get_first_node_in_group("daynight") as DayNight
	p._invulnerable = 99999.0
	dn.running = false
	if part != "night":
		dn.set_time(12.0)
		await create_timer(1.0).timeout
		await run_views(p, "day", true)
	if part == "day":
		quit()
		return
	dn.set_time(22.0)
	await create_timer(2.0).timeout
	for v in [VIEWS[0], VIEWS[4], VIEWS[2]]:
		await visit(p, v[1], v[2])
		await shot("night_%s" % v[0])
		await sample("night %s" % v[0], 3.0)
	quit()
```

- [ ] **Step 2: Run it and look at every picture**

Run: `mkdir -p tools/_shots/greattreeshot && timeout 450 godot --path . --resolution 1920x1080 --script tools/greattreeshot.gd -- tools/_shots/greattreeshot day > /tmp/gs1.txt 2>&1; echo day exit=$?; grep "PERF\|SCRIPT ERROR" /tmp/gs1.txt; timeout 450 godot --path . --resolution 1920x1080 --script tools/greattreeshot.gd -- tools/_shots/greattreeshot night > /tmp/gs2.txt 2>&1; echo night exit=$?; grep "PERF\|SCRIPT ERROR" /tmp/gs2.txt; ls tools/_shots/greattreeshot/*.png`
Expected: 8 day pictures, 3 night pictures and `PERF` lines. If a run crashes (Vulkan memory), retry, then use `--resolution 1280x720`, and tell Theodore if it is only possible at that size.

Look at each PNG with the Read tool. Check: the lake is a believable turquoise (not black or white), the islands read as rock with mossy tops and a cliff (not as blobs or discs), the great tree is clearly the centre of the picture with a full canopy and a thick trunk with roots, the bridges look like rope bridges with a sagging plank deck and rails, the causeway climbs around the central island on pillars, the houses stand upright with their doors toward the tree, the umbrella trees look like mushrooms, the balloons are visible against the sky with stripes, no geometry is inside out (a black or see-through face means a winding error), George can be seen on a bridge or island without clipping, the signpost and other village things are not inside the lake, night pictures: the lanterns glow and the three lights light the houses without blowing out. FPS: every `PERF` line should be 58 or more (60 expected).

**Visual bar check (spec risk):** if it does not look good, tune it here, then re-run the driver: palette constants at the top of `scripts/tree_meshes.gd`; island profile numbers in `TreeMeshes.island` (the rim wobble `0.06/0.04/0.02`, the lip, the ring radii); tree proportions (`height`, `br`, the `blobs` list, the 0.78 flattening); `HOUSE_SCALE`, the house yaw (add `+ 180.0` to `rad_to_deg(atan2(d.x, d.z))` if the doors face away), the `HOUSES` positions; light energies; balloon sizes and heights in `BALLOONS`. If the frame rate drops, reduce `great_tree` blob count and vines first, then the flower and bridge rope detail. If something cannot be fixed within this task, stop and tell Theodore what you saw with the screenshot paths.

- [ ] **Step 3: Re-run the headless tests after any tuning**

`tree_meshes_test`, `great_tree_walk_test`, `great_tree_props_test`, `balloon_test` and `great_tree_integration_test` must all print 0 for `grep -c "^FAIL"` (a changed island height or house position can break a route or a bridge end).

- [ ] **Step 4: Commit**

```bash
godot --path . --headless --import > /dev/null 2>&1
git add tools/greattreeshot.gd tools/greattreeshot.gd.uid scripts/tree_meshes.gd scripts/great_tree.gd scripts/balloon.gd
git commit -m "Add the Great Tree screenshot driver and tune the look"
```
(Only the files that changed are staged; `git add` of an unchanged file is harmless.)

---

### Task 7: Regression run and documentation

**Files:**
- Modify: `CLAUDE.md`, `HANDOVER.md`, `CHANGELOG.md`
- No `project.godot` version bump, no tag, no push.

- [ ] **Step 1: Regression tests**

Run and confirm no `FAIL` and no `SCRIPT ERROR` in each (windowed ones need the GPU; retry on a crash and note it honestly):

```bash
godot --path . --headless --import
for t in tree_meshes_test great_tree_walk_test great_tree_props_test balloon_test great_tree_integration_test fish_data_test kitchen_test kitchen_window_test fishing_test gender_test guard_snag_test part3_data_test part3_mobs_test frontier_enter_test frontier_build_test part3_hooks_test; do timeout 300 godot --path . --headless --script tools/$t.gd > /tmp/v_$t.txt 2>&1; echo "$t exit=$? pass=$(grep -c '^PASS' /tmp/v_$t.txt) fail=$(grep -c '^FAIL' /tmp/v_$t.txt) err=$(grep -c 'SCRIPT ERROR' /tmp/v_$t.txt)"; done
for t in questtest sidequesttest eventtest minimaptest savetest keepertest guardtest; do mkdir -p tools/_shots/$t; for try in 1 2; do timeout 290 godot --path . --resolution 1280x720 --script tools/$t.gd -- tools/_shots/$t > /tmp/v_$t.txt 2>&1; rc=$?; [ $rc -eq 0 ] && break; done; echo "$t exit=$rc tries=$try err=$(grep -c 'SCRIPT ERROR' /tmp/v_$t.txt) fail=$(grep -c '^FAIL' /tmp/v_$t.txt)"; done
godot --path . --resolution 1920x1080 --script tools/perftest.gd 2>&1 | grep PERF
godot --path . --resolution 1920x1080 --script tools/perftest.gd -- night 2>&1 | grep PERF
```
Expected: all green; the village stays at about 60 fps (the new area is far from the perftest viewpoints, so this mainly checks that nothing else got slower). Check that `tools/_shots/minimaptest` shows the lake in the east of the map picture (the one-off capture sees the islands) and that `git status --short` shows only the files of this task, and that `ls "$APPDATA/Godot/app_userdata/Οι Περιπέτειες του Γιώργου στον Άγιο Βλάση/"` has no leftover `*before*` files (back up and compare the save files before and after as in earlier runs).

- [ ] **Step 2: CHANGELOG**

In `CHANGELOG.md`, insert above the first `## ` heading (the newest entry):

```markdown
## 0.16-beta (unreleased) — the Great Tree and its lake
**New in this version**
- **A new place in the east of the map** (`scripts/great_tree.gd`, `scripts/tree_meshes.gd`, `scripts/balloon.gd`, about 170 m east of the well): a turquoise lake with a central rock island that carries a **giant tree** and two houses, four smaller islands with umbrella trees, flowers and a golden chest, **rope bridges** with rails, a **stone causeway** that winds around the central island on pillars, lanterns, and **hot-air balloons** drifting overhead (one is moored on the entry island). Walk in from the village side along the new signpost "Το Μεγάλο Δέντρο →"; the place is named "Η Λίμνη του Αιωνόβιου" on the big map.
- Everything is built in code in the game's low-poly style (flat shading, vertex colours) and everything is walkable (trimesh colliders, bridge rails, slopes under 15 degrees); the lake is shallow wading water. No gameplay change; only three real lights at night (lanterns glow through emissive materials).
- The quest barrel and the two skeletons next to it moved 20 m west to make room.
- New test drivers: `tree_meshes_test`, `great_tree_walk_test` (a capsule like George walks the three routes, rails and cliffs), `great_tree_props_test`, `balloon_test`, `great_tree_integration_test` (headless), `greattreeshot` (screenshots + fps; run its `day` and `night` parts one after the other on a GPU shared with other programs).

**Not done yet:** a rideable balloon, NPCs or quests in this place, swimming, fish in this lake.

```

- [ ] **Step 3: CLAUDE.md**

In `CLAUDE.md`, add before the paragraph that starts `**Village square**`:

```markdown
**The Great Tree and its lake** (`great_tree.gd` class `GreatTree`, `tree_meshes.gd` class `TreeMeshes`, `balloon.gd` class `Balloon`; added by `Village._build_great_tree()` right after the totems, which also registers `_occupy(CENTER, AREA_RADIUS)` so nothing is scattered in it): a showcase area centred at world (172, -40): an oval lake (radii 36 x 30, water shader with turquoise parameters, sand ring `Terrain.add_patch`), five rock islands (`GreatTree.ISLANDS`: central r 11 top y 7.0 with the tree and two KayKit houses, entry, south with the chest, east with a bench, far), seven bridges (`bridge_list()`, endpoints from `island_point`/`plateau_point`, sag 1.5% of the length, slope under 0.27) and a stone causeway (`RAMP`: an arc of radius 16.5 around the central island from 180 to 330 degrees, y 2.4 to 7.0, on pillars) so every island is reachable from the shore bridge at local (-41, 2.5). All coordinates in that file are local to `CENTER`; `GreatTree.to_world` converts. `TreeMeshes` is a pure geometry library (no scene access): the `Soup` triangle builder (`tri` orients each triangle away from an `inside` point, because Godot's front faces are clockwise seen from outside; `box`, `strut`), `lathe`/`lathe_into` (a profile revolved around Y with rim `outline`, vertex `wobble`, `stripes`), `island`, `great_tree`, `umbrella_tree`, `bridge`/`bridge_collision`, `ramp`/`ramp_collision`, `pillar`, `balloon`, props; everything is flat shaded with vertex colours drawn with `TreeMeshes.material()`. Colliders are trimesh shapes on layer 1 (bridge and ramp collision meshes add invisible rails 1.1 m high), the lake has no collider (shallow, like the pond), the ground box stays at y 0. `Balloon` drifts on an ellipse (`center`, `radii`, `angular_speed`) and bobs; one is `moored`. Lighting: exactly three `OmniLight3D` in group `night_lights` (two house doors, the deck); lantern heads glow through an emissive material. The quest barrel moved to (124, -26) and its two skeleton spawns to (120, -18) and (130, -34); the signpost "Το Μεγάλο Δέντρο  →" stands at (112, -44); the big map names the place `bigtree` ("Η Λίμνη του Αιωνόβιου"); `SoundManager` has `water_loop` and `wind_loop` positional loops at the lake. Tests: `tree_meshes_test`, `great_tree_walk_test` (a capsule like George walks three routes, bridge rails and cliffs), `great_tree_props_test`, `balloon_test`, `great_tree_integration_test` (headless), `greattreeshot` (`-- <dir> day` and `-- <dir> night` as two processes when another Godot holds the GPU). Do not type-reference `GreatTree` in a `--script` test: `load("res://scripts/great_tree.gd")`.

```

- [ ] **Step 4: HANDOVER.md**

Edit `HANDOVER.md` (Edit tool, UTF-8): in section 0 add a bullet at the top of the list: `**Built, tested and committed on branch feature/great-tree (7 commits on top of main), NOT merged, pushed, tagged or released: the Great Tree lake area in the east (spec docs/superpowers/specs/2026-10-13-big-tree-lake-design.md, plan docs/superpowers/plans/2026-10-13-big-tree-lake.md; all 7 tasks done, executed inline).** Theodore asked for it from a picture (a fantasy floating-island world); it is a walkable showcase place, no new systems. Headless tests pass, 60 fps in the screenshot runs.` and replace the "What to do now" bullet so it says: wait for Theodore to try it (F5 on that branch: follow the signpost east of the market, or walk to (172, -40)), then merge when he says so (release target 0.16-beta, see memory `github-releases`; note that the `feature/weather` branch is a separate, still unmerged piece of work). Add `tree_meshes_test`, `great_tree_walk_test`, `great_tree_props_test`, `balloon_test`, `great_tree_integration_test` and `greattreeshot` to the test-driver list in section 2; add a paragraph `**The Great Tree and its lake (unreleased, branch feature/great-tree):**` before `Release history:` in section 3 with two sentences from the CHANGELOG entry and a pointer to `CLAUDE.md` ("The Great Tree and its lake"); add `great_tree.gd`, `tree_meshes.gd`, `balloon.gd` to the **world** list of the file map.

- [ ] **Step 5: Final state and commit**

Run: `git status --short`
Expected: only the three docs modified.

```bash
git add CLAUDE.md HANDOVER.md CHANGELOG.md
git commit -m "Document the Great Tree and its lake"
```

- [ ] **Step 6: Report to Theodore**

Tell him, in Greek or Greeklish and short: what exists (the lake, the tree, bridges, causeway, balloons, chest, signpost, map name), the test results (list any `FAIL` honestly), the fps numbers, the screenshot paths, that nothing was merged, pushed, tagged or released, and that merging and releasing as `0.16-beta` wait for his word. Mention what only he can judge: how it looks next to the photo (he knows what he expects) and that the house size and the balloon colours are easy to change.

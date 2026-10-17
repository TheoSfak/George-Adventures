class_name NavGrid
extends RefCounted
## Walkable-ground grid of one region (the village, the Frontier, the catacombs), built from the static colliders
## themselves, plus A* paths over it. The world is flat (ground top at y = 0) and made of boxes, cylinders and a few
## trimeshes, so a grid is cheap and deterministic; Godot's AStarGrid2D (C++) does the searching.
## Pure: no autoload references. Spec: docs/superpowers/specs/2026-10-14-camera-pathfinding-design.md
##
## How it works: every StaticBody3D of collision layer 1 under the roots that is not marked meta "nav_ignore" gives the
## footprints of its shapes (circles and convex polygons); only shapes that reach into the walking band
## BAND_MIN..BAND_MAX above the ground block (not the ground box, roofs or bridge decks). For a clearance class
## (0.6 m for ordinary walkers, 1.2 m for big ones) the footprints are inflated by that distance and drawn into a raster
## of 0.5 m cells; a coarse cell (1 m) is solid when any of its four fine cells is. Walkers keep their centre in free
## cells, so they clear the obstacles by about their own radius.

const FINE := 0.5                         # raster cell, metres
const COARSE := 2                         # fine cells per A* cell
const BAND_MIN := 0.3
const BAND_MAX := 1.9
const CLEARANCES: Array[float] = [0.6, 1.2]
const LINE_STEP := 0.25                   # sampling step of line_clear
const LOOKAHEAD := 12                     # waypoints tried when smoothing a path
const LEADING_FREE := 1.2                 # a walker may start inside the inflated zone of a wall it hugs (metres)
const MIN_NORMAL_Y := 0.85                # triangles flatter than this (nearly horizontal) never block

static var _regions := {}                 # id -> NavGrid

var rect := Rect2()                       # world xz extent (x, z, width, depth)
var _w := 0                               # fine cells across x
var _h := 0                               # fine cells across z
var _cw := 0                              # coarse cells across x
var _ch := 0
var _circles: Array = []                  # [cx, cz, r]
var _polys: Array = []                    # [PackedVector2Array counter-clockwise, Vector2 min, Vector2 max]
var _classes := {}                        # clearance -> {"fine": PackedByteArray, "astar": AStarGrid2D}
var _threads: Array[Thread] = []
var shape_count := 0                      # footprints collected, for tests and probes


# ----------------------------------------------------------------- registry ----

static func set_region(id: String, grid: NavGrid) -> void:
	_regions[id] = grid


static func clear_regions() -> void:
	var current_id := OS.get_thread_caller_id()
	for id in _regions:
		var g := _regions[id] as NavGrid
		if g != null:
			for t in g._threads:
				if t.is_alive() and str(t.get_id()) != str(current_id):
					t.wait_to_finish()
	_regions.clear()


static func region(id: String) -> NavGrid:
	return _regions.get(id) as NavGrid


## The grid whose rectangle holds this position, null when the position is in no region (then walkers go straight).
static func at(pos: Vector3) -> NavGrid:
	var p := Vector2(pos.x, pos.z)
	for id in _regions:
		var g := _regions[id] as NavGrid
		if g.rect.has_point(p):
			return g
	return null


## The clearance class for a walker of this collision radius.
static func clearance_for(radius: float) -> float:
	var need := radius + 0.2
	for c in CLEARANCES:
		if need <= c + 0.0001:
			return c
	return CLEARANCES[CLEARANCES.size() - 1]


# -------------------------------------------------------------------- build ----

## Reads the colliders under `roots` (nodes that must be inside the tree). Call prepare() before using the grid.
static func build(roots: Array, world_rect: Rect2) -> NavGrid:
	var g := NavGrid.new()
	g.rect = world_rect
	g._w = int(ceil(world_rect.size.x / FINE))
	g._h = int(ceil(world_rect.size.y / FINE))
	g._cw = int(ceil(float(g._w) / COARSE))
	g._ch = int(ceil(float(g._h) / COARSE))
	for root in roots:
		g._collect(root as Node)
	return g


## Builds the rasters and A* grids of every clearance class: at once, or on worker threads (queries of a class that is
## not ready yet say "clear" and "no path", so walkers behave as before until it is).
func prepare(threaded := false) -> void:
	for c in CLEARANCES:
		if threaded:
			var t := Thread.new()
			_threads.append(t)
			t.start(_make_class_threaded.bind(c, t))
		else:
			_classes[c] = _make_class(c)


func is_ready(clearance: float = CLEARANCES[0]) -> bool:
	return _classes.has(clearance)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		var current_id := OS.get_thread_caller_id()
		for t in _threads:
			if t.is_alive() and str(t.get_id()) != str(current_id):
				t.wait_to_finish()


func _make_class_threaded(clearance: float, thread: Thread) -> void:
	var data := _make_class(clearance)
	_class_done.call_deferred(clearance, data, thread)


func _class_done(clearance: float, data: Dictionary, thread: Thread) -> void:
	_classes[clearance] = data
	thread.wait_to_finish()
	_threads.erase(thread)


func _collect(root: Node) -> void:
	if root == null:
		return
	var bodies: Array = root.find_children("*", "StaticBody3D", true, false)
	if root is StaticBody3D:
		bodies.append(root)
	for b in bodies:
		var body := b as StaticBody3D
		if body.collision_layer & 1 == 0 or body.has_meta("nav_ignore"):
			continue
		for child in body.get_children():
			var cs := child as CollisionShape3D
			if cs != null and not cs.disabled and cs.shape != null and cs.is_inside_tree():
				_add_shape(cs.shape, cs.global_transform)


func _add_shape(shape: Shape3D, xf: Transform3D) -> void:
	var sx := xf.basis.x.length()
	var sy := xf.basis.y.length()
	var sz := xf.basis.z.length()
	if shape is BoxShape3D:
		var half := (shape as BoxShape3D).size * 0.5
		var pts := PackedVector2Array()
		var lo := INF
		var hi := -INF
		for sxn in [-1.0, 1.0]:
			for syn in [-1.0, 1.0]:
				for szn in [-1.0, 1.0]:
					var p := xf * Vector3(half.x * sxn, half.y * syn, half.z * szn)
					lo = minf(lo, p.y)
					hi = maxf(hi, p.y)
					pts.append(Vector2(p.x, p.z))
		if hi >= BAND_MIN and lo <= BAND_MAX:
			_add_hull(pts)
	elif shape is CylinderShape3D:
		var cyl := shape as CylinderShape3D
		var half_h := cyl.height * 0.5 * sy
		if xf.origin.y + half_h >= BAND_MIN and xf.origin.y - half_h <= BAND_MAX:
			_circles.append([xf.origin.x, xf.origin.z, cyl.radius * maxf(sx, sz)])
			shape_count += 1
	elif shape is SphereShape3D:
		var sph := shape as SphereShape3D
		var r := sph.radius * maxf(sx, maxf(sy, sz))
		if xf.origin.y + r >= BAND_MIN and xf.origin.y - r <= BAND_MAX:
			_circles.append([xf.origin.x, xf.origin.z, r])
			shape_count += 1
	elif shape is CapsuleShape3D:
		var cap := shape as CapsuleShape3D
		var half_h := cap.height * 0.5 * sy
		if xf.origin.y + half_h >= BAND_MIN and xf.origin.y - half_h <= BAND_MAX:
			_circles.append([xf.origin.x, xf.origin.z, cap.radius * maxf(sx, sz)])
			shape_count += 1
	elif shape is ConvexPolygonShape3D:
		var pts2 := PackedVector2Array()
		var lo2 := INF
		var hi2 := -INF
		for p3 in (shape as ConvexPolygonShape3D).points:
			var p := xf * p3
			lo2 = minf(lo2, p.y)
			hi2 = maxf(hi2, p.y)
			pts2.append(Vector2(p.x, p.z))
		if hi2 >= BAND_MIN and lo2 <= BAND_MAX:
			_add_hull(pts2)
	elif shape is ConcavePolygonShape3D:
		var faces := (shape as ConcavePolygonShape3D).get_faces()
		var i := 0
		while i + 2 < faces.size():
			var a := xf * faces[i]
			var b := xf * faces[i + 1]
			var c := xf * faces[i + 2]
			i += 3
			var lo3 := minf(a.y, minf(b.y, c.y))
			var hi3 := maxf(a.y, maxf(b.y, c.y))
			if hi3 < BAND_MIN or lo3 > BAND_MAX:
				continue
			var n := (b - a).cross(c - a)
			if n.length_squared() > 0.000001 and absf(n.normalized().y) > MIN_NORMAL_Y:
				continue
			_add_polygon(PackedVector2Array([Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z)]))


func _add_hull(points: PackedVector2Array) -> void:
	var hull := Geometry2D.convex_hull(points)
	if hull.size() > 1 and hull[0] == hull[hull.size() - 1]:
		hull.remove_at(hull.size() - 1)
	if hull.size() >= 2:
		_add_polygon(hull)


func _add_polygon(pts: PackedVector2Array) -> void:
	var area2 := 0.0
	var lo := pts[0]
	var hi := pts[0]
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		area2 += a.x * b.y - b.x * a.y
		lo = lo.min(a)
		hi = hi.max(a)
	if area2 < 0.0:
		var rev := PackedVector2Array()
		for i in range(pts.size() - 1, -1, -1):
			rev.append(pts[i])
		pts = rev
	_polys.append([pts, lo, hi])
	shape_count += 1


# ------------------------------------------------------------------ rasters ----

func _make_class(clearance: float) -> Dictionary:
	var fine := _rasterize(clearance)
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(0, 0, _cw, _ch)
	astar.cell_size = Vector2.ONE * (FINE * COARSE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	for cz in _ch:
		for cx in _cw:
			if _coarse_blocked(fine, cx, cz):
				astar.set_point_solid(Vector2i(cx, cz), true)
	return {"fine": fine, "astar": astar}


func _coarse_blocked(fine: PackedByteArray, cx: int, cz: int) -> bool:
	for dz in COARSE:
		var iz := cz * COARSE + dz
		if iz >= _h:
			continue
		for dx in COARSE:
			var ix := cx * COARSE + dx
			if ix < _w and fine[iz * _w + ix] != 0:
				return true
	return false


func _rasterize(clearance: float) -> PackedByteArray:
	var fine := PackedByteArray()
	fine.resize(_w * _h)
	var ox := rect.position.x
	var oz := rect.position.y
	for c in _circles:
		var r: float = c[2] + clearance
		var r2 := r * r
		var x0 := maxi(int(floor((c[0] - r - ox) / FINE)), 0)
		var x1 := mini(int(floor((c[0] + r - ox) / FINE)), _w - 1)
		var z0 := maxi(int(floor((c[1] - r - oz) / FINE)), 0)
		var z1 := mini(int(floor((c[1] + r - oz) / FINE)), _h - 1)
		for iz in range(z0, z1 + 1):
			var dz: float = oz + (iz + 0.5) * FINE - c[1]
			var row := iz * _w
			for ix in range(x0, x1 + 1):
				var dx: float = ox + (ix + 0.5) * FINE - c[0]
				if dx * dx + dz * dz <= r2:
					fine[row + ix] = 1
	var c2 := clearance * clearance
	for poly in _polys:
		var pts: PackedVector2Array = poly[0]
		var lo: Vector2 = poly[1]
		var hi: Vector2 = poly[2]
		var x0 := maxi(int(floor((lo.x - clearance - ox) / FINE)), 0)
		var x1 := mini(int(floor((hi.x + clearance - ox) / FINE)), _w - 1)
		var z0 := maxi(int(floor((lo.y - clearance - oz) / FINE)), 0)
		var z1 := mini(int(floor((hi.y + clearance - oz) / FINE)), _h - 1)
		var n := pts.size()
		for iz in range(z0, z1 + 1):
			var row := iz * _w
			var pz := oz + (iz + 0.5) * FINE
			for ix in range(x0, x1 + 1):
				var p := Vector2(ox + (ix + 0.5) * FINE, pz)
				var inside := true
				var best := INF
				for i in n:
					var a := pts[i]
					var ab := pts[(i + 1) % n] - a
					var ap := p - a
					if ab.x * ap.y - ab.y * ap.x < 0.0:
						inside = false
					var len2 := ab.length_squared()
					var t := 0.0 if len2 <= 0.0000001 else clampf(ap.dot(ab) / len2, 0.0, 1.0)
					best = minf(best, (a + ab * t).distance_squared_to(p))
				var d2 := 0.0 if inside else best
				if d2 <= c2:
					fine[row + ix] = 1
	return fine


## Squared distance from p to a counter-clockwise convex polygon (0 inside).
func _poly_dist2(pts: PackedVector2Array, p: Vector2) -> float:
	var inside := true
	var best := INF
	var n := pts.size()
	for i in n:
		var a := pts[i]
		var ab := pts[(i + 1) % n] - a
		var ap := p - a
		if ab.x * ap.y - ab.y * ap.x < 0.0:
			inside = false
		var len2 := ab.length_squared()
		var t := 0.0 if len2 <= 0.0000001 else clampf(ap.dot(ab) / len2, 0.0, 1.0)
		best = minf(best, (a + ab * t).distance_squared_to(p))
	return 0.0 if inside else best


# ------------------------------------------------------------------ queries ----

func _fine_index(x: float, z: float) -> int:
	var ix := int(floor((x - rect.position.x) / FINE))
	var iz := int(floor((z - rect.position.y) / FINE))
	if ix < 0 or iz < 0 or ix >= _w or iz >= _h:
		return -1
	return iz * _w + ix


## True when a walker of this clearance class cannot stand at `pos` (no information = free).
func blocked(pos: Vector3, clearance: float = CLEARANCES[0]) -> bool:
	var cls = _classes.get(clearance)
	if cls == null:
		return false
	var i := _fine_index(pos.x, pos.z)
	return i >= 0 and (cls["fine"] as PackedByteArray)[i] != 0


## Is the straight line a to b free for this clearance class? A walker that starts inside the inflated zone of a wall
## (it hugs it, its body is a capsule) is not stopped by the first LEADING_FREE metres of blocked cells. Without a ready
## class it says true.
func line_clear(a: Vector3, b: Vector3, clearance: float = CLEARANCES[0]) -> bool:
	var cls = _classes.get(clearance)
	if cls == null:
		return true
	return _line_free(cls["fine"], Vector2(a.x, a.z), Vector2(b.x, b.z))


func _line_free(fine: PackedByteArray, a: Vector2, b: Vector2) -> bool:
	var d := b - a
	var length := d.length()
	var steps := maxi(int(ceil(length / LINE_STEP)), 1)
	var leading := true
	for s in range(steps + 1):
		var p := a + d * (float(s) / float(steps))
		var i := _fine_index(p.x, p.y)
		if i >= 0 and fine[i] != 0:
			if leading and float(s) * length / float(steps) <= LEADING_FREE:
				continue
			return false
		leading = false
	return true


## A path from a to b as world points (y = 0) without a and with b (or the nearest free spot to it) as the last point,
## smoothed by line-of-sight shortcuts. Empty: no information yet, the walker is outside the grid or b cannot be reached.
func find_path(a: Vector3, b: Vector3, clearance: float = CLEARANCES[0]) -> PackedVector3Array:
	var out := PackedVector3Array()
	var cls = _classes.get(clearance)
	if cls == null:
		return out
	var fine: PackedByteArray = cls["fine"]
	var astar: AStarGrid2D = cls["astar"]
	var ca := _free_coarse(astar, _to_coarse(a))
	var cb := _free_coarse(astar, _to_coarse(b))
	if ca.x < 0 or cb.x < 0:
		return out
	var ids: Array[Vector2i] = astar.get_id_path(ca, cb, true)
	if ids.is_empty():
		return out
	# the goal itself when the search reached it and it is free ground, else the closest point the search could reach
	var goal := Vector2(b.x, b.z)
	var gi := _fine_index(goal.x, goal.y)
	if ids[ids.size() - 1] != cb or gi < 0 or fine[gi] != 0:
		goal = _coarse_center(ids[ids.size() - 1])
	if ids.size() == 1 and ids[0] == ca:
		return out
	if Vector2(a.x, a.z).distance_to(goal) < 0.6:
		return out
	if _line_free(fine, Vector2(a.x, a.z), goal):
		out.append(Vector3(goal.x, 0.0, goal.y))
		return out
	var way: Array[Vector2] = [Vector2(a.x, a.z)]
	for k in range(1, ids.size() - 1):
		way.append(_coarse_center(ids[k]))
	way.append(goal)
	var i := 0
	while i < way.size() - 1:
		var j := mini(i + LOOKAHEAD, way.size() - 1)
		while j > i + 1 and not _line_free(fine, way[i], way[j]):
			j -= 1
		out.append(Vector3(way[j].x, 0.0, way[j].y))
		i = j
	return out


func _to_coarse(pos: Vector3) -> Vector2i:
	var cs := FINE * COARSE
	return Vector2i(clampi(int(floor((pos.x - rect.position.x) / cs)), 0, _cw - 1), clampi(int(floor((pos.z - rect.position.y) / cs)), 0, _ch - 1))


func _coarse_center(c: Vector2i) -> Vector2:
	var cs := FINE * COARSE
	return Vector2(rect.position.x + (c.x + 0.5) * cs, rect.position.y + (c.y + 0.5) * cs)


## The coarse cell itself when it is free, else the nearest free one within a few rings, else (-1, -1).
func _free_coarse(astar: AStarGrid2D, c: Vector2i) -> Vector2i:
	if not astar.is_point_solid(c):
		return c
	for ring in range(1, 7):
		for dz in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dz)) != ring:
					continue
				var n := Vector2i(c.x + dx, c.y + dz)
				if n.x >= 0 and n.y >= 0 and n.x < _cw and n.y < _ch and not astar.is_point_solid(n):
					return n
	return Vector2i(-1, -1)


# -------------------------------------------------------------------- debug ----

## The raster of a class as a picture (white = blocked), one pixel per fine cell.
func debug_image(clearance: float = CLEARANCES[0], path: PackedVector3Array = PackedVector3Array()) -> Image:
	var img := Image.create(_w, _h, false, Image.FORMAT_RGB8)
	var cls = _classes.get(clearance)
	if cls == null:
		return img
	var fine: PackedByteArray = cls["fine"]
	for iz in _h:
		for ix in _w:
			img.set_pixel(ix, iz, Color(0.95, 0.95, 0.95) if fine[iz * _w + ix] != 0 else Color(0.12, 0.14, 0.12))
	for p in path:
		var i := _fine_index(p.x, p.z)
		if i >= 0:
			var px := i % _w
			var pz := i / _w
			for dz in range(-2, 3):
				for dx in range(-2, 3):
					if px + dx >= 0 and px + dx < _w and pz + dz >= 0 and pz + dz < _h:
						img.set_pixel(px + dx, pz + dz, Color(1.0, 0.2, 0.2))
	return img

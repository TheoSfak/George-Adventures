extends SceneTree
## NavGrid on a synthetic world made of StaticBody3Ds: godot --path . --headless --script tools/nav_grid_test.gd
var failed := false
var holder: Node3D


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


## A static body with one shape at a position (and a yaw), under `holder`.
func add_body(shape: Shape3D, pos: Vector3, yaw := 0.0, layer := 1) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	holder.add_child(body)
	body.global_position = pos
	body.rotation.y = yaw
	return body


func box(x: float, y: float, z: float) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = Vector3(x, y, z)
	return b


func fresh() -> void:
	if holder != null:
		holder.queue_free()
	holder = Node3D.new()
	root.add_child(holder)


func build(world := Rect2(-50, -50, 100, 100)) -> NavGrid:
	var g := NavGrid.build([holder], world)
	g.prepare()
	return g


func path_ok(g: NavGrid, path: PackedVector3Array, start: Vector3, clearance := 0.6) -> bool:
	var prev := start
	for p in path:
		if not g.line_clear(prev, p, clearance):
			return false
		prev = p
	return true


func path_length(path: PackedVector3Array, start: Vector3) -> float:
	var total := 0.0
	var prev := start
	for p in path:
		total += prev.distance_to(p)
		prev = p
	return total


func _run() -> void:
	await process_frame
	# --- open ground
	fresh()
	var g := build()
	var a := Vector3(-20, 0, 0)
	var b := Vector3(20, 0, 0)
	check("an empty world has a free line", g.line_clear(a, b))
	var p := g.find_path(a, b)
	check("and a path that ends at the goal", p.size() >= 1 and p[p.size() - 1].distance_to(b) < 0.01)
	check("a straight path is smoothed to one segment", p.size() == 1)
	check("clearance classes", NavGrid.clearance_for(0.4) == 0.6 and NavGrid.clearance_for(0.9) == 1.2 and NavGrid.clearance_for(3.0) == 1.2)

	# --- a wall across the way
	fresh()
	add_body(box(1.0, 2.0, 20.0), Vector3(0, 1, 0))
	g = build()
	check("a wall blocks the line", not g.line_clear(a, b))
	check("the wall is blocked ground, the open side is not", g.blocked(Vector3(0, 0, 0)) and not g.blocked(Vector3(10, 0, 0)))
	p = g.find_path(a, b)
	check("a path exists around the wall", p.size() >= 2 and p[p.size() - 1].distance_to(b) < 0.01)
	check("it goes around the end of the wall (z beyond 10)", _max_abs_z(p) > 10.0)
	check("every segment of it is free", path_ok(g, p, a))
	check("it is longer than the straight line and shorter than a detour of 60 m", path_length(p, a) > 40.0 and path_length(p, a) < 60.0)
	check("a walker next to the wall (inside its inflated zone) can still leave", g.line_clear(Vector3(-0.9, 0, 0), Vector3(-10, 0, 0)))

	# --- a rotated box and a cylinder
	fresh()
	add_body(box(2.0, 2.0, 30.0), Vector3(0, 1, 0), deg_to_rad(45.0))
	g = build()
	check("a rotated wall blocks its diagonal", g.blocked(Vector3(7, 0, 7)) and g.blocked(Vector3(-7, 0, -7)))
	check("and leaves the other diagonal free", not g.blocked(Vector3(7, 0, -7)))
	fresh()
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.0
	cyl.height = 3.0
	add_body(cyl, Vector3(0, 1.5, 0))
	g = build()
	check("a cylinder blocks its disc plus the clearance", g.blocked(Vector3(1.2, 0, 0)) and not g.blocked(Vector3(1.8, 0, 0)))
	check("a bigger walker keeps farther away", g.blocked(Vector3(1.8, 0, 0), 1.2) and not g.blocked(Vector3(2.4, 0, 0), 1.2))
	p = g.find_path(Vector3(-10, 0, 0), Vector3(10, 0, 0))
	check("a path leads around the pillar", p.size() >= 2 and path_ok(g, p, Vector3(-10, 0, 0)))

	# --- goal inside an obstacle, unreachable goal
	fresh()
	add_body(box(6.0, 3.0, 6.0), Vector3(10, 1.5, 0))
	g = build()
	p = g.find_path(Vector3(-10, 0, 0), Vector3(10, 0, 0))
	check("a goal inside a house ends next to it", p.size() >= 1 and not g.blocked(p[p.size() - 1]) and p[p.size() - 1].distance_to(Vector3(10, 0, 0)) < 6.0)
	fresh()
	add_body(box(14.0, 2.0, 1.0), Vector3(0, 1, 7))
	add_body(box(14.0, 2.0, 1.0), Vector3(0, 1, -7))
	add_body(box(1.0, 2.0, 14.0), Vector3(7, 1, 0))
	add_body(box(1.0, 2.0, 14.0), Vector3(-7, 1, 0))
	g = build()
	p = g.find_path(Vector3(-30, 0, 0), Vector3(0, 0, 0))
	var end_ok := p.size() >= 1 and (absf(p[p.size() - 1].x) > 6.0 or absf(p[p.size() - 1].z) > 6.0)
	check("a goal inside a closed ring ends outside it, as close as possible", end_ok)

	# --- a gap between two walls: class 0.6 fits through 2 m, class 1.2 does not
	fresh()
	add_body(box(1.0, 2.0, 20.0), Vector3(0, 1, -11.0))
	add_body(box(1.0, 2.0, 20.0), Vector3(0, 1, 11.0))
	g = build()
	check("a 2 m gap lets an ordinary walker through", g.line_clear(a, b, 0.6))
	check("and stops a big one", not g.line_clear(a, b, 1.2))
	p = g.find_path(a, b, 1.2)
	check("the big one finds no way through the gap (goes around the 40 m long wall or ends short)", p.is_empty() or path_length(p, a) > 60.0 or p[p.size() - 1].distance_to(b) > 1.0)

	# --- things above or below the walking band do not block
	fresh()
	add_body(box(100.0, 2.0, 100.0), Vector3(0, -1.0, 0))             # the ground: top at y = 0
	add_body(box(10.0, 0.5, 10.0), Vector3(0, 3.0, 0))                # a roof / deck above head height
	g = build()
	check("the ground box and a roof do not block", not g.blocked(Vector3(0, 0, 0)) and g.shape_count == 0)

	# --- layers and the nav_ignore mark
	fresh()
	add_body(box(4.0, 2.0, 4.0), Vector3(0, 1, 0), 0.0, 2)              # layer 2: not the world
	var marked := add_body(box(4.0, 2.0, 4.0), Vector3(20, 1, 0))
	marked.set_meta("nav_ignore", true)
	g = build()
	check("only layer 1 bodies without nav_ignore count", g.shape_count == 0)

	# --- trimeshes: a wall blocks, a flat floor does not
	fresh()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(1.0, 2.0, 20.0)
	add_body(wall_mesh.create_trimesh_shape(), Vector3(0, 1, 0))
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(10, 10)
	add_body(floor_mesh.create_trimesh_shape(), Vector3(30, 0.8, 30))
	g = build()
	check("a trimesh wall blocks", g.blocked(Vector3(0, 0, 0)) and not g.line_clear(a, b))
	check("a flat trimesh floor in the band does not", not g.blocked(Vector3(30, 0, 30)))

	# --- regions
	NavGrid.clear_regions()
	NavGrid.set_region("test", g)
	check("a position inside the rectangle finds its grid", NavGrid.at(Vector3(0, 0, 0)) == g and NavGrid.region("test") == g)
	check("outside every region there is none", NavGrid.at(Vector3(500, 0, 0)) == null)
	NavGrid.clear_regions()
	check("clearing forgets them", NavGrid.at(Vector3(0, 0, 0)) == null)

	# --- worker threads: nothing is known until a class is ready, then the same answers
	fresh()
	add_body(box(1.0, 2.0, 20.0), Vector3(0, 1, 0))
	var tg := NavGrid.build([holder], Rect2(-50, -50, 100, 100))
	tg.prepare(true)
	check("before a class is ready the line is 'clear' and there is no path", (tg.is_ready() or tg.line_clear(a, b)) and (tg.is_ready() or tg.find_path(a, b).is_empty()))
	var waited := 0.0
	while not (tg.is_ready(0.6) and tg.is_ready(1.2)) and waited < 20.0:
		await create_timer(0.1).timeout
		waited += 0.1
	check("the threaded classes become ready (%.1f s)" % waited, tg.is_ready(0.6) and tg.is_ready(1.2))
	check("and then block like the others", not tg.line_clear(a, b) and tg.find_path(a, b).size() >= 2)

	# --- a debug picture can be made
	var img := g.debug_image(0.6, p)
	check("the debug image has one pixel per fine cell", img.get_width() == 200 and img.get_height() == 200)

	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)


func _max_abs_z(path: PackedVector3Array) -> float:
	var m := 0.0
	for p in path:
		m = maxf(m, absf(p.z))
	return m

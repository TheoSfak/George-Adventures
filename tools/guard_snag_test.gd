extends SceneTree
## A guard that is stuck behind a prop sidesteps left or right until it is free:
##   godot --path . --headless --script tools/guard_snag_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _box(parent: Node, pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = pos
	parent.add_child(body)
	return body


## Puts a guard at `start`, its post at `home` (nothing to fight) and returns the seconds it needs to get
## within 1.5 m of home, or -1 when it does not arrive in 14 s.
func walk_home(arena: Node, start: Vector3, home: Vector3) -> float:
	var guard = (load("res://scripts/guard.gd") as GDScript).new()
	guard.home = home
	arena.add_child(guard)
	guard.global_position = start
	var t := 0.0
	var result := -1.0
	while t < 14.0:
		await physics_frame
		t += 1.0 / 60.0
		var d := Vector2(guard.global_position.x - home.x, guard.global_position.z - home.z).length()
		if d < 1.5:
			result = t
			break
	guard.queue_free()
	return result


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()                                 # nothing for the guard to chase
	# a flat arena far from the village: a floor and walls of different widths
	var arena := Node3D.new()
	root.add_child(arena)
	arena.position = Vector3(8000, 0, 8000)
	_box(arena, Vector3(0, -0.5, 0), Vector3(200, 1, 200))
	var start := Vector3(8000, 0.05, 8000)

	# 1. a free walk: the sidestep must not get in the way
	var t_free := await walk_home(arena, start, start + Vector3(0, 0, -12))
	check("a free walk of 12 m arrives (%.1f s)" % t_free, t_free > 0.0)

	# 2. a wall 12 m wide straight in the way: needs a sidestep of 6 m or more to one side
	_box(arena, Vector3(0, 1.5, -6), Vector3(12, 3, 1))
	var t_wall := await walk_home(arena, start, start + Vector3(0, 0, -14))
	check("a wall 12 m wide straight ahead is walked around (%.1f s)" % t_wall, t_wall > 0.0)

	# 3. a dead end: a wall with two short side walls; the first sidestep side is blocked
	_box(arena, Vector3(6.5, 1.5, -4.5), Vector3(1, 3, 4))      # a spur on the right of the wall
	var t_spur := await walk_home(arena, start, start + Vector3(0, 0, -14))
	check("a spur on one side still gets the guard around (%.1f s)" % t_spur, t_spur > 0.0)

	# 4. the same wall and spur with a navigation grid (nav_grid.gd): the guard plans its way round, no guessing of a side
	var grid := NavGrid.build([arena], Rect2(7950, 7950, 100, 100))
	grid.prepare()
	NavGrid.set_region("arena", grid)
	var t_nav := await walk_home(arena, start, start + Vector3(0, 0, -14))
	check("with a navigation grid the guard walks round the wall and the spur (%.1f s)" % t_nav, t_nav > 0.0 and t_nav < 9.0)
	NavGrid.clear_regions()
	quit(1 if failed else 0)

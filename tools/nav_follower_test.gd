extends SceneTree
## NavFollower with real physics: walkers (capsule bodies) behind a wall find their way round it:
##   godot --path . --headless --script tools/nav_follower_test.gd
var failed := false
var holder: Node3D


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


class Walker extends CharacterBody3D:
	var goal := Vector3.ZERO
	var follower := NavFollower.new()
	var clearance := 0.6
	var speed := 5.0
	var used_path := false
	var max_abs_z := 0.0
	var straight_only := false
	var age := 0.0
	var arrived_at := -1.0

	func _physics_process(delta: float) -> void:
		age += delta
		if arrived_at < 0.0 and Vector2(goal.x - global_position.x, goal.z - global_position.z).length() <= 1.5:
			arrived_at = age
		if not is_on_floor():
			velocity.y -= 22.0 * delta
		var dir := Vector3.ZERO
		if Vector2(goal.x - global_position.x, goal.z - global_position.z).length() > 1.0:
			if straight_only:
				dir = Vector3(goal.x - global_position.x, 0.0, goal.z - global_position.z).normalized()
			else:
				dir = follower.direction(global_position, goal, clearance, delta)
		used_path = used_path or follower.active
		max_abs_z = maxf(max_abs_z, absf(global_position.z))
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		move_and_slide()


func add_static(shape: Shape3D, pos: Vector3, yaw := 0.0) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	holder.add_child(body)
	body.global_position = pos
	body.rotation.y = yaw


func box(x: float, y: float, z: float) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = Vector3(x, y, z)
	return b


func add_walker(pos: Vector3, goal: Vector3, straight := false) -> Walker:
	var w := Walker.new()
	w.collision_layer = 4
	w.collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	w.add_child(cs)
	w.goal = goal
	w.straight_only = straight
	holder.add_child(w)
	w.global_position = pos + Vector3(0, 0.05, 0)
	return w


func reset_world(with_wall: bool) -> void:
	if holder != null:
		holder.queue_free()
		await process_frame
	NavGrid.clear_regions()
	holder = Node3D.new()
	root.add_child(holder)
	add_static(box(200.0, 2.0, 200.0), Vector3(0, -1.0, 0))               # the ground, top at y = 0
	if with_wall:
		add_static(box(1.0, 3.0, 24.0), Vector3(0, 1.5, 0))                # a wall across x = 0, z -12 .. 12
	var grid := NavGrid.build([holder], Rect2(-60, -60, 120, 120))
	grid.prepare()
	NavGrid.set_region("test", grid)


func run_until(walkers: Array, seconds: float) -> void:
	var frames := int(seconds * 60.0)
	for f in frames:
		await physics_frame
		var done := true
		for w in walkers:
			if Vector2((w as Walker).goal.x - w.global_position.x, (w as Walker).goal.z - w.global_position.z).length() > 1.5:
				done = false
		if done:
			return


func _run() -> void:
	await process_frame
	# --- a wall: the walker finds the end of it, the straight walker does not
	await reset_world(true)
	var w := add_walker(Vector3(-10, 0, 0), Vector3(10, 0, 0))
	var stuck := add_walker(Vector3(-10, 0, 1), Vector3(10, 0, 1), true)
	await run_until([w], 14.0)
	var reached := Vector2(w.goal.x - w.global_position.x, w.goal.z - w.global_position.z).length() <= 1.5
	check("a walker behind a 24 m wall reaches the goal on the other side", reached)
	check("it walked a path (not straight) and went round the end of the wall", w.used_path and w.max_abs_z > 11.5)
	check("a walker that goes straight is still stuck at the wall", stuck.global_position.x < -0.5)

	# --- a free line: no path is followed
	await reset_world(false)
	w = add_walker(Vector3(-10, 0, 0), Vector3(10, 0, 0))
	await run_until([w], 8.0)
	reached = Vector2(w.goal.x - w.global_position.x, w.goal.z - w.global_position.z).length() <= 1.5
	check("on open ground it walks straight to the goal", reached and not w.used_path and w.max_abs_z < 0.5)

	# --- a crowd takes turns with the path searches and everybody arrives
	await reset_world(true)
	var crowd: Array = []
	for i in 40:
		crowd.append(add_walker(Vector3(-12 - float(i % 5) * 1.5, 0, float(i / 5) * 2.0 - 8.0), Vector3(14, 0, float(i / 5) * 1.0 - 4.0)))
	var t0 := Time.get_ticks_msec()
	await run_until(crowd, 40.0)
	var arrived := 0
	for c in crowd:
		if Vector2((c as Walker).goal.x - c.global_position.x, (c as Walker).goal.z - c.global_position.z).length() <= 2.5:
			arrived += 1
	check("40 walkers behind the wall all get across (%d)" % arrived, arrived >= 38)
	print("  wall time of the crowd run: %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	var latest := 0.0
	var earliest := 999.0
	for c in crowd:
		latest = maxf(latest, (c as Walker).arrived_at)
		earliest = minf(earliest, (c as Walker).arrived_at if (c as Walker).arrived_at > 0.0 else 999.0)
	print("  arrival times: first %.1f s, last %.1f s" % [earliest, latest])

	# --- no grid: straight, as before
	NavGrid.clear_regions()
	var f := NavFollower.new()
	var d := f.direction(Vector3(0, 0, 0), Vector3(10, 0, 0), 0.6, 0.016)
	check("without a grid the direction is the straight one", d.is_equal_approx(Vector3(1, 0, 0)) and not f.active)

	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)

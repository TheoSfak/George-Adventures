extends SceneTree
## The navigation grid of the real village: godot --path . --headless --script tools/nav_world_test.gd -- <outdir>
var out := "."
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var t0 := Time.get_ticks_msec()
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	var grid := NavGrid.region("village")
	check("the village registered a grid", grid != null)
	if grid == null:
		quit(1)
		return
	var waited := 0.0
	while not (grid.is_ready(0.6) and grid.is_ready(1.2)) and waited < 30.0:
		await create_timer(0.1).timeout
		waited += 0.1
	check("both clearance classes are ready (%.1f s after the world, %d shapes, rect %s)" % [waited, grid.shape_count, str(grid.rect)], grid.is_ready(0.6) and grid.is_ready(1.2))
	check("a few hundred obstacles were read", grid.shape_count > 500)
	await create_timer(1.0).timeout

	# --- the well is in the middle of the square, a few things stand around it
	var well := Vector3(0, 0, 0)
	var start_fine_free := not grid.blocked(Vector3(0, 0, 16.0))
	check("the spawn point of George (0, 16) is free ground", start_fine_free)

	# --- every enemy spawn, and the four gates, reach the well
	var enemies_data = load("res://scripts/enemies.gd")
	var unreachable := 0
	var checked := 0
	var total_len := 0.0
	var worst := 0.0
	for s in enemies_data.SPAWNS:
		var pos := Vector3(float(s[1]), 0.0, float(s[2]))
		if not grid.rect.has_point(Vector2(pos.x, pos.z)):
			continue
		var path := grid.find_path(pos, Vector3(0, 0, 16.0))
		checked += 1
		if path.is_empty():
			unreachable += 1
			print("  no path from ", pos)
			continue
		var len_p := 0.0
		var prev := pos
		for w in path:
			len_p += prev.distance_to(w)
			prev = w
		total_len += len_p
		worst = maxf(worst, len_p / maxf(pos.distance_to(Vector3(0, 0, 16.0)), 1.0))
	check("every enemy spawn has a path to the square (%d checked, %d without)" % [checked, unreachable], checked > 20 and unreachable == 0)
	print("  worst path / straight line ratio: %.2f" % worst)
	check("no path is absurdly longer than the straight line (ratio < 3)", worst < 3.0)
	for gate in [Vector3(150, 0, 0), Vector3(-150, 0, 0), Vector3(0, 0, 150), Vector3(0, 0, -150)]:
		var p := grid.find_path(gate, Vector3(0, 0, 16.0))
		check("a march from %s reaches the square" % str(gate), not p.is_empty())

	# --- a picture of the grid with one route drawn on it
	var route := grid.find_path(Vector3(-140, 0, -90), Vector3(0, 0, 16.0))
	var img := grid.debug_image(0.6, route)
	DirAccess.make_dir_recursive_absolute(out)
	img.save_png("%s/nav_village.png" % out)
	var from_start := (Time.get_ticks_msec() - t0) / 1000.0
	print("  total test time %.1f s" % from_start)
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)

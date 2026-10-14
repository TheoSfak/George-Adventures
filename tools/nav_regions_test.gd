extends SceneTree
## The navigation grids of the catacombs and the Frontier: godot --path . --headless --script tools/nav_regions_test.gd -- catacombs|frontier [outdir]
## Every creature spawn must reach the entry; a picture of the grid is saved.
var failed := false
var which := "catacombs"
var out := "."


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		which = a[0]
	if a.size() > 1:
		out = a[1]
	_run()


func _run() -> void:
	await process_frame
	var q := root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	p._invulnerable = 99999.0
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	var interiors = get_first_node_in_group("interiors")
	var spot: InteractSpot = null
	var level = null
	var entry: Vector3
	var spawns: Array
	var wp: Callable
	if which == "catacombs":
		level = load("res://scripts/catacombs.gd")
		q.state["king"] = q.S.DONE
		q._refresh_availability()
		q.state["descent"] = q.S.ACTIVE
		q.changed.emit()
		for n in get_nodes_in_group("interactables"):
			if n is InteractSpot and n.global_position.distance_to(Vector3(0, 0, -188)) < 4.0:
				spot = n
		entry = level.wp(level.ENTRY_SPAWN.x, level.ENTRY_SPAWN.y, 0.05)
		spawns = level.SPAWNS
		wp = func(s): return level.wp(float(s[1]), float(s[2]), 0.0)
	else:
		level = load("res://scripts/frontier.gd")
		q.state["f_gate"] = q.S.ACTIVE
		for n in get_nodes_in_group("interactables"):
			if n is InteractSpot and n.global_position.distance_to(level.VILLAGE_GATE + Vector3(0, 0, 3)) < 2.0:
				spot = n
		entry = level.wp(level.ENTRY.x, level.ENTRY.y, 0.05)
		spawns = level.SPAWNS
		wp = func(s): return level.wp(float(s[1]), float(s[2]), 0.0)
	check("found the way in", spot != null)
	if spot == null:
		quit(1)
		return
	p.teleport(spot.global_position + Vector3(0, 0.05, 2.0), PI)
	spot.interact(p)
	var grid: NavGrid = null
	for i in 300:
		await create_timer(0.1).timeout
		grid = NavGrid.region(which)
		if grid != null and grid.is_ready(0.6) and grid.is_ready(1.2) and (interiors.is_inside() or interiors.in_region()):
			break
	check("%s has a navigation grid, ready (%d shapes, %s)" % [which, grid.shape_count if grid else 0, str(grid.rect) if grid else "-"], grid != null and grid.is_ready(0.6) and grid.is_ready(1.2))
	if grid == null:
		quit(1)
		return
	check("the entry point is free ground", not grid.blocked(entry))
	var without := 0
	var checked := 0
	var worst := 0.0
	for s in spawns:
		var pos: Vector3 = wp.call(s)
		if not grid.rect.has_point(Vector2(pos.x, pos.z)):
			print("  spawn outside the grid: ", s)
			without += 1
			continue
		checked += 1
		var path := grid.find_path(pos, entry)
		var last_ok := not path.is_empty() and Vector2(path[path.size() - 1].x - entry.x, path[path.size() - 1].z - entry.z).length() < 3.0
		if not last_ok:
			without += 1
			print("  no full path from ", s, " to the entry")
			continue
		var length := 0.0
		var prev := pos
		for w in path:
			length += prev.distance_to(w)
			prev = w
		worst = maxf(worst, length / maxf(pos.distance_to(entry), 1.0))
	check("every creature spawn reaches the entry (%d checked, %d without)" % [checked, without], checked > 10 and without == 0)
	print("  worst path / straight ratio %.2f" % worst)
	DirAccess.make_dir_recursive_absolute(out)
	grid.debug_image(0.6).save_png("%s/nav_%s.png" % [out, which])
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)

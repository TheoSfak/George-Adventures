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
	check("eight bridges", bl.size() == 8)
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
	check("the causeway is gentle (%.3f) and climbs from 3.0 to 7.0" % TreeMeshes.max_slope(rline), TreeMeshes.max_slope(rline) < 0.15 and is_equal_approx(rline[0].y, 3.0) and is_equal_approx(rline[rline.size() - 1].y, 7.0))

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

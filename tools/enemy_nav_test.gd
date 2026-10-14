extends SceneTree
## Skeletons in the real village get around houses: one behind a big house chases George on the other side, an
## invader marches from a gate to the well:
##   godot --path . --headless --script tools/enemy_nav_test.gd
## (about 90 s: the march is real time)
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


## The biggest house-sized box collider on open ground: [center, half extents (x, z)].
func find_house(village: Node) -> Dictionary:
	var best := {}
	var best_area := 0.0
	for body in village.find_children("*", "StaticBody3D", true, false):
		var sb := body as StaticBody3D
		if sb.collision_layer & 1 == 0:
			continue
		for c in sb.get_children():
			var cs := c as CollisionShape3D
			if cs == null or not (cs.shape is BoxShape3D):
				continue
			var size := (cs.shape as BoxShape3D).size
			var xf := cs.global_transform
			var gsize := Vector3(size.x * xf.basis.x.length(), size.y * xf.basis.y.length(), size.z * xf.basis.z.length())
			# axis aligned, tall enough and big enough to be a house, not the ground
			if gsize.y < 3.0 or gsize.x < 7.0 or gsize.z < 7.0 or gsize.x > 30.0 or gsize.z > 30.0:
				continue
			if absf(xf.basis.x.normalized().x) < 0.999:
				continue
			var center := xf.origin
			if Vector2(center.x, center.z).length() < 15.0 or Vector2(center.x, center.z).length() > 120.0:
				continue
			if gsize.x * gsize.z > best_area:
				best_area = gsize.x * gsize.z
				best = {"center": center, "half": Vector2(gsize.x, gsize.z) * 0.5}
	return best


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var village := main.get_node("Village")
	var p := get_first_node_in_group("player") as Player
	var spawner := get_first_node_in_group("enemy_spawner")
	p._invulnerable = 99999.0
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.3).timeout
	var grid := NavGrid.region("village")
	check("the village grid is ready", grid != null and grid.is_ready(0.6))

	# --- a skeleton behind a house
	var house := find_house(village)
	check("found a house to hide behind", not house.is_empty())
	var c: Vector3 = house["center"]
	var half: Vector2 = house["half"]
	print("  house at ", c, " half extents ", half)
	var george_at := Vector3(c.x + half.x + 3.0, 0.05, c.z)
	var skeleton_at := Vector3(c.x - half.x - 3.0, 0.05, c.z)
	check("both spots are free ground", not grid.blocked(george_at) and not grid.blocked(skeleton_at))
	p.global_position = george_at
	p.velocity = Vector3.ZERO
	var e: Enemy = spawner.spawn_extra("warrior", skeleton_at)
	e.aggro_range = 60.0
	e.leash_range = 90.0
	e.global_position = skeleton_at
	var start_dist := e.global_position.distance_to(p.global_position)
	var arrived_after := -1.0
	for i in 20 * 60:
		await physics_frame
		p.global_position = george_at
		p.velocity = Vector3.ZERO
		if Vector2(e.global_position.x - george_at.x, e.global_position.z - george_at.z).length() < 3.0:
			arrived_after = i / 60.0
			break
	check("the skeleton reaches George round the house (%.1f s, %.0f m apart, house %.0f x %.0f m)" % [arrived_after, start_dist, half.x * 2.0, half.y * 2.0], arrived_after > 0.0)
	e.queue_free()
	await create_timer(0.3).timeout

	# --- the same without the grid: the old behaviour (information only)
	NavGrid.clear_regions()
	p.global_position = george_at
	var e2: Enemy = spawner.spawn_extra("warrior", skeleton_at)
	e2.aggro_range = 60.0
	e2.leash_range = 90.0
	e2.global_position = skeleton_at
	var old_after := -1.0
	for i in 20 * 60:
		await physics_frame
		p.global_position = george_at
		p.velocity = Vector3.ZERO
		if Vector2(e2.global_position.x - george_at.x, e2.global_position.z - george_at.z).length() < 3.0:
			old_after = i / 60.0
			break
	print("  without the grid the skeleton needs: ", ("%.1f s" % old_after) if old_after > 0.0 else "more than 20 s (stuck)")
	e2.queue_free()
	NavGrid.set_region("village", grid)
	await create_timer(0.3).timeout

	# --- an invader marches from a gate to the well
	p.global_position = Vector3(0, 0.05, 90)            # far enough that he does not notice George
	var inv: Enemy = spawner.spawn_invader("warrior", Vector3(120, 0.05, 0), Vector3(0, 0, 0))
	var marched := -1.0
	for i in 70 * 60:
		await physics_frame
		p.global_position = Vector3(0, 0.05, 90)
		if Vector2(inv.global_position.x, inv.global_position.z).length() < 8.0:
			marched = i / 60.0
			break
	check("an invader marches 120 m to the well (%.1f s)" % marched, marched > 0.0)

	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)

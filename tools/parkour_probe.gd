extends SceneTree

var passed := 0
var failed := 0

func check(desc: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("  PASS: %s" % desc)
	else:
		failed += 1
		print("  FAIL: %s" % desc)

func _initialize() -> void:
	_run()

func _run() -> void:
	print("--- Running Comprehensive Parkour Collision & Traversal Test ---")
	await process_frame

	var main_scene = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main_scene)
	await create_timer(1.2).timeout

	var player = main_scene.find_child("Player", true, false) as Player
	var village = main_scene.find_child("Village", true, false)
	var parkour = village.find_child("ParkourCourse", true, false) as ParkourCourse
	var space_state = player.get_world_3d().direct_space_state

	check("Player exists in scene", player != null)
	check("Village exists in scene", village != null)
	check("ParkourCourse exists in village", parkour != null)

	# 1. Collision-Free Raycast Verification on all stages
	print("\n[1] Raycast Collision Audit against Building Hitboxes...")
	var test_points: Dictionary = {
		"Start Plinth": Vector3(-49.5, 0.1, -1.0),
		"Step 1": Vector3(-49.5, 0.5, -2.5),
		"Step 4": Vector3(-49.5, 1.8, -7.0),
		"Step 8": Vector3(-49.5, 3.6, -13.0),
		"Ascent Terrace": Vector3(-49.5, 4.1, -15.0),
		"Checkpoint 1": Vector3(-60.0, 4.6, -18.5),
		"Canopy Oak Deck": Vector3(-54.0, 5.2, -28.5),
		"Checkpoint 2": Vector3(-41.0, 6.2, -40.5),
		"Jump Pad 1": Vector3(-34.0, 6.2, -41.0),
		"Checkpoint 3": Vector3(-9.5, 12.1, -48.0),
		"Checkpoint 4": Vector3(-46.0, 12.5, -50.0),
		"Jump Pad 2": Vector3(-84.0, 11.7, -48.0),
		"Checkpoint 5": Vector3(-99.0, 11.8, -46.0),
		"Ascending Beam 2": Vector3(-108.0, 14.5, -52.0),
		"Finish Podium CP 6": Vector3(-108.0, 17.3, -62.0),
		"Acrobat Trophy Chest": Vector3(-108.0, 17.5, -64.2),
		"Return Pad": Vector3(-105.5, 17.3, -60.2),
	}

	for pt_name in test_points.keys():
		var pt: Vector3 = test_points[pt_name]
		var query = PhysicsRayQueryParameters3D.create(pt + Vector3(0, 25, 0), pt - Vector3(0, 2, 0), 1)
		var hit = space_state.intersect_ray(query)
		var hit_building := false
		var hit_name := "none"
		if not hit.is_empty():
			var collider = hit.collider
			var parent = collider.get_parent()
			hit_name = parent.name if parent else collider.name
			if hit_name.begins_with("building_"):
				hit_building = true
		check("%s has zero building collider overlap (hit: %s)" % [pt_name, hit_name], not hit_building)

	# 2. Start Area Triggering & Stair Climbing
	print("\n[2] Testing Start Area Trigger & Stair Climbing...")
	check("Parkour initially in IDLE state", parkour.state == ParkourCourse.State.IDLE)
	player.global_position = Vector3(-49.5, 0.1, -1.0)
	await create_timer(0.3).timeout
	check("Stepping on start plinth starts parkour", parkour.state == ParkourCourse.State.RUNNING)
	check("Elapsed time begins counting", parkour.elapsed_time > 0.0)
	check("No false fall trigger at start zone", parkour.current_checkpoint == 0)

	# Simulate climbing each step of the staircase up to the landing terrace
	var step_zs: Array[float] = [-2.5, -4.0, -5.5, -7.0, -8.5, -10.0, -11.5, -13.0]
	for i in step_zs.size():
		var h: float = (i + 1) * 0.45
		player.global_position = Vector3(-49.5, h + 0.1, step_zs[i])
		await create_timer(0.08).timeout
		check("Stood safely on Step %d (Y=%.2f)" % [i + 1, player.global_position.y], player.global_position.y >= h)

	player.global_position = Vector3(-49.5, 4.15, -15.0)
	await create_timer(0.1).timeout
	check("Reached Ascent Terrace (Y=%.2f)" % player.global_position.y, player.global_position.y >= 4.0)

	# 3. Checkpoint Traversal Simulation
	print("\n[3] Testing Checkpoint Traversal & Jump Pads...")
	player.global_position = Vector3(-60.0, 4.7, -18.5) # CP 1
	await create_timer(0.25).timeout
	check("Reached Checkpoint 1", parkour.current_checkpoint == 1)

	player.global_position = Vector3(-41.0, 6.3, -40.5) # CP 2
	await create_timer(0.25).timeout
	check("Reached Checkpoint 2", parkour.current_checkpoint == 2)

	# Step on Jump Pad 1
	player.global_position = Vector3(-34.0, 6.3, -41.0)
	await create_timer(0.15).timeout
	check("Jump Pad 1 triggers and launches player upward", player.velocity.y > 15.0)
	check("Jump Pad 1 imparts forward kick x towards church", player.velocity.x > 10.0)

	player.global_position = Vector3(-9.5, 12.2, -48.0) # CP 3
	await create_timer(0.25).timeout
	check("Reached Checkpoint 3", parkour.current_checkpoint == 3)

	player.global_position = Vector3(-46.0, 12.6, -50.0) # CP 4
	await create_timer(0.25).timeout
	check("Reached Checkpoint 4", parkour.current_checkpoint == 4)

	# Step on Jump Pad 2
	player.global_position = Vector3(-84.0, 11.8, -48.0)
	await create_timer(0.15).timeout
	check("Jump Pad 2 triggers and launches player upward", player.velocity.y > 14.0)

	player.global_position = Vector3(-99.0, 11.9, -46.0) # CP 5
	await create_timer(0.25).timeout
	check("Reached Checkpoint 5", parkour.current_checkpoint == 5)

	player.global_position = Vector3(-108.0, 17.4, -62.0) # CP 6
	await create_timer(0.25).timeout
	check("Reached Checkpoint 6", parkour.current_checkpoint == 6)

	check("Reaching CP 6 finishes course", parkour.state == ParkourCourse.State.FINISHED)
	check("Trophy Chest is valid and accessible", is_instance_valid(parkour._trophy_chest))

	# 4. Return Pad Trigger
	print("\n[4] Testing Return Pad Teleport...")
	player.global_position = Vector3(-105.5, 17.4, -60.2)
	await create_timer(0.3).timeout
	var dist_to_well: float = player.global_position.distance_to(Vector3(0.0, 0.5, 5.0))
	check("Return pad safely teleports player to village well square", dist_to_well < 2.0)

	print("\n==================================================")
	print("Summary: %d Passed, %d Failed" % [passed, failed])
	print("==================================================")

	main_scene.queue_free()
	quit(0 if failed == 0 else 1)

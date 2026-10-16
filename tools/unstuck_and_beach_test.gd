extends SceneTree

var _passed := 0
var _failed := 0

func _init() -> void:
	print("--- Running Unstuck & Beach Water Verification Suite ---")
	call_deferred("_run")

func _check(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("  PASS: %s" % msg)
	else:
		_failed += 1
		printerr("  FAIL: %s" % msg)

func _run() -> void:
	if not root.has_node("Quests"):
		var q_inst = (load("res://scripts/quests.gd") as GDScript).new()
		q_inst.name = "Quests"
		root.add_child(q_inst)
	var save = load("res://scripts/save_game.gd")
	save.menu_in_tests = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	var player = main.get_node_or_null("Player") as Player
	_check(player != null, "Player exists in main scene")
	if not player:
		quit(1)
		return

	var space := main.get_viewport().world_3d.direct_space_state

	# Test 1: No invisible 8m wall at X = -18, Z = 72
	var from_hill := Vector3(-18.0, 15.0, 72.0)
	var to_hill := Vector3(-18.0, -15.0, 72.0)
	var q_hill := PhysicsRayQueryParameters3D.create(from_hill, to_hill, 1)
	var res_hill := space.intersect_ray(q_hill)
	_check(not res_hill.is_empty(), "Ground exists at X=-18, Z=72")
	if not res_hill.is_empty():
		_check(res_hill["position"].y < 1.0, "Rolling hill cylinder wall removed (height is %.2f <= 1.0)" % res_hill["position"].y)

	# Test 2: Watertight ground collision across beach Z=84 to 160
	var beach_misses := 0
	for z in range(85, 160, 5):
		for x in [-50.0, -35.0, -18.0, 0.0, 20.0]:
			var from := Vector3(x, 15.0, float(z))
			var to := Vector3(x, -15.0, float(z))
			var q := PhysicsRayQueryParameters3D.create(from, to, 1)
			var res := space.intersect_ray(q)
			if res.is_empty():
				beach_misses += 1
				printerr("Void miss at X=%s, Z=%s" % [x, z])
	_check(beach_misses == 0, "Watertight beach collision: 0 misses out of 75 raycasts across Z=85..155")

	# Close title menu so physics can run
	var menu := main.get_node_or_null("Menu") as GameMenu
	if menu:
		menu._close_menu()
		paused = false

	# Test 3: Pier jumping into sea lands on solid seabed
	player.global_position = Vector3(-31.0, 1.0, 120.0) # jumping off east side of pier into sea
	player.velocity = Vector3(2.0, 0.0, 0.0)
	for f in 40:
		await physics_frame
	_check(player.is_on_floor(), "Player landed on floor after jumping into sea (is_on_floor == true)")
	_check(player.global_position.y >= -1.2 and player.global_position.y <= 0.2, "Player safely standing on seabed at Y=%.2f" % player.global_position.y)

	# Test 4: Unstuck method functionality
	var msg_box := [""]
	player.message.connect(func(t: String): msg_box[0] = t)
	player.unstuck()
	await physics_frame
	_check(player.global_position.distance_to(player._spawn_point) < 1.0, "Unstuck teleported player to village center spawn point")
	_check(player.velocity == Vector3.ZERO, "Unstuck reset velocity to ZERO")
	_check(not player.busy, "Unstuck cleared busy flag")
	_check(not player.is_dead, "Unstuck ensured player is alive")
	_check(msg_box[0] == Strings.MSG_UNSTUCK, "Unstuck emitted Greek notification: '%s'" % msg_box[0])

	# Test 5: GameMenu pause page has Unstuck button
	_check(menu != null, "GameMenu node exists in main scene")
	if menu:
		menu._title = false
		menu.toggle_pause()
		await process_frame
		_check(menu._open, "GameMenu pause opened")
		var has_unstuck_btn := false
		for child in menu._box.get_children():
			if child is Button and child.text == Strings.MENU_UNSTUCK:
				has_unstuck_btn = true
				break
		_check(has_unstuck_btn, "GameMenu pause page has 'Ξεκόλλημα (Unstuck)' button")
		menu._unstuck()
		await process_frame
		_check(not menu._open, "Clicking unstuck closed pause menu")

	print("\n==================================================")
	print("Summary: %d Passed, %d Failed" % [_passed, _failed])
	print("==================================================")

	main.queue_free()
	await process_frame
	quit(1 if _failed > 0 else 0)

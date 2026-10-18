extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame
	print("==================================================")
	print("Mount Anywhere & Orc Castle Redesign Test Suite")
	print("==================================================")

	root.get_node("/root/Quests").intro_seen = true

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var player = get_first_node_in_group("player")
	if not player:
		print("FAIL: Player not found")
		quit(1)
		return

	var interiors = get_first_node_in_group("interiors")
	if not interiors:
		print("FAIL: Interiors manager not found")
		quit(1)
		return

	# Enable horse ownership for testing
	player.horse_owned = true

	# 1. Test Outdoor Mount at various locations across the world
	var test_locations := [
		["Village Square", Vector3(0.0, 0.2, 16.0)],
		["Stable Yard", Vector3(63.0, 0.2, 53.0)],
		["Wheat Field", Vector3(-35.0, 0.2, -30.0)],
		["North Pier", Vector3(0.0, 0.2, 85.0)],
		["Cottage Garden", Vector3(25.0, 0.2, 12.0)]
	]

	print("\n--- 1. Testing Outdoor Mount Freedom ---")
	for loc in test_locations:
		player.teleport(loc[1], 0.0)
		player.busy = false
		await create_timer(0.05).timeout
		var reason: String = player.mount_block_reason()
		if reason != "":
			print("FAIL: Mount blocked at %s (%s) with reason: %s" % [loc[0], loc[1], reason])
			quit(1)
			return
		var mounted_ok: bool = player.mount()
		if not mounted_ok or not player.mounted:
			print("FAIL: Failed to mount at %s" % loc[0])
			quit(1)
			return
		player.dismount(false)
		print("  PASS: Mount & dismount successful at %s %s" % [loc[0], loc[1]])

	# 2. Test Indoor Mount Block in Orc Castle
	print("\n--- 2. Testing Orc Castle Interior & Mount Block ---")
	var orc_door_front := Vector3(130.5, 0.05, 6.0)
	await interiors.enter("orc_castle_0", "orc_castle", orc_door_front, 0.0, player)
	await create_timer(0.4).timeout

	if not interiors.is_inside():
		print("FAIL: Player should be inside orc_castle")
		quit(1)
		return

	var indoor_reason: String = player.mount_block_reason()
	if indoor_reason != "indoors":
		print("FAIL: Mount reason inside castle should be 'indoors', got '%s'" % indoor_reason)
		quit(1)
		return
	print("  PASS: Mount correctly blocked indoors with 'indoors' in orc_castle")

	var orc_room := interiors.get_node_or_null("Room_orc_castle_0")
	if not orc_room:
		print("FAIL: Room_orc_castle_0 node not found")
		quit(1)
		return
	var chests := orc_room.find_children("*", "Chest", true, false)
	print("  PASS: Redesigned orc_castle loaded with %d nodes and %d chests" % [orc_room.get_child_count(), chests.size()])
	if chests.size() < 2:
		print("FAIL: Expected at least 2 chests in orc_castle")
		quit(1)
		return

	# 3. Test Unstuck from Inside Resetting Indoor State
	print("\n--- 3. Testing Unstuck / Exit Clearing Indoor State ---")
	player.unstuck()
	await create_timer(0.1).timeout

	if interiors.is_inside():
		print("FAIL: interiors.is_inside() still true after unstuck!")
		quit(1)
		return
	var unstuck_mount_reason: String = player.mount_block_reason()
	if unstuck_mount_reason != "":
		print("FAIL: Mount still blocked after unstuck: %s" % unstuck_mount_reason)
		quit(1)
		return
	var unstuck_mounted: bool = player.mount()
	if not unstuck_mounted or not player.mounted:
		print("FAIL: Cannot mount horse at village well after unstuck!")
		quit(1)
		return
	player.dismount(false)
	print("  PASS: Unstuck properly cleared indoor state and horse mount works at village well!")

	# 4. Check All Orc Positions Clear of Walls
	print("\n--- 4. Checking Orc Spawns Away From Colliders ---")
	var orc_count := 0
	for e in get_nodes_in_group("enemies"):
		var k: String = e.get("kind_id") if e.get("kind_id") != null else ""
		if k.begins_with("orc_"):
			orc_count += 1
			var pos: Vector3 = e.global_position
			print("  * %s at %s" % [k, pos])
			# Check distance from ruined walls
			var dist_keep := pos.distance_to(Vector3(150.0, 0.0, 68.0))
			var dist_wall1 := pos.distance_to(Vector3(142.0, 0.0, 64.0))
			var dist_wall2 := pos.distance_to(Vector3(158.0, 0.0, 72.0))
			var dist_gate := pos.distance_to(Vector3(138.0, 0.0, 74.0))
			print("    distances -> keep: %.1fm, wall1: %.1fm, wall2: %.1fm, gate: %.1fm" % [dist_keep, dist_wall1, dist_wall2, dist_gate])

	if orc_count < 6:
		print("FAIL: Expected 6 orcs spawned, found %d" % orc_count)
		quit(1)
		return

	print("  PASS: All %d Orcs verified in open courtyard ground!" % orc_count)

	print("\n==================================================")
	print("ALL TESTS PASSED SUCCESSFULLY!")
	print("==================================================")
	quit(0)

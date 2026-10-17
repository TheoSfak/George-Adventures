extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	await process_frame
	print("==================================================")
	print("Castle Interiors & Exploration Test Suite")
	print("==================================================")

	root.get_node("/root/Quests").intro_seen = true

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var interiors = get_first_node_in_group("interiors")
	if not interiors:
		print("FAIL: Interiors node not found")
		quit(1)
		return
	print("  PASS: Interiors manager found")

	var player = get_first_node_in_group("player")
	if not player:
		print("FAIL: Player not found")
		quit(1)
		return
	print("  PASS: Player found")

	# Check DEFS entries
	for kind in ["tower", "orc_castle", "shadow_castle"]:
		if not interiors.DEFS.has(kind):
			print("FAIL: DEFS missing kind: %s" % kind)
			quit(1)
			return
		var d: Dictionary = interiors.DEFS[kind]
		print("  PASS: DEFS has '%s': size=%s, furniture=%d, chests=%d" % [
			kind, d["size"], d["furniture"].size(), d["chests"].size()
		])

	# Check Greek building names
	for kind in ["tower", "orc_castle", "shadow_castle"]:
		if not Strings.BUILDING_NAMES.has(kind):
			print("FAIL: Strings.BUILDING_NAMES missing kind: %s" % kind)
			quit(1)
			return
		print("  PASS: Strings.BUILDING_NAMES['%s'] = '%s'" % [kind, Strings.BUILDING_NAMES[kind]])

	# Test 1: Enter Guard Castle / Tower of Captain Vasilis
	print("\n--- Testing Guard Castle / Watchtower (tower) ---")
	var tower_outside := Vector3(95.1, 0.0, -78.7)
	player.busy = false
	await interiors.enter("tower_12", "tower", tower_outside, 0.0, player)
	await create_timer(0.4).timeout

	if not interiors.is_inside():
		print("FAIL: Player failed to enter tower")
		quit(1)
		return
	if interiors.current_kind != "tower":
		print("FAIL: Current kind is %s, expected 'tower'" % interiors.current_kind)
		quit(1)
		return
	print("  PASS: Player successfully entered Guard Castle (tower) at %s" % player.global_position)

	# Verify room nodes
	var tower_room := interiors.get_node_or_null("Room_tower_12")
	if not tower_room:
		print("FAIL: Room_tower_12 node not found under Interiors")
		quit(1)
		return
	var tower_chests := tower_room.find_children("*", "Chest", true, false)
	print("  PASS: Room_tower_12 contains %d chests and %d total nodes" % [tower_chests.size(), tower_room.get_child_count()])

	# Exit tower
	player.busy = false
	await interiors._exit_room("tower_12", player)
	await create_timer(0.4).timeout
	if interiors.is_inside():
		print("FAIL: Player still inside after exit")
		quit(1)
		return
	print("  PASS: Player successfully exited Guard Castle back to outside %s" % player.global_position)

	# Test 2: Enter Ruined Orc Stronghold Castle Keep (orc_castle)
	print("\n--- Testing Ruined Orc Stronghold Castle (orc_castle) ---")
	var orc_outside := Vector3(146.5, 0.0, 68.5)
	player.busy = false
	await interiors.enter("orc_castle_0", "orc_castle", orc_outside, deg_to_rad(45.0), player)
	await create_timer(0.4).timeout

	if not interiors.is_inside() or interiors.current_kind != "orc_castle":
		print("FAIL: Player failed to enter orc_castle (inside=%s, kind=%s)" % [interiors.is_inside(), interiors.current_kind])
		quit(1)
		return
	print("  PASS: Player successfully entered Ruined Orc Castle (orc_castle) at %s" % player.global_position)

	var orc_room := interiors.get_node_or_null("Room_orc_castle_0")
	if not orc_room:
		print("FAIL: Room_orc_castle_0 node not found")
		quit(1)
		return
	var orc_chests := orc_room.find_children("*", "Chest", true, false)
	print("  PASS: Room_orc_castle_0 contains %d chests and %d total nodes" % [orc_chests.size(), orc_room.get_child_count()])
	if orc_chests.size() < 2:
		print("FAIL: Expected at least 2 chests in orc_castle")
		quit(1)
		return

	# Exit orc castle
	player.busy = false
	await interiors._exit_room("orc_castle_0", player)
	await create_timer(0.4).timeout
	if interiors.is_inside():
		print("FAIL: Player still inside orc_castle after exit")
		quit(1)
		return
	print("  PASS: Player successfully exited Ruined Orc Castle back to courtyard %s" % player.global_position)

	# Test 3: Enter Fortress of Shadow Keep (shadow_castle)
	print("\n--- Testing Fortress of Shadow Keep (shadow_castle) ---")
	var shadow_outside := Vector3(0.0, 0.0, -160.0)
	player.busy = false
	await interiors.enter("shadow_castle_0", "shadow_castle", shadow_outside, 0.0, player)
	await create_timer(0.4).timeout

	if not interiors.is_inside() or interiors.current_kind != "shadow_castle":
		print("FAIL: Player failed to enter shadow_castle (inside=%s, kind=%s)" % [interiors.is_inside(), interiors.current_kind])
		quit(1)
		return
	print("  PASS: Player successfully entered Fortress of Shadow Keep (shadow_castle) at %s" % player.global_position)

	var shadow_room := interiors.get_node_or_null("Room_shadow_castle_0")
	if not shadow_room:
		print("FAIL: Room_shadow_castle_0 node not found")
		quit(1)
		return
	var shadow_chests := shadow_room.find_children("*", "Chest", true, false)
	print("  PASS: Room_shadow_castle_0 contains %d chests and %d total nodes" % [shadow_chests.size(), shadow_room.get_child_count()])

	# Exit shadow castle
	player.busy = false
	await interiors._exit_room("shadow_castle_0", player)
	await create_timer(0.4).timeout
	if interiors.is_inside():
		print("FAIL: Player still inside shadow_castle after exit")
		quit(1)
		return
	print("  PASS: Player successfully exited Fortress of Shadow Keep back to courtyard %s" % player.global_position)

	print("==================================================")
	print("ALL CASTLE INTERIOR CHECKS PASSED SUCCESSFULLY!")
	print("==================================================")
	quit(0)

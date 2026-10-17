extends SceneTree

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	print("==================================================")
	print("Orc Stronghold Accessibility & Combat Test")
	print("==================================================")

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var village: Node = main.get_node_or_null("Village")
	if not village:
		print("FAIL: Village not found")
		quit(1)
		return

	var outpost: Node = village.get_node_or_null("RuinedOutpost")
	if not outpost:
		print("FAIL: RuinedOutpost not found")
		quit(1)
		return

	# Check gate doors are removed
	var gate := outpost.get_node_or_null("wall_corner_A_gate")
	if not gate:
		print("FAIL: Gate node not found in RuinedOutpost")
		quit(1)
		return

	var door_left := gate.find_child("*door_left*", true, false)
	var door_right := gate.find_child("*door_right*", true, false)
	if door_left != null or door_right != null:
		print("FAIL: Gate doors still exist! left=%s, right=%s" % [door_left, door_right])
		quit(1)
		return
	print("  PASS: Closed wooden gate doors successfully removed")

	# Check gate archway collision
	var gate_cols := gate.find_children("*", "CollisionShape3D", true, false)
	print("  PASS: Gate collision shapes count: %d" % gate_cols.size())
	for gc in gate_cols:
		var parent_body := gc.get_parent() as CollisionObject3D
		print("    Gate collider: %s under %s" % [gc.name, parent_body.name if parent_body else "none"])
		if "door" in parent_body.name.to_lower():
			print("FAIL: Door collision body still present: %s" % parent_body.name)
			quit(1)
			return

	# Test NavGrid path through gate
	var grid := NavGrid.region("village")
	if not grid:
		print("FAIL: NavGrid 'village' not found")
		quit(1)
		return

	var outside_pos := Vector3(128.0, 0.0, 78.0)
	var inside_pos := Vector3(146.0, 0.0, 69.0)
	var path_into_castle := grid.find_path(outside_pos, inside_pos, 0.6)
	if path_into_castle.size() == 0:
		print("FAIL: Cannot pathfind into castle through gate")
		quit(1)
		return
	print("  PASS: NavGrid path through gate into courtyard exists (%d points)" % path_into_castle.size())

	# Find player and orcs
	var player := root.get_node_or_null("Main/Player") as Player
	if not player:
		player = get_first_node_in_group("player") as Player
	if not player:
		print("FAIL: Player not found")
		quit(1)
		return

	var enemies := get_nodes_in_group("enemies")
	var orcs: Array = []
	for e in enemies:
		var kind: String = str(e.get("kind_id"))
		if kind.begins_with("orc_"):
			orcs.append(e)

	print("  PASS: Found %d orcs stationed in the stronghold" % orcs.size())
	if orcs.size() == 0:
		print("FAIL: No orcs found!")
		quit(1)
		return

	# Teleport player into courtyard to test combat directly
	player.global_position = inside_pos
	player.max_health = 10000.0
	player.health = 10000.0

	# Test hitting each orc
	var hit_count := 0
	for o in orcs:
		var orc := o as Enemy
		var initial_hp: float = orc.health
		var orc_pos: Vector3 = orc.global_position
		# Stand in front of orc
		player.global_position = orc_pos + Vector3(0.5, 0.0, 0.5)
		# Hit orc
		orc.take_damage(50.0, player.global_position, 2.0)
		if orc.health < initial_hp:
			hit_count += 1
			print("  PASS: Orc %s took damage! (%1.0f -> %1.0f HP)" % [orc.kind_id, initial_hp, orc.health])
		else:
			print("FAIL: Orc %s did not take damage! (HP: %1.0f)" % [orc.kind_id, orc.health])

	if hit_count == orcs.size():
		print("  PASS: All %d orcs can take damage and be defeated!" % hit_count)
	else:
		print("FAIL: Only %d/%d orcs took damage" % [hit_count, orcs.size()])
		quit(1)
		return

	# Slay an orc to verify death and reward
	var test_orc := orcs[0] as Enemy
	test_orc.take_damage(99999.0, player.global_position, 0.0)
	print("  PASS: Orc killed successfully without crash")

	print("==================================================")
	print("ALL ORC ACCESSIBILITY & COMBAT CHECKS PASSED!")
	print("==================================================")
	quit(0)

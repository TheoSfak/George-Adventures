extends SceneTree
## The zones of the Frontier: dressing, the light budget, the fortress gate:
##   godot --path . --headless --script tools/frontier_build_test.gd
var failed := false
var p: Player
var q: Node
var interiors


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func enter() -> void:
	q.state["f_gate"] = q.S.ACTIVE
	interiors.enter_region("frontier", Vector3(0, 0.05, 20), 0.0, p)
	for i in 120:
		await create_timer(0.1).timeout
		if interiors.in_region() and not p.busy:
			break


func _run() -> void:
	await process_frame
	q = root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	p = get_first_node_in_group("player") as Player
	interiors = get_first_node_in_group("interiors")
	p._invulnerable = 99999.0
	var lights_before := root.find_children("*", "OmniLight3D", true, false).size()
	await enter()
	var level = get_first_node_in_group("frontier")
	check("the level exists", level != null)
	var lights_after := root.find_children("*", "OmniLight3D", true, false).size()
	var region_lights := lights_after - lights_before
	print("   region lights: ", region_lights)
	check("the region stays inside the light budget (%d lights)" % region_lights, region_lights > 6 and region_lights <= 34)
	check("the fortress gate starts sealed", not level._gate_open)
	var barrier := root.find_children("*", "MeshInstance3D", true, false).filter(func(n): return n.is_in_group("frontier_gate"))
	check("a gate barrier is standing", barrier.size() == 1)
	q.state["f_symbols"] = q.S.READY
	q.changed.emit()
	await create_timer(1.5).timeout
	check("the gate opens when the symbols are ready", level._gate_open)
	check("the barrier is gone", root.find_children("*", "MeshInstance3D", true, false).filter(func(n): return n.is_in_group("frontier_gate") and is_instance_valid(n) and not n.is_queued_for_deletion()).is_empty())

	# --- content
	var counts := {}
	for e in get_nodes_in_group("enemies"):
		var k: String = e.kind_id
		counts[k] = int(counts.get(k, 0)) + 1
	print("   enemies by kind: ", counts)
	check("at least 8 shadow knights stand around", int(counts.get("shadow_knight", 0)) >= 8)
	check("at least 5 soul collectors", int(counts.get("soul_collector", 0)) >= 5)
	check("one giant skeleton and one Malakar", int(counts.get("giant_skeleton", 0)) == 1 and int(counts.get("malakar", 0)) == 1)
	var fr = load("res://scripts/frontier.gd")
	for e in get_nodes_in_group("enemies"):
		var local: Vector3 = e.global_position - fr.ORIGIN
		if absf(local.x) > 2000.0:
			continue                                # village skeletons stand thousands of metres away
		check("no enemy in the camp (%s at %s)" % [e.kind_id, str(local)], Vector2(local.x, local.z).length() > fr.CAMP_RADIUS)
	var npc_ids := []
	for n in get_nodes_in_group("npcs"):
		npc_ids.append(n.get("npc_id"))
	check("Ilarion and Elpida stand in the camp", "ilarion" in npc_ids and "elpida" in npc_ids)
	check("5 chests in the region", root.find_children("*", "Chest", true, false).filter(func(c): return c.global_position.x < -5000.0).size() == 5)
	# symbols only show while the quest is active
	var symbols := root.find_children("*", "QuestItem", true, false).filter(func(n): return n.item_id == "symbol")
	check("three Symbols of Shadow lie around", symbols.size() == 3)
	q.state["f_symbols"] = q.S.AVAILABLE
	q.changed.emit()
	check("...hidden before the quest", symbols.all(func(n): return not n.visible))
	q.state["f_symbols"] = q.S.ACTIVE
	q.changed.emit()
	check("...visible while the quest is active", symbols.all(func(n): return n.visible))
	# a boss killed early comes back when its quest starts
	var giant
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "giant_skeleton":
			giant = e
	giant.take_damage(999999.0, p.global_position)
	await create_timer(0.3).timeout
	check("the giant is dead", giant.is_dead())
	q.state["f_wall"] = q.S.ACTIVE
	q.changed.emit()
	await create_timer(0.3).timeout
	var back := 0
	for e in get_nodes_in_group("enemies"):
		if e.kind_id == "giant_skeleton" and not e.is_dead():
			back += 1
	check("the giant is back once f_wall is active", back == 1)
	quit(1 if failed else 0)

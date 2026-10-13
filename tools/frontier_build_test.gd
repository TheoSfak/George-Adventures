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
	quit(1 if failed else 0)

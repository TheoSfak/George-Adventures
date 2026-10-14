extends SceneTree
## The bone totems stand on the ground (not in the air) and not inside a rock, tree or tent:
##   godot --path . --headless --script tools/totem_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func _lowest_y(node: Node3D) -> float:
	var low := INF
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var box := m.global_transform * m.get_aabb()
		low = minf(low, box.position.y)
	return low


func _run() -> void:
	await process_frame
	var q = root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	q.state["totems"] = 2
	q.changed.emit()
	await create_timer(0.3).timeout
	var space: PhysicsDirectSpaceState3D = main.get_viewport().world_3d.direct_space_state
	var shape := CylinderShape3D.new()
	shape.radius = 2.0
	shape.height = 4.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	var totems := get_nodes_in_group("breakables")
	check("three totems", totems.size() == 3)
	for t in totems:
		var where := "(%d, %d)" % [roundi(t.global_position.x), roundi(t.global_position.z)]
		check("totem %s is visible while its quest runs" % where, t.visible)
		var foot: float = _lowest_y(t._visual)
		check("totem %s stands on the ground (foot at %.2f)" % [where, foot], absf(foot - t.global_position.y) < 0.15)
		query.exclude = [t.get_rid()]
		query.transform = Transform3D(Basis.IDENTITY, t.global_position + Vector3(0, 2.5, 0))
		check("totem %s is not inside anything solid" % where, space.intersect_shape(query, 4).is_empty())
	quit(1 if failed else 0)

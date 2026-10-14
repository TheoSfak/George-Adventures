extends SceneTree
## Where the totem model stands (its lowest point) and which spots near each totem are open ground:
##   godot --path . --headless --script tools/totem_probe.gd
func _initialize() -> void:
	_run()


func _aabb(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var local := (node.global_transform.affine_inverse() * m.global_transform) * m.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var model := (load("res://assets/graveyard/post_skull.gltf") as PackedScene).instantiate() as Node3D
	root.add_child(model)
	var box := _aabb(model)
	print("post_skull AABB (model units): min ", box.position, " size ", box.size, " max y ", box.end.y)
	model.queue_free()

	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var space: PhysicsDirectSpaceState3D = main.get_viewport().world_3d.direct_space_state
	var shape := CylinderShape3D.new()
	shape.radius = 3.0
	shape.height = 5.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	var village = main.get_node("Village")
	for t in village.TOTEMS:
		var free: Array[String] = []
		for ring in range(0, 9):
			var steps := 1 if ring == 0 else ring * 8
			for i in steps:
				var a := TAU * float(i) / float(steps)
				var pos := Vector3(t.x + cos(a) * ring * 3.0, 0.0, t.y + sin(a) * ring * 3.0)
				query.transform = Transform3D(Basis.IDENTITY, pos + Vector3(0, 3.5, 0))
				if space.intersect_shape(query, 1).is_empty():
					if free.size() < 6:
						free.append("(%d, %d)" % [roundi(pos.x), roundi(pos.z)])
		print("totem ", t, ": nearest open spots (radius 3): ", ", ".join(free))
	quit()

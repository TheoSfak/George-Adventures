extends SceneTree
## Prints which spots near the northern mountains are open ground (for the Frontier gate):
##   godot --path . --headless --script tools/passgateprobe.gd
func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var shape := BoxShape3D.new()
	shape.size = Vector3(18.0, 6.0, 12.0)         # the gate, its two lamps and room to walk through
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	for z in range(-226, -190, 6):
		var line := "z=%d free x:" % z
		for x in range(-120, 121, 10):
			query.transform = Transform3D(Basis.IDENTITY, Vector3(x, 4.0, z))
			if space.intersect_shape(query, 1).is_empty():
				line += " %d" % x
		print(line)
	quit()

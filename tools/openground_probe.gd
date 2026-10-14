extends SceneTree
## Looks for open ground (no building, prop, path or collider nearby) 66 to 90 m from the well, e.g. for a new yard.
##   godot --path . --headless --script tools/openground_probe.gd
## Prints one line per free spot (angle, radius, x, z). Change the radius list, the 10 m margins or the 6 m sphere to taste.
func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var village = main.get_node("Village")
	var space := root.get_world_3d().direct_space_state
	var found := []
	for deg in range(0, 360, 10):
		for r in [66.0, 74.0, 82.0, 90.0]:
			var a := deg_to_rad(float(deg))
			var p := Vector2(cos(a) * r, sin(a) * r)
			if village.call("_outside_map", p) or village.call("_is_occupied", p.x, p.y, 10.0):
				continue
			if village._terrain.near_path(p, 8.0):
				continue
			var q := PhysicsShapeQueryParameters3D.new()
			var s := SphereShape3D.new()
			s.radius = 6.0
			q.shape = s
			q.collision_mask = 1
			q.transform = Transform3D(Basis.IDENTITY, Vector3(p.x, 7.5, p.y))
			if not space.intersect_shape(q, 1).is_empty():
				continue
			found.append("%d deg r=%d  (%.0f, %.0f)" % [deg, int(r), p.x, p.y])
	print("OPEN SPOTS: ", found.size())
	for f in found:
		print(f)
	quit()

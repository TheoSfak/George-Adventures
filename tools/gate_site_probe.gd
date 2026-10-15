extends SceneTree
## Finds open ground at the edge of the village map (radius 195 to 228 m from the well) for a mountain gate:
##   godot --path . --headless --script tools/gate_site_probe.gd
const ZONES := [Vector2(-175, 20), Vector2(140, 125), Vector2(0, -178), Vector2(172, -40), Vector2(63, 53), Vector2(-70, 108),
		Vector2(-140, -90), Vector2(-80, -140), Vector2(70, -171), Vector2(70, -208), Vector2(0, -188)]


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var space: PhysicsDirectSpaceState3D = main.get_viewport().world_3d.direct_space_state
	var shape := CylinderShape3D.new()
	shape.radius = 9.0
	shape.height = 5.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	var found: Array = []
	for angle in range(0, 360, 4):
		for r in range(190, 232, 3):
			var p := Vector2(cos(deg_to_rad(angle)), sin(deg_to_rad(angle))) * r
			var near := 999.0
			for z in ZONES:
				near = minf(near, p.distance_to(z))
			if near < 45.0:
				continue
			query.transform = Transform3D(Basis.IDENTITY, Vector3(p.x, 3.5, p.y))
			if space.intersect_shape(query, 1).is_empty():
				found.append([angle, r, p, near])
	print("open 9 m discs at the map edge (angle 0 = east, 90 = south): ", found.size())
	var shown := {}
	for f in found:
		var bucket := int(f[0] / 20)
		if shown.has(bucket):
			continue
		shown[bucket] = true
		print("  angle %3d radius %3d -> (%d, %d), %.0f m from the nearest zone" % [f[0], f[1], f[2].x, f[2].y, f[3]])
	quit()

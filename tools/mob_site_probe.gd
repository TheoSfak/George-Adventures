extends SceneTree
## Checks candidate centres for the pumpkin patch and the cult's ritual circle: the largest free disc (metres) around each:
##   godot --path . --headless --script tools/mob_site_probe.gd
const CANDIDATES := [
	Vector2(-30, -135), Vector2(-38, -150), Vector2(128, -52), Vector2(118, -60), Vector2(160, 100), Vector2(170, 100),
	Vector2(110, -48), Vector2(-62, -124), Vector2(-71, -152), Vector2(-80, -150),
]


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
	shape.height = 4.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	for c in CANDIDATES:
		var free_r := 0.0
		for r in range(4, 34, 2):
			shape.radius = float(r)
			query.transform = Transform3D(Basis.IDENTITY, Vector3(c.x, 3.5, c.y))
			if space.intersect_shape(query, 1).is_empty():
				free_r = float(r)
			else:
				break
		print("candidate (%d, %d): free disc radius %.0f m" % [c.x, c.y, free_r])
	quit()

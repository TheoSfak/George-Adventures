extends SceneTree
## Finds open ground (a free disc of 14 m) for a camp, far from every other zone of the map:
##   godot --path . --headless --script tools/bandit_site_probe.gd
const ZONES := [Vector2(-175, 20), Vector2(140, 125), Vector2(0, -178), Vector2(172, -40), Vector2(63, 53),
		Vector2(-70, 108), Vector2(-70, 65), Vector2(0, 0), Vector2(-100, -54), Vector2(95, -79), Vector2(-93, 30),
		Vector2(95, 39), Vector2(0, -59), Vector2(-59, -10), Vector2(59, -12), Vector2(-140, -90)]


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var spawner = get_first_node_in_group("enemy_spawner")
	var spawns: Array = []
	for s in spawner.SPAWNS:
		spawns.append(Vector2(s[1], s[2]))
	var space: PhysicsDirectSpaceState3D = main.get_viewport().world_3d.direct_space_state
	var shape := CylinderShape3D.new()
	shape.radius = 14.0
	shape.height = 4.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	var found: Array = []
	for x in range(-190, 191, 10):
		for z in range(-190, 191, 10):
			var p := Vector2(x, z)
			var d := p.length()
			if d < 85.0 or d > 175.0:
				continue
			var near := 999.0
			for zn in ZONES:
				near = minf(near, p.distance_to(zn))
			if near < 50.0:
				continue
			var near_spawn := 999.0
			for sp in spawns:
				near_spawn = minf(near_spawn, p.distance_to(sp))
			query.transform = Transform3D(Basis.IDENTITY, Vector3(x, 3.5, z))
			if space.intersect_shape(query, 1).is_empty():
				found.append([near_spawn, near, p])
	found.sort_custom(func(a, b): return a[0] > b[0])
	print("open 14 m discs, farthest from skeleton spawns first (spawn dist, zone dist, spot):")
	for i in mini(12, found.size()):
		print("  %.0f m from a spawn, %.0f m from a zone: (%d, %d)" % [found[i][0], found[i][1], found[i][2].x, found[i][2].y])
	quit()

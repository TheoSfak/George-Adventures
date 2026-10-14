extends SceneTree
## The camera: characters close to it fade out, and the spring arm keeps the camera out of the houses:
##   godot --path . --headless --script tools/camera_test.gd
var failed := false


func check(label: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  "), label)
	if not ok:
		failed = true


func _initialize() -> void:
	_run()


func meshes_of(node: Node) -> Array:
	return node.find_children("*", "GeometryInstance3D", true, false)


func max_transparency(node: Node) -> float:
	var m := 0.0
	for g in meshes_of(node):
		m = maxf(m, (g as GeometryInstance3D).transparency)
	return m


func min_transparency(node: Node) -> float:
	var m := 1.0
	for g in meshes_of(node):
		m = minf(m, (g as GeometryInstance3D).transparency)
	return m


## The visual bounds of a house: its meshes (not the colliders) in the frame `frame` (the collider's transform).
func visual_aabb(root_node: Node3D, frame: Transform3D) -> AABB:
	var box := AABB()
	var first := true
	var inverse := frame.affine_inverse()
	for m in root_node.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		var a := (inverse * mi.global_transform) * mi.mesh.get_aabb()
		box = a if first else box.merge(a)
		first = false
	return box


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var spawner := get_first_node_in_group("enemy_spawner")
	p._invulnerable = 99999.0
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.3).timeout

	# --- a skeleton right behind George (inside the camera) fades out, and back in when it leaves
	p.teleport(Vector3(40, 0.05, 40), 0.0)
	await create_timer(0.5).timeout
	var cam := p.get_node("CameraRig/SpringArm3D/Camera3D") as Camera3D
	var e: Enemy = spawner.spawn_extra("warrior", cam.global_position)
	e.aggro_range = 0.1                                   # stand still
	e.set_physics_process(false)
	var body_center := Vector3(0, 0.9, 0)                  # the middle of a skeleton, above its feet
	e.global_position = cam.global_position - body_center
	await create_timer(0.5).timeout
	check("a skeleton at the camera is nearly invisible (%.2f)" % max_transparency(e), min_transparency(e) > 0.85)
	e.global_position = cam.global_position - body_center + Vector3(0, 0, 6.0)
	await create_timer(0.5).timeout
	check("and opaque again when it is 6 m away (%.2f)" % max_transparency(e), max_transparency(e) < 0.01)
	e.global_position = cam.global_position - body_center + Vector3(1.4, 0, 0)
	await create_timer(0.5).timeout
	var halfway := min_transparency(e)
	check("at 1.4 m it is half faded (%.2f)" % halfway, halfway > 0.2 and halfway < 0.8)
	e.queue_free()

	# --- the arm and the houses: sweep the camera round every big house
	var space := root.get_world_3d().direct_space_state
	var village := main.get_node("Village")
	var houses: Array = []
	for body in village.find_children("*", "StaticBody3D", true, false):
		var sb := body as StaticBody3D
		if sb.collision_layer & 1 == 0:
			continue
		var cs := sb.get_child(0) as CollisionShape3D if sb.get_child_count() > 0 else null
		if cs == null or not (cs.shape is BoxShape3D):
			continue
		var gs := (cs.shape as BoxShape3D).size * cs.global_transform.basis.get_scale()
		if gs.x >= 7.0 and gs.z >= 7.0 and gs.y >= 3.0 and gs.x < 30.0 and gs.z < 30.0 and sb.get_parent() is Node3D:
			houses.append(sb)
	check("there are houses to sweep (%d)" % houses.size(), houses.size() >= 5)
	var arm := p.get_node("CameraRig/SpringArm3D") as SpringArm3D
	var sphere := SphereShape3D.new()
	sphere.radius = (arm.shape as SphereShape3D).radius
	var results := {}
	for pulled in [false, true]:
		var mask := arm.collision_mask
		var total := 0
		var clipped := 0
		var worst := 0.0
		var swept := 0
		var inside_stands := 0
		for sb in houses:
			var cs := (sb as StaticBody3D).get_child(0) as CollisionShape3D
			var xf := cs.global_transform
			var half := (cs.shape as BoxShape3D).size * xf.basis.get_scale() * 0.5
			var vis := visual_aabb((sb as StaticBody3D).get_parent() as Node3D, xf)      # in the collider's frame
			var local_half := (cs.shape as BoxShape3D).size * 0.5
			# only roots that are one house: the visual box is about the size of the collider (not a whole group of things)
			if vis.size == Vector3.ZERO or vis.size.x > local_half.x * 2.0 * 1.6 + 2.0 or vis.size.z > local_half.z * 2.0 * 1.6 + 2.0:
				continue
			swept += 1
			# George stands 1.2 m from each of the four sides of the house, the camera sweeps behind him
			for side: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
				# 1.2 m outside the VISIBLE wall of that side (in the collider's frame, the visual box is vis)
				var vc := vis.get_center()
				var vh := vis.size * 0.5
				var stand := xf * Vector3(vc.x + side.x * (vh.x + 1.2), 0.0, vc.z + side.z * (vh.z + 1.2))
				stand.y = 0.0
				var rig := stand + Vector3.UP * 1.7
				if vis.grow(-0.25).has_point(xf.affine_inverse() * rig):
					inside_stands += 1                       # George himself stands inside the visible house here
					continue
				for yaw_deg in range(0, 360, 20):
					for pitch in [-0.7, -0.2, 0.3]:
						for length in [4.0, 7.0, 12.0]:
							var basis := Basis(Vector3.UP, deg_to_rad(float(yaw_deg))) * Basis(Vector3.RIGHT, pitch)
							var dir := basis * Vector3(0, 0, 1)
							var params := PhysicsShapeQueryParameters3D.new()
							params.shape = sphere
							params.transform = Transform3D(Basis(), rig)
							params.motion = dir * float(length)
							params.collision_mask = mask
							var res := space.cast_motion(params)
							var fraction: float = res[0] if res.size() > 0 else 1.0
							var dist := maxf(fraction * float(length) - arm.margin, 0.0)
							var camera_at := rig + dir * dist
							if pulled:
								camera_at = Player.camera_pull_in(space, rig, camera_at)
							total += 1
							# inside the visual box of the house by more than the near plane
							var local := xf.affine_inverse() * camera_at
							if vis.grow(-0.25).has_point(local):
								clipped += 1
								var depth := minf(minf(local.x - vis.position.x, vis.end.x - local.x), minf(local.z - vis.position.z, vis.end.z - local.z))
								worst = maxf(worst, depth)
		results[pulled] = clipped
		print("  %s: camera inside a house's visual box %d of %d positions (%d houses), deepest %.2f m (%d of the %d stands skipped: George himself is inside the visible house there)" % ["with the shell pull-in" if pulled else "spring arm alone", clipped, total, swept, worst, inside_stands, swept * 4])
	check("with the spring arm alone the camera does end up inside houses (the problem, %d)" % results[false], results[false] > 0)
	check("with the shell pull-in it never does", results[true] == 0)
	print("ALL PASS" if not failed else "SOME FAILED")
	quit(1 if failed else 0)

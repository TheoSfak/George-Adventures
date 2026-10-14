extends SceneTree
## Screenshots of the new creatures (and of the cult site and the pumpkin patch in the real village):
##   godot --path . --resolution 1600x900 --script tools/mobshot.gd -- <outdir> [night]
var out := "."
var night := false


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	night = "night" in a
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	await create_timer(0.3).timeout
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(out)
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var spawner := get_first_node_in_group("enemy_spawner")
	var dn := get_first_node_in_group("daynight")
	dn.running = false
	dn.set_time(22.0 if night else 12.0)
	p._invulnerable = 99999.0
	for e in get_nodes_in_group("enemies"):
		e.queue_free()

	# --- a line-up in an arena far from the village
	var arena_at := Vector3(8000, 0, 8000)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	var fs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(300, 1, 300)
	fs.shape = box
	floor_body.add_child(fs)
	floor_body.position = arena_at + Vector3(0, -0.5, 0)
	root.add_child(floor_body)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 60)
	ground.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.33, 0.42, 0.26)
	ground.material_override = gmat
	ground.position = arena_at
	root.add_child(ground)
	p.teleport(arena_at + Vector3(0, 0.05, 60), 0.0)
	await create_timer(0.5).timeout
	var row := ["pumpkin", "pumpkin", "haunted_tree", "golem", "golem", "bone_heap", "mimic", "cultist", "cult_priest"]
	var x := -float(row.size() - 1) * 3.2 * 0.5
	var made: Array = []
	for k in row:
		var e: Enemy = spawner.spawn_extra(k, arena_at + Vector3(x, 0.05, 0))
		e.aggro_range = 0.1
		e.global_position = arena_at + Vector3(x, 0.05, 0)
		e._model_root.rotation.y = PI                # face the camera (+Z)
		made.append(e)
		x += 3.2
	await create_timer(0.8).timeout
	(made[4] as Enemy)._wake()                        # the second golem is awake
	await create_timer(1.2).timeout
	for e in made:
		e._bar.visible = true
	var cam := Camera3D.new()
	cam.position = arena_at + Vector3(0, 5.5, 17)
	cam.look_at(arena_at + Vector3(0, 1.6, 0))
	cam.fov = 50
	root.add_child(cam)
	cam.current = true
	await shot("mobs_lineup" + ("_night" if night else ""))
	# close-ups of three of them
	for pair in [["golem_awake", 4, 1.0], ["pumpkin", 0, 0.5], ["priest", 8, 1.0]]:
		var e: Enemy = made[pair[1]]
		cam.global_position = e.global_position + Vector3(2.5, 2.2 * e.model_scale + 0.8, 6.0 * maxf(e.model_scale, 1.0))
		cam.look_at(e.global_position + Vector3(0, 1.3 * e.model_scale, 0))
		await shot("mob_%s%s" % [pair[0], "_night" if night else ""])

	# --- the cult's ritual circle and the pumpkin patch in the real village
	p.teleport(Vector3(-80, 0.05, -118), PI)
	await create_timer(1.5).timeout
	var cult_cam := Camera3D.new()
	root.add_child(cult_cam)
	cult_cam.current = true
	cult_cam.fov = 60
	cult_cam.global_position = Vector3(-80, 9.0, -112)
	cult_cam.look_at(Vector3(-80, 1.5, -144))
	await shot("cult_site" + ("_night" if night else ""))
	cult_cam.global_position = Vector3(-66, 4.0, -130)
	cult_cam.look_at(Vector3(-82, 1.5, -146))
	await shot("cult_altar" + ("_night" if night else ""))
	p.teleport(Vector3(70, 0.05, -150), PI)
	await create_timer(1.5).timeout
	cult_cam.global_position = Vector3(70, 7.0, -158)
	cult_cam.look_at(Vector3(70, 0.8, -172))
	await shot("pumpkin_patch" + ("_night" if night else ""))
	quit(0)

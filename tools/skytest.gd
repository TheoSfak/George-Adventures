extends SceneTree
## Sky shots:  godot --path . --resolution 1280x720 --script tools/skytest.gd -- <outdir>
var out := "."
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: out = args[0]
	_run()
func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.0).timeout
	for e in get_nodes_in_group("enemies"): e.queue_free()
	var dn := get_first_node_in_group("daynight")
	dn.running = false
	var cam := Camera3D.new()
	main.add_child(cam)
	cam.global_position = Vector3(0, 6, 30)
	cam.current = true
	for h in [10.0, 19.8, 22.0, 2.0, 5.8]:
		dn.set_time(h)
		var sun_dir: Vector3 = dn._sun_direction()
		var moon_dir: Vector3 = dn._moon_direction()
		var look: Vector3 = sun_dir if sun_dir.y > -0.05 else moon_dir
		cam.look_at(cam.global_position + Vector3(look.x, look.y * 0.8 + 0.15, look.z) * 10.0)
		await create_timer(1.2).timeout
		root.get_viewport().get_texture().get_image().save_png("%s/sky_%05.2f.png" % [out, h])
		print("h ", h, " sun ", sun_dir, " moon ", moon_dir)
	quit()

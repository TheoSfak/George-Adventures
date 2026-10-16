extends SceneTree

var out := "C:/Users/user/.gemini/antigravity-ide/brain/2c45d79f-37ca-4c72-a189-f1ade871ffb8/.tempmediaStorage"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	_run()

func shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	print("Saved shot: %s/%s.png" % [out, name])

func _look_at_sign(cam: Camera3D, target: Vector3, rot_deg: float, dist: float, y_offset: float = 0.0) -> void:
	var rad := deg_to_rad(rot_deg)
	var forward := Vector3(sin(rad), 0.0, cos(rad)).normalized()
	var from := target + forward * dist + Vector3(0.0, y_offset, 0.0)
	cam.global_position = from
	cam.look_at(target, Vector3.UP)

func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.0).timeout

	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.2).timeout

	var dn := get_first_node_in_group("daynight") as DayNight
	if dn:
		dn.running = false
		dn.set_time(12.5) # midday sun

	var cam := Camera3D.new()
	cam.fov = 48.0
	main.add_child(cam)
	cam.make_current()

	# 1. Waterfall Signpost
	_look_at_sign(cam, Vector3(41.53, 1.45, -127.95), 30.0, 3.2, 0.0)
	await create_timer(0.5).timeout
	await shot("sign_waterfall_final")

	# 2. Village Sea Signpost
	_look_at_sign(cam, Vector3(-12.0, 3.8, 62.0), 0.0, 7.5, -0.2)
	await create_timer(0.5).timeout
	await shot("sign_village_sea_final")

	# 3. Pier Signpost
	_look_at_sign(cam, Vector3(-32.2, 1.45, 94.0), -20.0, 3.2, 0.0)
	await create_timer(0.5).timeout
	await shot("sign_pier_final")

	# 4. Lighthouse Signpost
	_look_at_sign(cam, Vector3(-106.55, 1.45, 136.03), -60.0, 3.2, 0.0)
	await create_timer(0.5).timeout
	await shot("sign_lighthouse_final")

	# 5. Parkour Signpost
	var pc := main.find_child("ParkourCourse", true, false)
	if pc and pc.get("_sign_body"):
		var p_pos: Vector3 = pc._sign_body.global_position
		_look_at_sign(cam, p_pos + Vector3(0.0, 1.8, 0.0), 0.0, 3.6, 0.0)
		await create_timer(0.5).timeout
		await shot("sign_parkour_final")

	print("AFTER SHOTS COMPLETED!")
	quit(0)

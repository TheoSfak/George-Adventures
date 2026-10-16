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


func _look(cam: Camera3D, target: Vector3, from: Vector3) -> void:
	cam.global_position = from
	cam.look_at(target, Vector3.UP)


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout

	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await create_timer(0.3).timeout

	var p := get_first_node_in_group("player") as Player
	var dn := get_first_node_in_group("daynight") as DayNight
	if dn:
		dn.running = false
		dn.set_time(12.5) # Bright midday Mediterranean sun

	if p:
		p.max_health = 50000.0
		p.health = 50000.0

	var cam := Camera3D.new()
	cam.fov = 65.0
	main.add_child(cam)
	cam.make_current()

	# 1. Lighthouse & Beach Promontory
	# Lighthouse at (-115, 0, 138), height ~23m
	_look(cam, Vector3(-115.0, 9.0, 138.0), Vector3(-88.0, 8.5, 105.0))
	await create_timer(0.8).timeout
	await shot("island_sea_lighthouse")

	# 2. Fishing Pier & Sunken Shipwreck
	# Pier at (-35, 0, 126), Shipwreck at (-72, 0, 168)
	_look(cam, Vector3(-45.0, 1.2, 145.0), Vector3(-35.0, 3.8, 116.0))
	await create_timer(0.8).timeout
	await shot("island_pier_shipwreck")

	# 3. Cascading Waterfall of the Nymphs
	# Waterfall at (48, 0, -132)
	_look(cam, Vector3(48.0, 6.0, -132.0), Vector3(48.0, 3.2, -115.0))
	await create_timer(0.8).timeout
	await shot("island_waterfall")

	# 3b. Secret Cave behind the waterfall
	_look(cam, Vector3(48.0, 1.2, -125.0), Vector3(48.0, 1.2, -136.5))
	await create_timer(0.8).timeout
	await shot("island_secret_cave")

	# 4. Arched Stone River Bridge
	# Bridge at (70, 0.1, -66)
	_look(cam, Vector3(70.0, 1.5, -66.0), Vector3(54.0, 4.5, -48.0))
	await create_timer(0.8).timeout
	await shot("island_river_bridge")

	# 5. Eagle's Vista & North Highlands Summit
	# Summit at (82, 13.5, -155), canopy at (82, 13.7, -156.5)
	_look(cam, Vector3(82.0, 15.0, -156.5), Vector3(82.0, 15.0, -150.5))
	await create_timer(0.8).timeout
	await shot("island_highlands_vista")

	print("ALL SHOTS COMPLETED SUCCESSFULLY!")
	quit(0)

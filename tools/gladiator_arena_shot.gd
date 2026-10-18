extends SceneTree

var out_dir := "C:/Users/user/.gemini/antigravity-ide/brain/b4e8c09d-d4b5-4402-8be1-5536522d6f1b"

func _init() -> void:
	_run.call_deferred()

func shot(shot_name: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out_dir)
	var p: String = "%s/%s.png" % [out_dir, shot_name]
	img.save_png(p)
	print("Saved screenshot: %s" % p)

func _look(cam: Camera3D, target: Vector3, from_pos: Vector3) -> void:
	cam.global_position = from_pos
	cam.look_at(target, Vector3.UP)

func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await create_timer(2.0).timeout

	var p: Player = get_first_node_in_group("player") as Player
	var hud = get_first_node_in_group("hud")
	var dn: DayNight = get_first_node_in_group("daynight") as DayNight
	if dn:
		dn.running = false
		dn.set_time(15.0) # Crisp golden afternoon lighting

	var arena := get_first_node_in_group("gladiator_arena")
	var center := Vector3(-130.0, 0.0, 58.0)

	# Give George high level, gold, and equip him
	p.level = 25
	p.gold = 5000
	p.equip("weapon_orc_cleaver")
	p.equip("armor_gladiator_champion")
	p._recalc()
	p._update_equipment_visuals()

	# Position George at the entrance avenue
	p.teleport(Vector3(-108.0, 0.05, 58.0), deg_to_rad(-90.0))
	await create_timer(0.4).timeout

	var cam: Camera3D = Camera3D.new()
	cam.fov = 60.0
	main.add_child(cam)
	cam.make_current()

	# 1. Panoramic Overview of the Arena (Coastal meadow setting, sand pit, polygonal battlements, grandstands)
	_look(cam, center + Vector3(0.0, 1.5, 0.0), center + Vector3(28.0, 16.0, -22.0))
	await shot("gladiator_arena_panoramic_new")

	# 2. Medium Shot: Master Kassandros at his podium, Entrance Archway, Grand Signpost & Portcullis
	_look(cam, Vector3(-114.5, 1.4, 58.0), Vector3(-102.0, 2.4, 53.5))
	await shot("gladiator_arena_entrance_and_master_new")

	# 3. Clean Sand Pit Interior (Zero deer, zero chests, pristine fighting disc with spectator stands)
	p.teleport(center + Vector3(4.0, 0.05, 0.0), deg_to_rad(-90.0))
	await create_timer(0.3).timeout
	_look(cam, center + Vector3(-2.0, 1.2, 0.0), center + Vector3(10.0, 2.5, 3.5))
	await shot("gladiator_arena_clean_pit_new")

	# 4. Emergency Gate Lever inside the arena near the gate post
	_look(cam, Vector3(-118.1, 0.55, 60.2), Vector3(-121.2, 1.6, 57.5))
	await shot("gladiator_arena_emergency_lever_new")

	# 5. Arena Window UI
	if hud:
		hud.open_arena(arena, p)
		await create_timer(0.4).timeout
		await shot("gladiator_arena_window_ui_new")
		hud._arena_window.close()

	print("\n--- All Gladiator Arena Screenshots Captured Successfully! ---")
	quit(0)

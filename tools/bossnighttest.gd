extends SceneTree
## Boss night, screenshots and frame rate:
##   godot --path . --resolution 1920x1080 --script tools/bossnighttest.gd -- <outdir>
var out := "."


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


## A free camera for the pictures (George's own camera may sit inside a tree).
func _look_at(cam: Camera3D, target: Vector3, from_dir: Vector3, distance: float, height: float) -> void:
	cam.global_position = target + from_dir * distance + Vector3.UP * height
	cam.look_at(target + Vector3.UP * 2.0, Vector3.UP)


func _night_lord():
	for e in get_nodes_in_group("invaders"):
		if e.kind_id == "night_lord":
			return e
	return null


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
	var inv = get_first_node_in_group("invasion")
	dn.running = false
	p.max_health = 50000.0
	p.health = 50000.0
	p.teleport(Vector3(0, 0.05, 12), 0.0)
	var cam := Camera3D.new()
	cam.fov = 60.0
	main.add_child(cam)
	cam.make_current()
	var banners := []
	inv.banner.connect(func(t, _s): banners.append(t))

	dn.night_number = 4
	dn.set_time(20.6)                      # night 5
	await create_timer(5.0).timeout
	var guard := 0
	while inv.active and inv.wave < 4 and guard < 24:
		for e in get_nodes_in_group("invaders"):
			e.take_damage(99999.0, p.global_position)
		await create_timer(0.8).timeout
		guard += 1
	await create_timer(0.5).timeout
	var boss = _night_lord()
	print("boss present: ", boss != null, "  wave ", inv.wave, "/", inv.waves_total, "  invaders ", get_nodes_in_group("invaders").size())
	print("banners: ", banners)
	if boss == null:
		quit(1)
		return
	var gate_pos: Vector3 = boss.global_position
	var toward_well := Vector3(-gate_pos.x, 0.0, -gate_pos.z).normalized()
	p.teleport(gate_pos + toward_well * 34.0 + Vector3(0, 0.05, 0), atan2(-toward_well.x, -toward_well.z))
	await create_timer(0.5).timeout
	_look_at(cam, boss.global_position, toward_well, 16.0, 6.0)
	await shot("boss_arrives")
	print("fps while the wave marches: ", Engine.get_frames_per_second())

	await create_timer(5.0).timeout       # the boss notices George and fights
	boss.call("_summon")
	await create_timer(1.5).timeout
	_look_at(cam, boss.global_position, toward_well, 14.0, 6.0)
	await shot("boss_summons")
	boss.take_damage(boss.max_health * 0.55, p.global_position)   # below half: enrage
	await create_timer(1.5).timeout
	_look_at(cam, boss.global_position, toward_well, 14.0, 6.0)
	await shot("boss_enraged")
	print("enraged: ", boss.get("_enraged"))
	boss.call("_summon")
	await create_timer(3.0).timeout       # no screenshot just before the measurement (reading the image stalls the GPU)
	print("fps in the fight (boss, helpers, escort): ", Engine.get_frames_per_second(), "  invaders ", get_nodes_in_group("invaders").size())

	for i in 6:
		for e in get_nodes_in_group("invaders"):
			e.take_damage(99999.0, p.global_position)
		await create_timer(0.8).timeout
	_look_at(cam, Vector3(0, 0, 0), Vector3(0.3, 0, 1).normalized(), 22.0, 8.0)
	await shot("boss_won")
	print("success: ", inv.last_success, "  banners: ", banners)
	quit()

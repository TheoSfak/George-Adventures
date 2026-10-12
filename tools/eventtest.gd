extends SceneTree
## Night invasion:  godot --path . --resolution 1280x720 --script tools/eventtest.gd -- <outdir>
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


func _run() -> void:
	await process_frame
	var quests := root.get_node("/root/Quests")
	quests.intro_seen = true
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
	p.max_health = 5000.0
	p.health = 5000.0
	p.teleport(Vector3(0, 0.05, 12), 0.0)
	quests.state["night"] = 2   # S.ACTIVE
	var banners := []
	inv.banner.connect(func(t, _s): banners.append(t))

	# ---- night 1: waves, then success
	dn.set_time(20.6)
	print("night ", dn.night_number, " invasion active: ", inv.active)
	await create_timer(5.0).timeout
	print("wave ", inv.wave, " alive ", get_nodes_in_group("invaders").size(), " safety ", inv.safety)
	await shot("inv_wave1_march")
	var guard := 0
	var gold_before := p.gold
	var xp_before := p.xp
	while inv.active and guard < 14:
		for e in get_nodes_in_group("invaders"):
			e.take_damage(99999.0, p.global_position)
		await create_timer(1.2).timeout
		guard += 1
		print("  after kill round ", guard, ": wave ", inv.wave, " active ", inv.active)
	print("success: ", inv.last_success, " gold +", p.gold - gold_before, " quest night state ", quests.state["night"], " (3 = ready)")
	print("reward chest present: ", main.get_node("Village/Chests").get_children().any(func(c): return c.get("golden") != null and c.position.is_equal_approx(Vector3(6, 0.05, 8))))
	print("banners: ", banners)
	await shot("inv_success")

	# ---- night 2: the village falls
	dn.set_time(5.9)
	await create_timer(1.0).timeout
	p.gold = 100
	dn.set_time(20.6)
	print("night ", dn.night_number, " active ", inv.active)
	await create_timer(5.0).timeout
	for e in get_nodes_in_group("invaders"):
		e.global_position = Vector3(randf_range(-5, 5), 0.05, randf_range(-5, 5))
	await create_timer(3.0).timeout
	await shot("inv_at_well")
	guard = 0
	while inv.active and guard < 80:
		for e in get_nodes_in_group("invaders"):
			if e.global_position.length() > 12.0:
				e.global_position = Vector3(randf_range(-5, 5), 0.05, randf_range(-5, 5))
		await create_timer(1.0).timeout
		guard += 1
	print("village fell after ~", guard, " s: safety ", inv.safety, " success ", inv.last_success, " gold now ", p.gold, " (was 100)")
	await create_timer(2.0).timeout
	print("invaders left after fail: ", get_nodes_in_group("invaders").size())

	# ---- night 3: leftovers crumble at dawn
	dn.set_time(5.9)
	await create_timer(1.0).timeout
	dn.set_time(20.6)
	await create_timer(6.0).timeout
	var before := get_nodes_in_group("invaders").size()
	dn.set_time(5.6)
	await create_timer(3.5).timeout
	print("night ", dn.night_number, ": invaders before dawn ", before, " after ", get_nodes_in_group("invaders").size(), " active ", inv.active)
	quit()

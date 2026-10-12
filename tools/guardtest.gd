extends SceneTree
## Guards help during the invasion (George does not fight):  godot --path . --resolution 1920x1080 --script tools/guardtest.gd -- <outdir>
var out := "."
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0: out = a[0]
	_run()
func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
func _run() -> void:
	await process_frame
	var q := root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	var p := get_first_node_in_group("player") as Player
	var dn := get_first_node_in_group("daynight") as DayNight
	var inv = get_first_node_in_group("invasion")
	dn.running = false
	p.max_health = 9999.0
	p.health = 9999.0
	q.state["archers"] = 4
	q.state["totems"] = 4        # two of Vasilis' quests done -> 4 guards
	p.teleport(Vector3(0, 0.05, 22), 0.0)
	dn.set_time(20.6)
	await create_timer(6.0).timeout
	print("guards: ", get_nodes_in_group("guards").size(), " (4 expected)   invaders: ", get_nodes_in_group("invaders").size())
	# march the invaders right up to the well so the guards meet them
	for e in get_nodes_in_group("invaders"):
		e.global_position = Vector3(randf_range(-9, 9), 0.05, randf_range(-14, -8))
	await create_timer(1.5).timeout
	await shot("guards_fight")
	var t0 := Time.get_ticks_msec()
	var start := get_nodes_in_group("invaders").size()
	while get_nodes_in_group("invaders").size() > 0 and Time.get_ticks_msec() - t0 < 60000:
		await create_timer(1.0).timeout
	print("wave 1: ", start, " invaders killed by the guards alone in ", snappedf((Time.get_ticks_msec() - t0) / 1000.0, 0.1), " s; George health ", p.health, " / ", p.max_health, "; wave now ", inv.wave)
	inv.safety = 0.0     # end the night quickly
	await create_timer(1.5).timeout
	await create_timer(1.5).timeout
	print("after the night: guards left ", get_nodes_in_group("guards").size(), " (0 expected)")
	quit()

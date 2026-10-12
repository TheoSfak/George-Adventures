extends SceneTree
## Day/night screenshots:  godot --path . --resolution 1280x720 --script tools/daytest.gd -- <outdir>
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
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	var dn := get_first_node_in_group("daynight")
	var p := get_first_node_in_group("player") as Player
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	p.teleport(Vector3(0, 0.05, 20), 0.0)
	dn.running = false
	var phases := []
	dn.dusk_started.connect(func(): phases.append("dusk"))
	dn.night_started.connect(func(n): phases.append("night%d" % n))
	dn.dawn_started.connect(func(): phases.append("dawn"))
	dn.day_started.connect(func(): phases.append("day"))
	for t in [9.0, 12.0, 19.0, 19.7, 20.8, 23.0, 3.0, 5.7, 6.5]:
		dn.set_time(t)
		await create_timer(0.8).timeout
		print("t=", t, " clock=", dn.clock_text(), " dark=", snappedf(dn.darkness(), 0.01), " phase=", dn.phase)
		await shot("day_%05.2f" % t)
	print("phases fired: ", phases)
	# villagers should have sheltered at dusk and returned at dawn
	var hidden := 0
	for v in get_nodes_in_group("villagers"):
		if not v.visible:
			hidden += 1
	print("villagers: ", get_nodes_in_group("villagers").size(), " hidden now: ", hidden)
	quit()

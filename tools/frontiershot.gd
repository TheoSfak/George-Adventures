extends SceneTree
## Screenshots of each zone of the Frontier and a frame-rate check:
##   godot --path . --resolution 1920x1080 --script tools/frontiershot.gd -- tools/_shots/frontier [night]
var out := "."


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func sample(label: String, secs: float) -> void:
	var t0 := Time.get_ticks_msec()
	var frames := 0
	while Time.get_ticks_msec() - t0 < secs * 1000.0:
		await process_frame
		frames += 1
	print("PERF ", label, ": ", snappedf(frames / secs, 0.1), " fps, draw calls ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _run() -> void:
	await process_frame
	var fr = load("res://scripts/frontier.gd")
	var q = root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var interiors = get_first_node_in_group("interiors")
	p._invulnerable = 99999.0
	if "night" in OS.get_cmdline_user_args():
		var dn := get_first_node_in_group("daynight")
		dn.running = false
		dn.set_time(23.0)
		await create_timer(2.0).timeout
	q.state["f_gate"] = q.S.ACTIVE
	interiors.enter_region("frontier", fr.VILLAGE_GATE + Vector3(0, 0.05, 5), 0.0, p)
	for i in 150:
		await create_timer(0.1).timeout
		if interiors.in_region() and not p.busy:
			break
	print("PERF lights in the tree: ", root.find_children("*", "OmniLight3D", true, false).size())
	var spots := [
		["entry", 0.0, 112.0, PI], ["pass", 4.0, 60.0, PI], ["camp", 0.0, 22.0, PI],
		["road", 0.0, -40.0, PI], ["fortress_outside", 0.0, -92.0, PI], ["courtyard", 0.0, -122.0, PI],
	]
	for s in spots:
		p.teleport(fr.wp(s[1], s[2], 0.05), s[3])
		await create_timer(1.2).timeout
		await shot("fr_" + s[0])
		await sample(s[0], 3.0)
	quit()

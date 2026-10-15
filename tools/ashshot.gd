extends SceneTree
## Screenshots of each zone of the Ash Valley (and the gate in the village) and a frame-rate check:
##   godot --path . --resolution 1920x1080 --script tools/ashshot.gd -- tools/_shots/ash [night]
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
	var av = load("res://scripts/ash_valley.gd")
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
	q.state["a_gate"] = q.S.ACTIVE
	# the gate as seen from the village
	var yaw := atan2(-av.VILLAGE_GATE.x, -av.VILLAGE_GATE.z)
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	for d in [[12.0, "gate_far"], [6.0, "gate_near"]]:
		p.teleport(av.VILLAGE_GATE + forward * float(d[0]) + Vector3(0, 0.05, 0), yaw + PI)
		await create_timer(1.5).timeout
		await shot("ash_" + String(d[1]))
	interiors.enter_region("ashvalley", av.VILLAGE_GATE + forward * 5.0, yaw, p)
	for i in 150:
		await create_timer(0.1).timeout
		if interiors.in_region() and not p.busy:
			break
	print("PERF lights in the tree: ", root.find_children("*", "OmniLight3D", true, false).size())
	var spots := [
		["entry", 0.0, 110.0, PI], ["road", 6.0, 78.0, PI], ["camp", 0.0, 50.0, PI], ["camp_fire", -4.0, 36.0, 0.6],
		["valley_south", 0.0, 0.0, PI], ["lava_bank", -30.0, -38.0, PI], ["bridge", 0.0, -36.0, PI], ["bridge_top", 0.0, -62.0, PI],
		["valley_north", 0.0, -84.0, PI], ["golem", -30.0, -76.0, 0.0], ["temple_outside", 0.0, -112.0, PI],
		["temple_inside", 0.0, -138.0, PI], ["flame", 0.0, -146.0, PI],
	]
	for s in spots:
		p.teleport(av.wp(s[1], s[2], 0.05), s[3])
		await create_timer(1.2).timeout
		await shot("ash_" + s[0])
		await sample(s[0], 3.0)
	quit()

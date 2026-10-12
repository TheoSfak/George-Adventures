extends SceneTree
## Frame rate check:  godot --path . --resolution 1280x720 --script tools/perftest.gd
func _initialize() -> void:
	_run()
func sample(label: String, secs: float) -> void:
	var t0 := Time.get_ticks_msec()
	var frames := 0
	while Time.get_ticks_msec() - t0 < secs * 1000.0:
		await process_frame
		frames += 1
	print("PERF ", label, ": ", snappedf(frames / secs, 0.1), " fps, draw calls ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), ", objects ", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	await sample("spawn / plaza", 4.0)
	for v in [["forest edge", -150.0, -100.0, 0.5], ["west camp", -140.0, 20.0, 1.5], ["crypt gate", 0.0, -128.0, PI], ["meadow", 60.0, 90.0, 2.0]]:
		p.teleport(Vector3(v[1], 0.05, v[2]), v[3])
		await create_timer(1.0).timeout
		await sample(v[0], 3.0)
	quit()

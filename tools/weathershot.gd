extends SceneTree
## Screenshots of every weather by day and by night, the tavern in the rain, and the frame rate of each:
##   godot --path . --resolution 1920x1080 --script tools/weathershot.gd -- tools/_shots/weathershot [day|night]
## Without the last word both parts run in one process; on a GPU shared with another Godot run the parts
## one after the other (a long run can run out of memory there).
var out := "."
var part := "both"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.size() > 1:
		part = args[1]
	DirAccess.make_dir_recursive_absolute(out)
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func sample(label: String, secs: float) -> void:
	var t0 := Time.get_ticks_msec()
	var frames := 0
	while Time.get_ticks_msec() - t0 < secs * 1000.0:
		await process_frame
		frames += 1
	print("PERF ", label, ": ", snappedf(frames / secs, 0.1), " fps")


## Sets the weather to a state completely (the node keeps running in real time) and waits for the picture to settle.
func weather(w, state: int) -> void:
	w.force(state)
	for i in 30:
		w.step(1.0)
	await create_timer(2.0).timeout


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(3.0).timeout
	var p := get_first_node_in_group("player") as Player
	var dn := get_first_node_in_group("daynight") as DayNight
	var w = get_first_node_in_group("weather")
	var interiors = get_first_node_in_group("interiors")
	p._invulnerable = 99999.0
	dn.running = false
	dn.set_time(12.0)
	p.teleport(Vector3(0.0, 0.05, 22.0), 0.0)
	await create_timer(1.5).timeout
	var names := ["clear", "fog", "rain", "storm"]
	if part != "night":
		for s in 4:
			await weather(w, s)
			await shot("w_day_%d_%s" % [s, names[s]])
			await sample("day " + names[s], 3.0)
		# a lightning flash in the storm
		w.set_process(false)
		w._bolt_t = 0.0
		w.step(0.0)
		await shot("w_day_3_storm_flash")
		w.set_process(true)
	if part == "day":
		quit()
		return
	# night
	dn.set_time(23.0)
	await create_timer(2.0).timeout
	for s in [0, 1, 2, 3]:
		await weather(w, s)
		await shot("w_night_%d_%s" % [s, names[s]])
		await sample("night " + names[s], 3.0)
	# the tavern in the rain
	await weather(w, 2)
	interiors.enter("tavern_weathershot", "tavern", Vector3(-59, 0.05, 5), 0.0, p)
	await create_timer(2.5).timeout
	await shot("w_tavern_rain")
	quit()

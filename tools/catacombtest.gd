extends SceneTree
## The catacombs: door, build time, screenshots of every area, creature counts, exit.
##   godot --path . --resolution 1920x1080 --script tools/catacombtest.gd -- <outdir>
var out := "."
var cat   # the Catacombs script (loaded, not type-referenced: it mentions the Quests autoload)


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	_run()


func shot(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


## Average frames per second over a short time (screenshots stall the frame rate, so measure separately).
func measure(seconds: float = 1.5) -> float:
	var frames := 0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < seconds * 1000.0:
		await process_frame
		frames += 1
	return frames / ((Time.get_ticks_msec() - t0) / 1000.0)


func press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await create_timer(0.1).timeout
	ev = InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)


func _run() -> void:
	await process_frame
	cat = load("res://scripts/catacombs.gd")
	var q := root.get_node("/root/Quests")
	q.intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	var p := get_first_node_in_group("player") as Player
	p._invulnerable = 9999.0

	# the sealed door first
	var door: InteractSpot = null
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.global_position.distance_to(Vector3(0, 0, -188)) < 4.0:
			door = n
	print("door found: ", door != null)
	p.teleport(door.global_position + Vector3(0, 0.05, 9.0), PI)
	await create_timer(1.0).timeout
	print("door prompt before the quest: ", door.interact_prompt())
	await shot("door_sealed")
	q.state["king"] = q.S.DONE
	q._refresh_availability()
	print("descent state: ", q.state["descent"], " (AVAILABLE=1)")
	q.state["descent"] = q.S.ACTIVE
	q.changed.emit()
	print("door prompt after: ", door.interact_prompt())
	p.teleport(door.global_position + Vector3(0, 0.05, 2.0), PI)
	await create_timer(0.5).timeout
	var t0 := Time.get_ticks_msec()
	await press("interact")
	var inside := false
	for i in 80:
		await create_timer(0.1).timeout
		if get_first_node_in_group("interiors").is_inside() and not p.busy:
			inside = true
			break
	print("entered: ", inside, " after ", Time.get_ticks_msec() - t0, " ms; pos ", p.global_position)
	print("descent state after entering: ", q.state["descent"], " (READY=3)")
	await create_timer(0.5).timeout
	var lights := root.find_children("*", "OmniLight3D", true, false).size()
	print("enemies: ", get_nodes_in_group("enemies").size(), "  omni lights in the world: ", lights, "  fps: ", Engine.get_frames_per_second())
	var kinds := {}
	for e in get_nodes_in_group("enemies"):
		kinds[e.kind_id] = kinds.get(e.kind_id, 0) + 1
	print("creatures: ", kinds)
	await shot("01_entry")

	var views := [
		["02_entry_wide", 30.0, 46.0, PI, -0.8, 11.0],
		["03_corridor", 30.0, 37.0, PI, -0.25, 6.2],
		["04_cloister", 30.0, 31.0, PI, -0.45, 8.0],
		["05_cloister_high", 30.0, 27.0, PI, -1.0, 16.0],
		["06_west", 6.0, 27.0, PI, -0.5, 8.0],
		["07_bone_warden", 7.0, 12.0, PI, -0.45, 8.0],
		["08_east", 54.0, 27.0, PI, -0.5, 8.0],
		["09_flame_warden", 53.0, 12.0, PI, -0.45, 8.0],
		["10_shadow", 20.0, 18.0, PI, -0.45, 8.0],
		["11_vault", 40.0, 16.5, PI, -0.45, 8.0],
		["12_gate", 30.0, 15.0, PI, -0.35, 6.5],
		["13_alcove", 15.5, 32.5, PI, -0.45, 7.0],
		["14_abbot_hall", 30.0, 8.5, PI, -0.5, 9.0],
	]
	for v in views:
		p.teleport(cat.wp(v[1], v[2], 0.05), v[3])
		p._pitch = v[4]
		p._arm.spring_length = v[5]
		await create_timer(0.9).timeout
		var fps: float = await measure()
		print(v[0], "  fps ", snappedf(fps, 0.1))
		await shot(v[0])

	# the exit
	p._arm.spring_length = 6.2
	p.teleport(cat.wp(30.0, 47.0, 0.05), PI)
	await create_timer(0.6).timeout
	print("exit prompt: ", p._last_prompt)
	await press("interact")
	await create_timer(1.6).timeout
	print("outside again: ", not get_first_node_in_group("interiors").is_inside(), " pos ", p.global_position)

	# back in, then dying inside: George wakes up in the village with the outdoor light back
	p.teleport(door.global_position + Vector3(0, 0.05, 2.0), PI)
	await create_timer(0.5).timeout
	await press("interact")
	for i in 60:
		await create_timer(0.1).timeout
		if get_first_node_in_group("interiors").is_inside() and not p.busy:
			break
	print("entered again: ", get_first_node_in_group("interiors").is_inside(), " pos ", p.global_position)
	p._invulnerable = 0.0
	p.take_damage(99999.0, p.global_position + Vector3(1, 0, 0))
	await create_timer(p.respawn_time + 1.0).timeout
	var env := (root.find_child("WorldEnvironment", true, false) as WorldEnvironment).environment
	print("after dying: inside=", get_first_node_in_group("interiors").is_inside(), " pos ", p.global_position, " fog ", env.fog_enabled, " (inside false, village, fog true expected)")
	quit()

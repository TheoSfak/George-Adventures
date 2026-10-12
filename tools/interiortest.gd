extends SceneTree
## Door + interior screenshots:  godot --path . --resolution 1280x720 --script tools/interiortest.gd -- <outdir>
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
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	var p := get_first_node_in_group("player") as Player
	var doors := []
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.label.begins_with("[R] Είσοδος"):
			doors.append(n)
	print("doors: ", doors.size())
	var seen := {}
	for d in doors:
		var kind: String = d.label
		if seen.has(kind):
			continue
		seen[kind] = true
		var tag := kind.replace("[R] Είσοδος: ", "").replace(" ", "_")
		# stand a few metres in front of the door, looking at the building
		var back: Vector3 = -(Vector3(sin(0), 0, 1))
		var door_pos: Vector3 = d.global_position
		var to_well := (-door_pos).normalized()
		var stand := door_pos + to_well * 7.0
		var heading := atan2(-to_well.x, -to_well.z)
		p.teleport(stand + Vector3(0, 0.05, 0), heading)
		await create_timer(1.0).timeout
		await shot("door_" + tag)
		p.teleport(door_pos + Vector3(0, 0.05, 0), heading)
		await create_timer(0.5).timeout
		print(kind, " prompt: ", p._last_prompt)
		await press("interact")
		await create_timer(1.6).timeout
		print("  inside: pos ", p.global_position, " busy ", p.busy)
		await shot("inside_" + tag)
		# look around the room from a high camera angle
		p._pitch = -0.9
		p._arm.spring_length = 12.0
		await create_timer(0.8).timeout
		await shot("inside_high_" + tag)
		p._pitch = -0.3
		p._arm.spring_length = 7.0
		# walk to the exit door and leave
		var exit_spot: InteractSpot = null
		for n in get_nodes_in_group("interactables"):
			if n is InteractSpot and n.label == Strings.PROMPT_EXIT and n.global_position.distance_to(p.global_position) < 30.0:
				exit_spot = n
		p.teleport(exit_spot.global_position, PI)
		await create_timer(0.5).timeout
		await press("interact")
		await create_timer(1.6).timeout
		print("  back outside: pos ", p.global_position, " (door was at ", door_pos, ")")
	quit()

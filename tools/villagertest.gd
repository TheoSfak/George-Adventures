extends SceneTree
## Villagers (strolling, chatting, tavern):  godot --path . --resolution 1280x720 --script tools/villagertest.gd -- <outdir>
var out := "."
var p: Player


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


func villagers() -> Array:
	var out_list := []
	for n in get_nodes_in_group("interactables"):
		if n.get("display_name") != null and n.get("mode") != null:
			out_list.append(n)
	return out_list


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	p = get_first_node_in_group("player") as Player
	var vs := villagers()
	var modes := {}
	for v in vs:
		modes[v.mode] = modes.get(v.mode, 0) + 1
	print("villagers outside: ", vs.size(), " by mode (0 wander,1 chat,2 sit,3 stand): ", modes)

	# watch strollers move
	var wanderers := vs.filter(func(v): return v.mode == 0)
	var before := wanderers.map(func(v): return v.global_position)
	p.teleport(Vector3(0, 0.05, 32), PI)
	await create_timer(9.0).timeout
	var moved := 0
	for i in wanderers.size():
		if wanderers[i].global_position.distance_to(before[i]) > 1.0:
			moved += 1
	print("strollers that walked somewhere: ", moved, " of ", wanderers.size())
	await shot("villagers_plaza")

	# stand next to a chatting pair
	var pair_a = vs.filter(func(v): return v.mode == 1 and v.lead)[0]
	p.teleport(pair_a.global_position + Vector3(0, 0.05, 6.0), PI)
	await create_timer(7.0).timeout
	await shot("villagers_chat")
	# talk to a stroller
	var talker = wanderers[0]
	p.teleport(talker.global_position + Vector3(1.5, 0.05, 0), PI / 2.0)
	await create_timer(0.6).timeout
	await press("interact")
	await create_timer(1.8).timeout
	var hud := get_first_node_in_group("hud")
	print("dialogue open after talking to ", talker.display_name, ": ", hud.is_dialogue_open())
	await shot("villagers_talk")
	var guard := 0
	while hud.is_dialogue_open() and guard < 12:
		guard += 1
		await create_timer(0.4).timeout
		await press("interact")
	await create_timer(0.8).timeout

	# the tavern
	var door: Node = null
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.label.contains("Ταβέρνα"):
			door = n
	p.teleport(door.global_position + Vector3(0, 0.05, 0), 0.0)
	await create_timer(0.5).timeout
	await press("interact")
	await create_timer(2.5).timeout
	var inside := villagers().filter(func(v): return v.global_position.x > 1000.0)
	print("regulars in the tavern: ", inside.size())
	await shot("tavern_regulars")
	# look at the sitting drinkers from above
	p._pitch = -0.7
	p._arm.spring_length = 9.0
	await create_timer(5.0).timeout
	await shot("tavern_regulars_high")
	quit()

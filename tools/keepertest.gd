extends SceneTree
## Shopkeepers inside the buildings, shop opened with R, respec shrine:
##   godot --path . --resolution 1280x720 --script tools/keepertest.gd -- <outdir>
var out := "."
var p: Player
var hud: Node


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
	await create_timer(0.12).timeout
	ev = InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)
	await create_timer(0.1).timeout


func find_door(text: String) -> Node:
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.label == text:
			return n
	return null


func find_spot(prefix: String) -> Node:
	for n in get_nodes_in_group("interactables"):
		if n is InteractSpot and n.interact_prompt().begins_with(prefix):
			return n
	return null


## Walks into a building through its door spot and waits for the fade.
func enter(door_label: String) -> void:
	var d := find_door(door_label)
	print("door '", door_label, "' found: ", d != null)
	d.action.call(p)
	await create_timer(1.6).timeout


func leave() -> void:
	var s := find_spot("[R] Έξοδος")
	s.action.call(p)
	await create_timer(1.2).timeout


func talk_to(npc_id: String) -> void:
	var keeper: Node
	for n in get_nodes_in_group("interactables"):
		if not (n is InteractSpot) and n.get("npc_id") == npc_id:   # untyped: Npc mentions Quests
			keeper = n
	print("keeper ", npc_id, " found: ", keeper != null, ", prompt: ", keeper.interact_prompt() if keeper else "-")
	var dist := p.global_position.distance_to(keeper.global_position)
	print("   distance from the door: ", snappedf(dist, 0.1), " m (interact range ", keeper.interact_range(), ")")
	# walk to a spot 3 m in front of the keeper, facing it
	var stand: Vector3 = keeper.global_position + Vector3(0, 0, 4.0)
	p.teleport(stand, PI)
	await create_timer(0.5).timeout
	await shot("keeper_" + npc_id)
	await press("interact")
	await create_timer(0.4).timeout
	print("   dialogue open: ", hud.is_dialogue_open())
	await shot("keeper_" + npc_id + "_talk")
	# finish the dialogue (typewriter: first press completes the line, second continues)
	for i in 2:
		await press("interact")
		await create_timer(0.35).timeout
		print("   press ", i + 1, ": dialogue open ", hud.is_dialogue_open(), ", shop open ", hud.is_shop_open())
	print("   shop open: ", hud.is_shop_open(), ", busy: ", p.busy)
	await shot("keeper_" + npc_id + "_shop")
	await press("ui_cancel")
	await create_timer(0.6).timeout
	print("   after Esc: shop open ", hud.is_shop_open(), ", busy ", p.busy)


func _run() -> void:
	await process_frame
	root.get_node("/root/Quests").intro_seen = true
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(2.5).timeout
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	p = get_first_node_in_group("player") as Player
	hud = get_first_node_in_group("hud")
	p.gold = 300

	await enter("[R] Είσοδος: Παζάρι")
	await talk_to("elena")
	await leave()

	await enter("[R] Είσοδος: Σιδηρουργείο")
	await talk_to("nikitas_forge")
	await leave()

	# --- respec shrine in the church
	await enter("[R] Είσοδος: Εκκλησία")
	p.gain_xp(100000)
	p.learn_talent("g_hp")
	p.learn_talent("g_hp")
	var spot := find_spot("[R] Αναδιανομή")
	print("respec spot found: ", spot != null, " prompt: ", spot.interact_prompt() if spot else "-")
	p.teleport(spot.global_position + Vector3(0, 0.05, 1.0), PI)
	await create_timer(0.4).timeout
	await shot("church_respec")
	p.gold = 2000
	spot.interact(p)
	print("   after respec: talents ", p.talents, ", gold ", p.gold, " (expect 1000), points ", p.talent_points_free(), " (expect 19)")
	quit()
